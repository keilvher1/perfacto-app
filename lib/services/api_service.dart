import 'dart:convert';
import 'package:http/http.dart' as http;

/// Perfacto 백엔드 API 서비스
class ApiService {
  // EC2 서버 주소 (추후 도메인으로 변경 가능)
  static const String baseUrl = 'http://16.184.51.245';

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
    final body = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body['message'] ?? '알 수 없는 오류가 발생했습니다.';
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

  /// 리뷰 작성
  static Future<Map<String, dynamic>> createReview({
    required int placeId,
    required double rating,
    required String content,
  }) async {
    final response = await postAuth('/perfacto/api/reviews', {
      'placeId': placeId,
      'rating': rating,
      'content': content,
    });
    return response['data'];
  }

  /// 장소의 리뷰 목록 조회
  static Future<List<dynamic>> getReviews(int placeId) async {
    final response = await get('/perfacto/every/reviews/place/$placeId');
    return response['data'] as List<dynamic>;
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
}
