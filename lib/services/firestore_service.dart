import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place_model.dart';
import '../models/review_model.dart';
import '../models/category_model.dart';
import '../models/tag_model.dart';
import '../models/match_score_model.dart';
import '../models/predicted_score_model.dart';
import '../models/leaderboard_model.dart';
import '../models/streak_model.dart';

/// Firebase Firestore 서비스
///
/// 모든 Firestore 데이터 접근을 담당하는 중앙 서비스
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자 ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// 현재 로그인된 사용자
  static User? get currentUser => _auth.currentUser;

  // ==================== Collections ====================

  static CollectionReference get _usersCollection => _db.collection('users');
  static CollectionReference get _placesCollection => _db.collection('places');
  static CollectionReference get _categoriesCollection => _db.collection('categories');
  static CollectionReference get _matchScoresCollection => _db.collection('matchScores');
  static CollectionReference get _streaksCollection => _db.collection('streaks');
  static CollectionReference get _leaderboardsCollection => _db.collection('leaderboards');
  static CollectionReference get _savedPlacesCollection => _db.collection('savedPlaces');
  static CollectionReference get _followsCollection => _db.collection('follows');
  static CollectionReference get _wantToTryCollection => _db.collection('wantToTry');

  // ==================== 카테고리 API ====================

  /// 모든 카테고리 조회
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final snapshot = await _categoriesCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('❌ FirestoreService.getCategories error: $e');
      // 기본 5대 카테고리 반환
      return PlaceCategory.values.map((cat) => {
        'id': cat.toLegacyId().toString(),
        'code': cat.code,
        'name': cat.label,
        'emoji': cat.emoji,
      }).toList();
    }
  }

  // ==================== 장소 API ====================

  /// 카테고리 코드를 ID로 변환 (Firestore 쿼리용)
  static int _categoryCodeToId(String categoryCode) {
    switch (categoryCode) {
      case 'restaurant':
        return 1;
      case 'accommodation':
        return 2;
      case 'cafe':
        return 3;
      case 'attraction':
        return 4;
      default:
        return 4; // 기본값: attraction
    }
  }

  /// 카테고리별 장소 조회
  static Future<List<PlaceModel>> getPlacesByCategory({
    required String categoryCode,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // 1️⃣ 먼저 categoryCode 필드로 쿼리 시도 (새 데이터 구조)
      Query query = _placesCollection
          .where('categoryCode', isEqualTo: categoryCode)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      var snapshot = await query.get();

      // 2️⃣ categoryCode로 결과가 없으면 category (숫자) 필드로 재시도 (레거시 데이터 구조)
      if (snapshot.docs.isEmpty) {
        final categoryId = _categoryCodeToId(categoryCode);
        query = _placesCollection
            .where('category', isEqualTo: categoryId)
            .orderBy('createdAt', descending: true)
            .limit(limit);

        if (startAfter != null) {
          query = query.startAfterDocument(startAfter);
        }

        snapshot = await query.get();
        print('📍 Using legacy category field (ID: $categoryId) for $categoryCode: ${snapshot.docs.length} places found');
      } else {
        print('📍 Using categoryCode field for $categoryCode: ${snapshot.docs.length} places found');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlaceModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('❌ FirestoreService.getPlacesByCategory error: $e');
      return [];
    }
  }

  /// 장소 상세 조회
  static Future<PlaceModel?> getPlace(String placeId) async {
    try {
      final doc = await _placesCollection.doc(placeId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return PlaceModel.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      print('❌ FirestoreService.getPlace error: $e');
      return null;
    }
  }

  /// 장소 검색
  static Future<List<PlaceModel>> searchPlaces(String keyword) async {
    try {
      // Firestore는 full-text search를 지원하지 않으므로
      // name 필드로 prefix 검색
      final snapshot = await _placesCollection
          .where('name', isGreaterThanOrEqualTo: keyword)
          .where('name', isLessThanOrEqualTo: '$keyword\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlaceModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('❌ FirestoreService.searchPlaces error: $e');
      return [];
    }
  }

  /// ELO 랭킹 기반 장소 조회
  static Future<List<PlaceModel>> getRanking({
    String? categoryCode,
    String? district,
    int limit = 50,
  }) async {
    try {
      Query query = _placesCollection
          .orderBy('eloRating', descending: true)
          .limit(limit);

      if (categoryCode != null) {
        query = query.where('categoryCode', isEqualTo: categoryCode);
      }

      if (district != null) {
        query = query.where('district', isEqualTo: district);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlaceModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('❌ FirestoreService.getRanking error: $e');
      return [];
    }
  }

  // ==================== 리뷰 API ====================

  /// 리뷰 작성
  static Future<String> createReview({
    required String placeId,
    required String overallRating,
    required List<String> reasons,
    List<String>? tags,
    String? comparedPlaceId,
    String? comparisonResult,
  }) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      final reviewRef = _placesCollection
          .doc(placeId)
          .collection('reviews')
          .doc();

      final reviewData = {
        'userId': currentUserId,
        'placeId': placeId,
        'overallRating': overallRating,
        'reasons': reasons,
        'tags': tags ?? [],
        'comparedPlaceId': comparedPlaceId,
        'comparisonResult': comparisonResult,
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await reviewRef.set(reviewData);

      // 장소의 리뷰 카운트 증가
      await _placesCollection.doc(placeId).update({
        'reviewCount': FieldValue.increment(1),
      });

      // 사용자의 리뷰 카운트 증가 및 Streak 업데이트
      await _updateUserReviewStats();

      return reviewRef.id;
    } catch (e) {
      print('❌ FirestoreService.createReview error: $e');
      rethrow;
    }
  }

  /// 사용자 리뷰 통계 업데이트 (리뷰 작성 시)
  static Future<void> _updateUserReviewStats() async {
    if (currentUserId == null) return;

    try {
      final userRef = _usersCollection.doc(currentUserId);

      // 리뷰 카운트 증가
      await userRef.update({
        'reviewCount': FieldValue.increment(1),
        'totalPoints': FieldValue.increment(10), // 리뷰 작성 시 10 포인트
        'lastReviewDate': FieldValue.serverTimestamp(),
      });

      // Streak 업데이트
      await _updateStreak();
    } catch (e) {
      print('❌ FirestoreService._updateUserReviewStats error: $e');
    }
  }

  /// Streak 업데이트
  static Future<void> _updateStreak() async {
    if (currentUserId == null) return;

    try {
      final streakRef = _streaksCollection.doc(currentUserId);
      final streakDoc = await streakRef.get();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (!streakDoc.exists) {
        // 첫 Streak 생성
        await streakRef.set({
          'userId': currentUserId,
          'currentStreak': 1,
          'longestStreak': 1,
          'lastReviewDate': Timestamp.fromDate(today),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = streakDoc.data() as Map<String, dynamic>;
        final lastReviewTimestamp = data['lastReviewDate'] as Timestamp?;

        if (lastReviewTimestamp != null) {
          final lastReviewDate = lastReviewTimestamp.toDate();
          final lastDay = DateTime(lastReviewDate.year, lastReviewDate.month, lastReviewDate.day);
          final daysDiff = today.difference(lastDay).inDays;

          if (daysDiff == 0) {
            // 오늘 이미 리뷰 작성함 (Streak 유지)
            return;
          } else if (daysDiff == 1) {
            // 연속 일수 증가
            final currentStreak = (data['currentStreak'] ?? 0) + 1;
            final longestStreak = data['longestStreak'] ?? 0;

            await streakRef.update({
              'currentStreak': currentStreak,
              'longestStreak': currentStreak > longestStreak ? currentStreak : longestStreak,
              'lastReviewDate': Timestamp.fromDate(today),
            });
          } else {
            // Streak 끊김 - 1로 리셋
            await streakRef.update({
              'currentStreak': 1,
              'lastReviewDate': Timestamp.fromDate(today),
            });
          }
        }
      }
    } catch (e) {
      print('❌ FirestoreService._updateStreak error: $e');
    }
  }

  /// 장소의 리뷰 목록 조회
  static Future<List<ReviewModel>> getReviews(
    String placeId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _placesCollection
          .doc(placeId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      // 1. 모든 고유한 userId 수집
      final userIds = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['userId'] as String?)
          .where((id) => id != null)
          .toSet()
          .cast<String>()
          .toList();

      // 2. 사용자 정보를 배치로 한 번에 조회 (N+1 문제 해결)
      final Map<String, Map<String, dynamic>> userMap = {};

      if (userIds.isNotEmpty) {
        final userDocs = await Future.wait(
          userIds.map((id) => _usersCollection.doc(id).get())
        );

        for (var userDoc in userDocs) {
          if (userDoc.exists) {
            userMap[userDoc.id] = userDoc.data() as Map<String, dynamic>;
          }
        }
      }

      // 3. 리뷰 목록 생성 (사용자 정보는 메모리에서 조회)
      final reviews = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String?;

        // 사용자 정보를 userMap에서 조회
        String userName = 'Unknown';
        String? userProfileImage;

        if (userId != null && userMap.containsKey(userId)) {
          final userData = userMap[userId]!;
          userName = userData['nickname'] ?? userData['displayName'] ?? 'Unknown';
          userProfileImage = userData['photoURL'];
        }

        return ReviewModel.fromJson({
          'id': doc.id,
          'userName': userName,
          'userProfileImage': userProfileImage,
          'placeName': '', // 필요 시 조회
          ...data,
        });
      }).toList();

      return reviews;
    } catch (e) {
      print('❌ FirestoreService.getReviews error: $e');
      return [];
    }
  }

  /// 사용자의 리뷰 목록 조회
  static Future<List<ReviewModel>> getUserReviews(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Firestore collection group query
      final snapshot = await _db
          .collectionGroup('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      // 1. 사용자 정보 한 번만 조회
      String userName = 'Unknown';
      String? userProfileImage;

      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userName = userData['nickname'] ?? userData['displayName'] ?? 'Unknown';
        userProfileImage = userData['photoURL'];
      }

      // 2. 모든 고유한 placeId 수집
      final placeIds = snapshot.docs
          .map((doc) => doc.data()['placeId'] as String?)
          .where((id) => id != null)
          .toSet()
          .cast<String>()
          .toList();

      // 3. 장소 정보를 배치로 한 번에 조회 (N+1 문제 해결)
      final Map<String, String> placeNameMap = {};

      if (placeIds.isNotEmpty) {
        final placeDocs = await Future.wait(
          placeIds.map((id) => _placesCollection.doc(id).get())
        );

        for (var placeDoc in placeDocs) {
          if (placeDoc.exists) {
            final placeData = placeDoc.data() as Map<String, dynamic>;
            placeNameMap[placeDoc.id] = placeData['name'] ?? '';
          }
        }
      }

      // 4. 리뷰 목록 생성 (장소 정보는 메모리에서 조회)
      final reviews = snapshot.docs.map((doc) {
        final data = doc.data();
        final placeId = data['placeId'] as String?;
        final placeName = placeId != null && placeNameMap.containsKey(placeId)
            ? placeNameMap[placeId]!
            : '';

        return ReviewModel.fromJson({
          'id': doc.id,
          'userName': userName,
          'userProfileImage': userProfileImage,
          'placeName': placeName,
          ...data,
        });
      }).toList();

      return reviews;
    } catch (e) {
      print('❌ FirestoreService.getUserReviews error: $e');
      return [];
    }
  }

  /// 리뷰 삭제
  static Future<void> deleteReview(String placeId, String reviewId) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _placesCollection
          .doc(placeId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // 장소의 리뷰 카운트 감소
      await _placesCollection.doc(placeId).update({
        'reviewCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('❌ FirestoreService.deleteReview error: $e');
      rethrow;
    }
  }

  // ==================== 저장된 장소 API ====================

  /// 장소 저장
  static Future<void> savePlace(String placeId, {String? memo}) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      final savedPlaceRef = _savedPlacesCollection
          .doc('${currentUserId}_$placeId');

      await savedPlaceRef.set({
        'userId': currentUserId,
        'placeId': placeId,
        'memo': memo,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FirestoreService.savePlace error: $e');
      rethrow;
    }
  }

  /// 장소 저장 취소
  static Future<void> unsavePlace(String placeId) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _savedPlacesCollection
          .doc('${currentUserId}_$placeId')
          .delete();
    } catch (e) {
      print('❌ FirestoreService.unsavePlace error: $e');
      rethrow;
    }
  }

  /// 저장된 장소 목록 조회
  static Future<List<PlaceModel>> getSavedPlaces() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _savedPlacesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      // 1. placeId 목록 수집
      final placeIds = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['placeId'] as String)
          .toList();

      if (placeIds.isEmpty) return [];

      // 2. whereIn으로 배치 조회 (최대 10개씩, N+1 문제 해결)
      final List<PlaceModel> places = [];

      for (var i = 0; i < placeIds.length; i += 10) {
        final batch = placeIds.skip(i).take(10).toList();

        final placeDocs = await _placesCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var placeDoc in placeDocs.docs) {
          if (placeDoc.exists) {
            final placeData = placeDoc.data() as Map<String, dynamic>;
            places.add(PlaceModel.fromJson({
              'id': placeDoc.id,
              'isSaved': true,
              ...placeData,
            }));
          }
        }
      }

      // 3. 저장된 순서대로 정렬
      final placeMap = {for (var place in places) place.id: place};
      final sortedPlaces = placeIds
          .map((id) => placeMap[id])
          .whereType<PlaceModel>()
          .toList();

      return sortedPlaces;
    } catch (e) {
      print('❌ FirestoreService.getSavedPlaces error: $e');
      return [];
    }
  }

  /// 장소 저장 여부 확인
  static Future<bool> isSaved(String placeId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _savedPlacesCollection
          .doc('${currentUserId}_$placeId')
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ FirestoreService.isSaved error: $e');
      return false;
    }
  }

  // ==================== 팔로우 API ====================

  /// 팔로우
  static Future<void> follow(String targetUserId) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      final followRef = _followsCollection.doc('${currentUserId}_$targetUserId');

      await followRef.set({
        'followerId': currentUserId,
        'followingId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FirestoreService.follow error: $e');
      rethrow;
    }
  }

  /// 언팔로우
  static Future<void> unfollow(String targetUserId) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _followsCollection
          .doc('${currentUserId}_$targetUserId')
          .delete();
    } catch (e) {
      print('❌ FirestoreService.unfollow error: $e');
      rethrow;
    }
  }

  /// 팔로잉 목록 조회
  static Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final snapshot = await _followsCollection
          .where('followerId', isEqualTo: userId)
          .get();

      // 사용자 정보 병렬 조회
      final following = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final followingId = data['followingId'] as String;

          final userDoc = await _usersCollection.doc(followingId).get();
          if (!userDoc.exists) return null;

          final userData = userDoc.data() as Map<String, dynamic>;
          return {
            'userId': followingId,
            'nickname': userData['nickname'] ?? userData['displayName'],
            'photoURL': userData['photoURL'],
          };
        }),
      );

      return following.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('❌ FirestoreService.getFollowing error: $e');
      return [];
    }
  }

  /// 팔로워 목록 조회
  static Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final snapshot = await _followsCollection
          .where('followingId', isEqualTo: userId)
          .get();

      // 사용자 정보 병렬 조회
      final followers = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>;
          final followerId = data['followerId'] as String;

          final userDoc = await _usersCollection.doc(followerId).get();
          if (!userDoc.exists) return null;

          final userData = userDoc.data() as Map<String, dynamic>;
          return {
            'userId': followerId,
            'nickname': userData['nickname'] ?? userData['displayName'],
            'photoURL': userData['photoURL'],
          };
        }),
      );

      return followers.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print('❌ FirestoreService.getFollowers error: $e');
      return [];
    }
  }

  /// 팔로우 여부 확인
  static Future<bool> isFollowing(String targetUserId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _followsCollection
          .doc('${currentUserId}_$targetUserId')
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ FirestoreService.isFollowing error: $e');
      return false;
    }
  }

  // ==================== Match Score API (간단 구현) ====================

  /// Match Score 조회 (캐시에서)
  static Future<MatchScore?> getMatchScore(String targetUserId) async {
    if (currentUserId == null) return null;

    try {
      final doc = await _matchScoresCollection
          .doc('${currentUserId}_$targetUserId')
          .get();

      if (!doc.exists) {
        // 캐시에 없으면 계산 (TODO: Cloud Function으로 이동)
        return await _calculateAndCacheMatchScore(targetUserId);
      }

      final data = doc.data() as Map<String, dynamic>;
      return MatchScore.fromJson(data);
    } catch (e) {
      print('❌ FirestoreService.getMatchScore error: $e');
      return null;
    }
  }

  /// Match Score 계산 및 캐싱 (간단 구현)
  static Future<MatchScore> _calculateAndCacheMatchScore(String targetUserId) async {
    // TODO: 실제 구현은 Cloud Functions에서 수행
    // 여기서는 더미 데이터 반환
    final matchScore = MatchScore(
      userId: int.tryParse(currentUserId!) ?? 0,
      targetUserId: int.tryParse(targetUserId) ?? 0,
      score: 0.0,
      commonPlacesCount: 0,
      compatibility: 'NEUTRAL',
      calculatedAt: DateTime.now(),
    );

    return matchScore;
  }

  // ==================== Streak API ====================

  /// 내 Streak 정보 조회
  static Future<UserStreak> getMyStreak() async {
    if (currentUserId == null) {
      return UserStreak(
        currentStreak: 0,
        longestStreak: 0,
        reviewedToday: false,
        hoursUntilStreakBreak: 24,
      );
    }

    try {
      final doc = await _streaksCollection.doc(currentUserId).get();

      if (!doc.exists) {
        return UserStreak(
          currentStreak: 0,
          longestStreak: 0,
          reviewedToday: false,
          hoursUntilStreakBreak: 24,
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final lastReviewTimestamp = data['lastReviewDate'] as Timestamp?;

      bool reviewedToday = false;
      int hoursUntilStreakBreak = 24;

      if (lastReviewTimestamp != null) {
        final lastReviewDate = lastReviewTimestamp.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastDay = DateTime(
          lastReviewDate.year,
          lastReviewDate.month,
          lastReviewDate.day,
        );

        reviewedToday = today == lastDay;

        if (reviewedToday) {
          hoursUntilStreakBreak = 24;
        } else {
          final nextDay = lastDay.add(const Duration(days: 1));
          final deadline = DateTime(nextDay.year, nextDay.month, nextDay.day, 23, 59, 59);
          final remaining = deadline.difference(now);
          hoursUntilStreakBreak = remaining.inHours.clamp(0, 24);
        }
      }

      return UserStreak(
        currentStreak: data['currentStreak'] ?? 0,
        longestStreak: data['longestStreak'] ?? 0,
        lastReviewDate: lastReviewTimestamp?.toDate(),
        reviewedToday: reviewedToday,
        hoursUntilStreakBreak: hoursUntilStreakBreak,
      );
    } catch (e) {
      print('❌ FirestoreService.getMyStreak error: $e');
      return UserStreak(
        currentStreak: 0,
        longestStreak: 0,
        reviewedToday: false,
        hoursUntilStreakBreak: 24,
      );
    }
  }

  // ==================== 리더보드 API ====================

  /// 글로벌 리더보드 조회
  static Future<List<LeaderboardEntry>> getGlobalLeaderboard({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _usersCollection
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      final entries = snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final data = doc.data() as Map<String, dynamic>;

        return LeaderboardEntry(
          rank: index + 1,
          userId: int.tryParse(doc.id) ?? 0,
          nickname: data['nickname'] ?? data['displayName'] ?? 'Unknown',
          profileImageUrl: data['photoURL'],
          reviewCount: data['reviewCount'] ?? 0,
          totalPoints: data['totalPoints'] ?? 0,
          currentStreak: 0, // Streak은 별도 조회 필요
        );
      }).toList();

      return entries;
    } catch (e) {
      print('❌ FirestoreService.getGlobalLeaderboard error: $e');
      return [];
    }
  }

  /// 도시별 리더보드 조회
  static Future<List<LeaderboardEntry>> getCityLeaderboard(
    String city, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _usersCollection
          .where('city', isEqualTo: city)
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      final entries = snapshot.docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final data = doc.data() as Map<String, dynamic>;

        return LeaderboardEntry(
          rank: index + 1,
          userId: int.tryParse(doc.id) ?? 0,
          nickname: data['nickname'] ?? data['displayName'] ?? 'Unknown',
          profileImageUrl: data['photoURL'],
          reviewCount: data['reviewCount'] ?? 0,
          totalPoints: data['totalPoints'] ?? 0,
          currentStreak: 0,
        );
      }).toList();

      return entries;
    } catch (e) {
      print('❌ FirestoreService.getCityLeaderboard error: $e');
      return [];
    }
  }

  // ==================== Want to Try (SNS 통합) API ====================

  /// SNS에서 발견한 장소를 Want to Try 리스트에 추가
  static Future<void> addToWantToTry({
    required String placeName,
    String? address,
    required String sourceUrl,
    required String sourcePlatform, // 'instagram', 'tiktok'
    String? notes,
  }) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _wantToTryCollection.add({
        'userId': currentUserId,
        'placeName': placeName,
        'address': address,
        'sourceUrl': sourceUrl,
        'sourcePlatform': sourcePlatform,
        'notes': notes,
        'isVisited': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FirestoreService.addToWantToTry error: $e');
      rethrow;
    }
  }

  /// Want to Try 리스트 조회
  static Future<List<Map<String, dynamic>>> getWantToTryList() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _wantToTryCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('❌ FirestoreService.getWantToTryList error: $e');
      return [];
    }
  }

  /// Want to Try 항목 삭제
  static Future<void> removeFromWantToTry(String itemId) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _wantToTryCollection.doc(itemId).delete();
    } catch (e) {
      print('❌ FirestoreService.removeFromWantToTry error: $e');
      rethrow;
    }
  }

  /// Want to Try 항목 방문 완료 처리
  static Future<void> markAsVisited(String itemId) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _wantToTryCollection.doc(itemId).update({
        'isVisited': true,
        'visitedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FirestoreService.markAsVisited error: $e');
      rethrow;
    }
  }

  /// Want to Try 항목 메모 업데이트
  static Future<void> updateWantToTryNotes(String itemId, String notes) async {
    if (currentUserId == null) throw Exception('로그인이 필요합니다');

    try {
      await _wantToTryCollection.doc(itemId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ FirestoreService.updateWantToTryNotes error: $e');
      rethrow;
    }
  }
}
