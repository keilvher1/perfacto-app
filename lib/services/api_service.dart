import 'dart:convert';
import 'package:http/http.dart' as http;

/// Perfacto 백엔드 API 서비스
class ApiService {
  // 배포된 EC2 서버 주소
  static const String baseUrl = 'http://16.184.51.245:8080';

  // 인증 토큰 저장 (로그인 후 설정)
  static String? _accessToken;
  static String? _refreshToken;

  /// 토큰 설정
  static void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// 토큰 초기화 (로그아웃 시)
  static void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// 공통 헤더 생성
  static Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// GET 요청 (인증 불필요)
  static Future<Map<String, dynamic>> get(String path) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// GET 요청 (인증 필요)
  static Future<Map<String, dynamic>> getAuth(String path) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.get(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// POST 요청 (인증 불필요)
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// POST 요청 (인증 필요)
  static Future<Map<String, dynamic>> postAuth(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.post(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// PUT 요청 (인증 필요)
  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.put(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// PATCH 요청 (인증 필요)
  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.patch(
        url,
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// DELETE 요청 (인증 필요)
  static Future<Map<String, dynamic>> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');

    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(includeAuth: true),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 응답 처리
  static Map<String, dynamic> _handleResponse(http.Response response) {
    print('🔍 DEBUG - Response Status Code: ${response.statusCode}');
    print('🔍 DEBUG - Response Body: ${response.body}');

    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body['message'] ?? '알 수 없는 오류가 발생했습니다.';
      print('❌ DEBUG - Error Message: $message');
      throw Exception(message);
    }
  }

  // ============ API 엔드포인트 메서드 ============

  /// 카테고리 목록 조회
  static Future<List<dynamic>> getCategories() async {
    final response = await get('/perfacto/every/categories');
    return response['data'] as List<dynamic>;
  }

  /// 장소 목록 조회 (카테고리별)
  static Future<List<dynamic>> getPlaces({
    required int categoryId,
    int page = 0,
    int size = 20,
  }) async {
    final response = await get(
      '/perfacto/every/places/category/$categoryId?page=$page&size=$size',
    );
    return response['data']['content'] as List<dynamic>;
  }

  /// 장소 상세 조회
  static Future<Map<String, dynamic>> getPlace(int placeId) async {
    final response = await get('/perfacto/every/places/$placeId');
    return response['data'];
  }

  /// 장소 검색
  static Future<List<dynamic>> searchPlaces(String keyword) async {
    final response = await get('/perfacto/every/places/search?keyword=$keyword');
    return response['data'] as List<dynamic>;
  }

  /// ELO 랭킹 기반 장소 조회
  static Future<List<dynamic>> getRanking({
    int? categoryId,
    String? district,
    int limit = 50,
  }) async {
    String path = '/perfacto/every/places/ranking?limit=$limit';

    if (categoryId != null) {
      path += '&categoryId=$categoryId';
    }
    if (district != null) {
      path += '&district=$district';
    }

    final response = await get(path);
    return response['data'] as List<dynamic>;
  }

  /// 카카오 로그인 (code → 토큰)
  static Future<Map<String, dynamic>> kakaoLogin(String code) async {
    final response = await get('/perfacto/auth/kakao-login?code=$code');

    // 토큰 저장
    if (response['data'] != null) {
      final data = response['data'];
      setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
    }

    return response['data'];
  }

  /// 네이버 로그인
  static Future<Map<String, dynamic>> naverLogin(String code, String state) async {
    final response = await get('/perfacto/auth/naver-login?code=$code&state=$state');

    // 토큰 저장
    if (response['data'] != null) {
      final data = response['data'];
      setTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
    }

    return response['data'];
  }

  /// 좋아요 추가
  static Future<void> addLike(int placeId) async {
    await postAuth('/perfacto/api/likes/$placeId', {});
  }

  /// 좋아요 취소
  static Future<void> removeLike(int placeId) async {
    await delete('/perfacto/api/likes/$placeId');
  }

  /// 북마크 추가
  static Future<void> addBookmark(int placeId) async {
    await postAuth('/perfacto/api/bookmarks/$placeId', {});
  }

  /// 북마크 취소
  static Future<void> removeBookmark(int placeId) async {
    await delete('/perfacto/api/bookmarks/$placeId');
  }

  /// 리뷰 작성 (3단계 리뷰 시스템)
  static Future<Map<String, dynamic>> createReview({
    required int placeId,
    required String overallRating, // 'GOOD', 'NEUTRAL', 'BAD'
    required List<String> reasons, // ReviewReason enum values
    int? comparedPlaceId,
    String? comparisonResult, // 'BETTER', 'SIMILAR', 'WORSE'
  }) async {
    final Map<String, dynamic> body = {
      'placeId': placeId,
      'overallRating': overallRating,
      'reasons': reasons,
    };

    if (comparedPlaceId != null) body['comparedPlaceId'] = comparedPlaceId;
    if (comparisonResult != null) body['comparisonResult'] = comparisonResult;

    final response = await postAuth('/perfacto/api/reviews', body);
    return response['data'];
  }

  /// 리뷰 삭제
  static Future<void> deleteReview(int reviewId) async {
    await delete('/perfacto/api/reviews/$reviewId');
  }

  /// 장소의 전체 리뷰 목록 조회
  static Future<List<dynamic>> getReviews(int placeId, {int page = 0, int size = 20}) async {
    final response = await get('/perfacto/every/reviews/place/$placeId?page=$page&size=$size');
    return response['data']['content'] as List<dynamic>;
  }

  /// 팔로잉 사용자의 리뷰 목록 조회
  static Future<List<dynamic>> getFollowingReviews(int placeId) async {
    final response = await getAuth('/perfacto/api/reviews/place/$placeId/following');
    return response['data'] as List<dynamic>;
  }

  /// 사용자의 리뷰 목록 조회
  static Future<List<dynamic>> getUserReviews(int userId, {int page = 0, int size = 20}) async {
    final response = await get('/perfacto/every/reviews/user/$userId?page=$page&size=$size');
    return response['data']['content'] as List<dynamic>;
  }

  /// 리뷰에 도움이 됨 추가
  static Future<void> addReviewHelpful(int reviewId) async {
    await postAuth('/perfacto/api/reviews/$reviewId/helpful', {});
  }

  // ============ 팔로우 관련 API ============

  /// 팔로우 추가
  static Future<void> follow(int userId) async {
    await postAuth('/perfacto/api/follows/$userId', {});
  }

  /// 언팔로우
  static Future<void> unfollow(int userId) async {
    await delete('/perfacto/api/follows/$userId');
  }

  /// 팔로잉 목록 조회
  static Future<List<dynamic>> getFollowing(int userId) async {
    final response = await get('/perfacto/every/follows/$userId/following');
    return response['data'] as List<dynamic>;
  }

  /// 팔로워 목록 조회
  static Future<List<dynamic>> getFollowers(int userId) async {
    final response = await get('/perfacto/every/follows/$userId/followers');
    return response['data'] as List<dynamic>;
  }

  /// 팔로우 여부 확인
  static Future<bool> isFollowing(int userId) async {
    final response = await getAuth('/perfacto/api/follows/$userId/status');
    return response['data']['isFollowing'] as bool;
  }

  // ============ 저장된 장소 관련 API ============

  /// 장소 저장
  static Future<void> savePlace(int placeId, {String? memo}) async {
    await postAuth('/perfacto/api/saved-places', {
      'placeId': placeId,
      if (memo != null) 'memo': memo,
    });
  }

  /// 장소 저장 취소
  static Future<void> unsavePlace(int placeId) async {
    await delete('/perfacto/api/saved-places/$placeId');
  }

  /// 저장된 장소 목록 조회
  static Future<List<dynamic>> getSavedPlaces() async {
    print('🔍 DEBUG - getSavedPlaces called');
    print('🔍 DEBUG - Access Token: ${_accessToken != null ? "EXISTS" : "NULL"}');

    try {
      final response = await getAuth('/perfacto/api/saved-places');
      print('🔍 DEBUG - getSavedPlaces response: $response');
      return response['data'] as List<dynamic>;
    } catch (e) {
      print('❌ DEBUG - getSavedPlaces error: $e');
      rethrow;
    }
  }

  /// 장소 저장 여부 확인
  static Future<bool> isSaved(int placeId) async {
    final response = await getAuth('/perfacto/api/saved-places/check/$placeId');
    return response['data'] as bool;
  }

  /// 회원가입
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final response = await post('/perfacto/auth/signup', {
      'email': email,
      'password': password,
      'nickname': nickname,
    });

    // 토큰 저장
    if (response['accessToken'] != null) {
      setTokens(
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'],
      );
    }

    return response;
  }

  /// 이메일 로그인
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post('/perfacto/auth/login', {
      'email': email,
      'password': password,
    });

    // 토큰 저장
    if (response['accessToken'] != null) {
      setTokens(
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'],
      );
    }

    return response;
  }

  // ==================== 사용자 검색 API ====================

  /// 사용자 검색 (닉네임 또는 이름으로 검색)
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await getAuth('/perfacto/api/user/search?query=$query');

    if (response['data'] != null) {
      return List<Map<String, dynamic>>.from(response['data']);
    }

    return [];
  }

  /// 특정 사용자 정보 조회
  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final response = await getAuth('/perfacto/api/user/$userId');
    return response['data'];
  }

  /// 특정 사용자의 저장한 장소 + 리뷰 남긴 장소 조회
  static Future<List<Map<String, dynamic>>> getUserPlaces(int userId) async {
    final response = await get('/perfacto/api/saved-places/user/$userId');

    if (response['data'] != null && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    }

    return [];
  }

  // ==================== 프로필 업데이트 API ====================

  /// 사용자 프로필 업데이트 (닉네임)
  static Future<void> updateUserProfile({required String nickname}) async {
    await patch('/perfacto/api/user/profile', {
      'nickName': nickname,
    });
  }
}
