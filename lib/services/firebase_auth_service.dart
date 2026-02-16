import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

/// Firebase Authentication 서비스
class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';

  /// 현재 로그인된 사용자
  static User? get currentUser => _auth.currentUser;

  /// 현재 사용자 ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// 현재 사용자 이메일
  static String? get currentUserEmail => _auth.currentUser?.email;

  /// 로그인 여부 확인
  static bool get isLoggedIn => _auth.currentUser != null;

  /// 로그인 상태 변경 스트림
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ==================== 이메일/비밀번호 인증 ====================

  /// 회원가입 (이메일/비밀번호)
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      // Firebase Auth 회원가입
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 사용자 프로필 생성
      if (credential.user != null) {
        await _createUserProfile(
          userId: credential.user!.uid,
          email: email,
          nickname: nickname,
        );

        // 사용자 정보 저장
        await _saveUserInfo(credential.user!.uid, email);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthService.signUp error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ FirebaseAuthService.signUp error: $e');
      throw Exception('회원가입 실패: $e');
    }
  }

  /// 로그인 (이메일/비밀번호)
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 정보 저장
      if (credential.user != null) {
        await _saveUserInfo(credential.user!.uid, email);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthService.signIn error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ FirebaseAuthService.signIn error: $e');
      throw Exception('로그인 실패: $e');
    }
  }

  /// 로그아웃
  static Future<void> signOut() async {
    try {
      await _auth.signOut();

      // 로컬 저장소 초기화
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
    } catch (e) {
      print('❌ FirebaseAuthService.signOut error: $e');
      throw Exception('로그아웃 실패: $e');
    }
  }

  /// 비밀번호 재설정 이메일 전송
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthService.sendPasswordResetEmail error: ${e.code}');
      throw _handleAuthException(e);
    }
  }

  /// 이메일 인증 전송
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      print('❌ FirebaseAuthService.sendEmailVerification error: $e');
      throw Exception('이메일 인증 전송 실패: $e');
    }
  }

  // ==================== 소셜 로그인 ====================

  /// Google 로그인
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Firebase signInWithPopup 사용
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final credential = await _auth.signInWithPopup(googleProvider);

        if (credential.user != null) {
          await _handleSocialLoginUser(
            user: credential.user!,
            provider: 'google',
          );
        }

        return credential;
      } else {
        // iOS/Android: google_sign_in 패키지 사용
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // 사용자가 로그인 취소
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await _handleSocialLoginUser(
            user: userCredential.user!,
            provider: 'google',
          );
        }

        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthService.signInWithGoogle error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ FirebaseAuthService.signInWithGoogle error: $e');
      throw Exception('Google 로그인 실패: $e');
    }
  }

  /// Apple 로그인
  static Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Web: Firebase signInWithPopup 사용
        final AppleAuthProvider appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');

        final credential = await _auth.signInWithPopup(appleProvider);

        if (credential.user != null) {
          await _handleSocialLoginUser(
            user: credential.user!,
            provider: 'apple',
          );
        }

        return credential;
      } else {
        // iOS: sign_in_with_apple 패키지 사용
        // nonce 생성 (보안을 위해)
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        // Apple에서 받은 정보로 OAuthCredential 생성
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        final userCredential = await _auth.signInWithCredential(oauthCredential);

        if (userCredential.user != null) {
          // Apple은 최초 로그인 시에만 이름 정보를 제공
          String? displayName;
          if (appleCredential.givenName != null || appleCredential.familyName != null) {
            displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          }

          await _handleSocialLoginUser(
            user: userCredential.user!,
            provider: 'apple',
            displayName: displayName,
          );
        }

        return userCredential;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      print('❌ FirebaseAuthService.signInWithApple error: ${e.code} - ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        return null; // 사용자 취소
      }
      throw Exception('Apple 로그인 실패: ${e.message}');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthService.signInWithApple error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ FirebaseAuthService.signInWithApple error: $e');
      throw Exception('Apple 로그인 실패: $e');
    }
  }

  /// 소셜 로그인 사용자 처리 (프로필 생성/업데이트)
  static Future<void> _handleSocialLoginUser({
    required User user,
    required String provider,
    String? displayName,
  }) async {
    try {
      // 사용자 프로필 존재 여부 확인
      final doc = await _db.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // 신규 사용자: 프로필 생성
        final nickname = displayName ?? user.displayName ?? user.email?.split('@').first ?? 'User';

        await _db.collection('users').doc(user.uid).set({
          'email': user.email,
          'nickname': nickname,
          'displayName': nickname,
          'photoURL': user.photoURL,
          'provider': provider,
          'reviewCount': 0,
          'totalPoints': 0,
          'city': '포항',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ New social user profile created: ${user.uid}');
      } else {
        // 기존 사용자: 로그인 시간만 업데이트
        await _db.collection('users').doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Existing social user logged in: ${user.uid}');
      }

      // 로컬 저장
      await _saveUserInfo(user.uid, user.email ?? '');
    } catch (e) {
      print('❌ FirebaseAuthService._handleSocialLoginUser error: $e');
      // 에러가 발생해도 로그인은 성공한 것으로 처리
    }
  }

  /// nonce 생성 (Apple 로그인용)
  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA256 해시 (Apple 로그인용)
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ==================== 사용자 프로필 관리 ====================

  /// Firestore에 사용자 프로필 생성
  static Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String nickname,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'email': email,
        'nickname': nickname,
        'displayName': nickname,
        'photoURL': null,
        'reviewCount': 0,
        'totalPoints': 0,
        'city': '포항', // 기본값
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ User profile created: $userId');
    } catch (e) {
      print('❌ FirebaseAuthService._createUserProfile error: $e');
      rethrow;
    }
  }

  /// 사용자 프로필 업데이트
  static Future<void> updateUserProfile({
    String? nickname,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (nickname != null) {
        updates['nickname'] = nickname;
        updates['displayName'] = nickname;
      }

      if (photoURL != null) {
        updates['photoURL'] = photoURL;
      }

      await _db.collection('users').doc(user.uid).update(updates);

      // Firebase Auth 프로필도 업데이트
      if (nickname != null || photoURL != null) {
        await user.updateDisplayName(nickname);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      }
    } catch (e) {
      print('❌ FirebaseAuthService.updateUserProfile error: $e');
      throw Exception('프로필 업데이트 실패: $e');
    }
  }

  /// 사용자 프로필 조회
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      return {
        'userId': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    } catch (e) {
      print('❌ FirebaseAuthService.getUserProfile error: $e');
      return null;
    }
  }

  /// 내 프로필 조회
  static Future<Map<String, dynamic>?> getMyProfile() async {
    if (currentUserId == null) return null;
    return await getUserProfile(currentUserId!);
  }

  // ==================== 헬퍼 메서드 ====================

  /// 사용자 정보 로컬 저장
  static Future<void> _saveUserInfo(String userId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, email);
    } catch (e) {
      print('❌ FirebaseAuthService._saveUserInfo error: $e');
    }
  }

  /// Firebase Auth 예외 처리
  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('비밀번호가 너무 약합니다');
      case 'email-already-in-use':
        return Exception('이미 사용 중인 이메일입니다');
      case 'user-not-found':
        return Exception('사용자를 찾을 수 없습니다');
      case 'wrong-password':
        return Exception('비밀번호가 올바르지 않습니다');
      case 'invalid-email':
        return Exception('유효하지 않은 이메일 형식입니다');
      case 'user-disabled':
        return Exception('비활성화된 계정입니다');
      case 'too-many-requests':
        return Exception('너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요');
      case 'operation-not-allowed':
        return Exception('이 로그인 방법은 현재 사용할 수 없습니다');
      default:
        return Exception('인증 오류: ${e.message}');
    }
  }

  /// 사용자 검색
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: query)
          .where('nickname', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'userId': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print('❌ FirebaseAuthService.searchUsers error: $e');
      return [];
    }
  }

  /// 회원 탈퇴
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    try {
      // Firestore 사용자 데이터 삭제
      await _db.collection('users').doc(user.uid).delete();

      // Firebase Auth 계정 삭제
      await user.delete();

      // 로컬 저장소 초기화
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('❌ FirebaseAuthService.deleteAccount error: $e');
      throw Exception('회원 탈퇴 실패: $e');
    }
  }
}
