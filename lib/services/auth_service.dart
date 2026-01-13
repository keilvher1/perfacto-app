import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// 인증 서비스 (백엔드 API 사용)
class AuthService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';

  /// 현재 로그인된 사용자 정보
  static String? _currentUserId;
  static String? _currentUserEmail;

  /// 로그인 (이메일/비밀번호)
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔍 DEBUG - signIn called with email: $email');

      final response = await ApiService.login(
        email: email,
        password: password,
      );

      print('🔍 DEBUG - login response: $response');

      // 토큰 저장
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userId = response['userId'].toString();
      final userEmail = response['email'] as String?;

      print('🔍 DEBUG - Saving tokens - accessToken: ${accessToken.substring(0, 20)}..., userId: $userId');

      await _saveTokens(accessToken, refreshToken, userId, userEmail ?? '');

      _currentUserId = userId;
      _currentUserEmail = userEmail;

      print('🔍 DEBUG - Login successful');

      return response;
    } catch (e) {
      print('❌ DEBUG - signIn error: $e');
      throw Exception('로그인 실패: $e');
    }
  }

  /// 회원가입 (이메일/비밀번호)
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final response = await ApiService.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );

      // 회원가입 후 자동 로그인 (토큰 저장)
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userId = response['userId'].toString();
      final userEmail = response['email'] as String?;

      await _saveTokens(accessToken, refreshToken, userId, userEmail ?? '');

      _currentUserId = userId;
      _currentUserEmail = userEmail;

      return response;
    } catch (e) {
      throw Exception('회원가입 실패: $e');
    }
  }

  /// 카카오 로그인
  static Future<Map<String, dynamic>> kakaoLogin(String code) async {
    try {
      final response = await ApiService.kakaoLogin(code);

      // 토큰 저장
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userId = response['userId'].toString();
      final userEmail = response['email'] as String?;

      await _saveTokens(accessToken, refreshToken, userId, userEmail ?? '');

      _currentUserId = userId;
      _currentUserEmail = userEmail;

      return response;
    } catch (e) {
      throw Exception('카카오 로그인 실패: $e');
    }
  }

  /// 로그아웃
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);

    _currentUserId = null;
    _currentUserEmail = null;

    // API 서비스의 토큰도 초기화
    ApiService.clearTokens();
  }

  /// 토큰 저장
  static Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    String userId,
    String userEmail,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserEmail, userEmail);

    // API 서비스에도 토큰 설정
    ApiService.setTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  /// 저장된 토큰 불러오기
  static Future<bool> loadSavedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    final userId = prefs.getString(_keyUserId);
    final userEmail = prefs.getString(_keyUserEmail);

    if (accessToken != null && refreshToken != null && userId != null) {
      _currentUserId = userId;
      _currentUserEmail = userEmail;

      // API 서비스에 토큰 설정
      ApiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return true;
    }

    return false;
  }

  /// 현재 사용자 ID
  static String? get currentUserId => _currentUserId;

  /// 현재 사용자 이메일
  static String? get currentUserEmail => _currentUserEmail;

  /// 로그인 여부 확인
  static Future<bool> isLoggedIn() async {
    if (_currentUserId != null) {
      return true;
    }

    return await loadSavedTokens();
  }
}
