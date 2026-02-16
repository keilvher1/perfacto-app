import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

/// FirebaseAuthService 인스턴스를 제공하는 Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// 현재 로그인된 사용자를 제공하는 Provider
///
/// Firebase Auth의 authStateChanges를 감지하여 자동으로 업데이트됩니다.
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 사용자 로그인 상태를 제공하는 Provider
///
/// Example: ref.watch(isLoggedInProvider)
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// 사용자 ID를 제공하는 Provider
///
/// Example: ref.watch(userIdProvider)
final userIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 인증 상태 관리를 위한 StateNotifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  /// 이메일/비밀번호 로그인
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await FirebaseAuthService.signIn(
        email: email,
        password: password,
      );
      final user = credential.user;
      state = AsyncValue.data(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Google 로그인
  Future<User?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final credential = await FirebaseAuthService.signInWithGoogle();
      final user = credential?.user;
      state = AsyncValue.data(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Apple 로그인
  Future<User?> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final credential = await FirebaseAuthService.signInWithApple();
      final user = credential?.user;
      state = AsyncValue.data(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await FirebaseAuthService.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// 인증 상태 Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(),
);
