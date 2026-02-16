import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:perfacto/config/api_config.dart';

/// Perfacto 백엔드 API 서비스
/// ⚠️ 주의: Firebase로 마이그레이션 완료. 레거시 코드
class ApiService {
  // API Base URL (환경 변수에서 로드)
  static String get baseUrl => ApiConfig.baseUrl;

  // 타임아웃 설정
  static Duration get requestTimeout => Duration(milliseconds: ApiConfig.timeoutMs);

  // 재시도 설정
  static int get maxRetries => ApiConfig.maxRetries;
  static const Duration retryDelay = Duration(seconds: 1);

  // 인증 토큰 저장 (로그인 후 설정)
  static String? _accessToken;
  static String? _refreshToken;

  // 서버 상태
  static bool _isServerDown = false;

  /// 서버 다운 상태 확인
  static bool get isServerDown => _isServerDown;

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

  /// 서버 상태 확인
  static Future<bool> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/perfacto/every/categories'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));

      _isServerDown = response.statusCode != 200;
      return !_isServerDown;
    } catch (e) {
      _isServerDown = true;
      return false;
    }
  }

  /// 재시도 로직이 포함된 HTTP 요청 wrapper
  static Future<T> _retryRequest<T>(
    Future<T> Function() request, {
    int maxAttempts = maxRetries,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxAttempts) {
      try {
        return await request();
      } on SocketException catch (e) {
        lastException = Exception('서버에 연결할 수 없습니다. 네트워크 연결을 확인해주세요.');
        print('❌ DEBUG - SocketException (attempt ${attempt + 1}/$maxAttempts): $e');
      } on HttpException catch (e) {
        lastException = Exception('서버 오류가 발생했습니다: $e');
        print('❌ DEBUG - HttpException (attempt ${attempt + 1}/$maxAttempts): $e');
      } on FormatException catch (e) {
        lastException = Exception('잘못된 응답 형식입니다: $e');
        print('❌ DEBUG - FormatException (attempt ${attempt + 1}/$maxAttempts): $e');
        break; // 재시도 불필요
      } catch (e) {
        lastException = e as Exception;
        print('❌ DEBUG - Exception (attempt ${attempt + 1}/$maxAttempts): $e');
      }

      attempt++;
      if (attempt < maxAttempts) {
        print('⏳ DEBUG - ${retryDelay.inSeconds}초 후 재시도...');
        await Future.delayed(retryDelay);
      }
    }

    _isServerDown = true;
    throw lastException ?? Exception('서버 요청 실패');
  }

  /// GET 요청 (인증 불필요)
  static Future<Map<String, dynamic>> get(String path) async {
    return await _retryRequest(() async {
      final url = Uri.parse('$baseUrl$path');

      try {
        final response = await http.get(
          url,
          headers: _getHeaders(),
        ).timeout(
          requestTimeout,
          onTimeout: () {
            throw SocketException('서버 응답 시간 초과 (${requestTimeout.inSeconds}초)');
          },
        );

        _isServerDown = false; // 성공 시 서버 정상 상태로 업데이트
        return _handleResponse(response);
      } on SocketException catch (e) {
        print('❌ DEBUG - GET $path - SocketException: $e');
        _isServerDown = true;
        rethrow;
      } on HttpException catch (e) {
        print('❌ DEBUG - GET $path - HttpException: $e');
        rethrow;
      } catch (e) {
        print('❌ DEBUG - GET $path - Error: $e');
        rethrow;
      }
    });
  }

  /// GET 요청 (인증 필요)
  static Future<Map<String, dynamic>> getAuth(String path) async {
    return await _retryRequest(() async {
      final url = Uri.parse('$baseUrl$path');

      try {
        final response = await http.get(
          url,
          headers: _getHeaders(includeAuth: true),
        ).timeout(
          requestTimeout,
          onTimeout: () {
            throw SocketException('서버 응답 시간 초과 (${requestTimeout.inSeconds}초)');
          },
        );

        _isServerDown = false;
        return _handleResponse(response);
      } on SocketException catch (e) {
        print('❌ DEBUG - GET AUTH $path - SocketException: $e');
        _isServerDown = true;
        rethrow;
      } catch (e) {
        print('❌ DEBUG - GET AUTH $path - Error: $e');
        rethrow;
      }
    });
  }

  /// POST 요청 (인증 불필요)
  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return await _retryRequest(() async {
      final url = Uri.parse('$baseUrl$path');

      try {
        final response = await http.post(
          url,
          headers: _getHeaders(),
          body: jsonEncode(body),
        ).timeout(
          requestTimeout,
          onTimeout: () {
            throw SocketException('서버 응답 시간 초과 (${requestTimeout.inSeconds}초)');
          },
        );

        _isServerDown = false;
        return _handleResponse(response);
      } on SocketException catch (e) {
        print('❌ DEBUG - POST $path - SocketException: $e');
        _isServerDown = true;
        rethrow;
      } catch (e) {
        print('❌ DEBUG - POST $path - Error: $e');
        rethrow;
      }
    });
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
      final message = body['message'] ?? body['error'] ?? '알 수 없는 오류가 발생했습니다.';
      print('❌ DEBUG - Error Message: $message');

      // 404 에러인 경우 특별 처리를 위해 상태 코드 포함
      if (response.statusCode == 404) {
        throw Exception('404_NOT_FOUND: $message');
      }

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
    print('🔍 DEBUG - getPlaces called: categoryId=$categoryId, page=$page, size=$size');

    final response = await get(
      '/perfacto/every/places/category/$categoryId?page=$page&size=$size',
    );

    print('🔍 DEBUG - getPlaces response keys: ${response.keys}');

    final content = response['data']['content'] as List<dynamic>;
    print('🔍 DEBUG - getPlaces returning ${content.length} places');

    return content;
  }

  /// 장소 상세 조회
  static Future<Map<String, dynamic>> getPlace(String placeId) async {
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

    // data가 리스트인 경우와 pagination 객체인 경우 모두 처리
    if (response['data'] is List) {
      return response['data'] as List<dynamic>;
    } else {
      return response['data']['content'] as List<dynamic>;
    }
  }

  /// 팔로잉 사용자의 리뷰 목록 조회
  static Future<List<dynamic>> getFollowingReviews(int placeId) async {
    final response = await getAuth('/perfacto/api/reviews/place/$placeId/following');
    return response['data'] as List<dynamic>;
  }

  /// 사용자의 리뷰 목록 조회
  static Future<List<dynamic>> getUserReviews(int userId, {int page = 0, int size = 20}) async {
    try {
      final response = await get('/perfacto/every/reviews/user/$userId?page=$page&size=$size');

      // data가 리스트인 경우와 pagination 객체인 경우 모두 처리
      if (response['data'] is List) {
        return response['data'] as List<dynamic>;
      } else {
        return response['data']['content'] as List<dynamic>;
      }
    } catch (e) {
      // 404 에러 또는 엔드포인트 미구현 시 빈 배열 반환
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ 사용자 리뷰 엔드포인트 미구현: 빈 배열 반환');
        return [];
      }
      // 다른 에러는 다시 던짐
      rethrow;
    }
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
    try {
      await postAuth('/perfacto/api/saved-places', {
        'placeId': placeId,
        if (memo != null) 'memo': memo,
      });
      print('✅ DEBUG - 장소 저장 성공: placeId=$placeId');
    } catch (e) {
      print('❌ DEBUG - savePlace error: $e');

      // 404 에러인 경우 사용자에게 알림
      if (e.toString().contains('404_NOT_FOUND') ||
          e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        throw Exception('저장 기능이 아직 준비 중입니다. 곧 이용하실 수 있습니다.');
      }

      rethrow;
    }
  }

  /// 장소 저장 취소
  static Future<void> unsavePlace(int placeId) async {
    try {
      await delete('/perfacto/api/saved-places/$placeId');
      print('✅ DEBUG - 장소 저장 취소 성공: placeId=$placeId');
    } catch (e) {
      print('❌ DEBUG - unsavePlace error: $e');

      // 404 에러인 경우 사용자에게 알림
      if (e.toString().contains('404_NOT_FOUND') ||
          e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        throw Exception('저장 취소 기능이 아직 준비 중입니다.');
      }

      rethrow;
    }
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

      // FormatException: 백엔드 순환 참조 문제 (JSON 파싱 실패)
      if (e.toString().contains('FormatException') ||
          e.toString().contains('Unexpected character')) {
        print('⚠️ DEBUG - 백엔드 응답 형식 오류 (순환 참조). 빈 배열 반환');
        return [];
      }

      // 404 에러인 경우 빈 배열 반환 (백엔드 API 미구현)
      if (e.toString().contains('404_NOT_FOUND') ||
          e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        print('⚠️ DEBUG - 저장된 장소 API가 아직 구현되지 않았습니다. 빈 배열 반환');
        return [];
      }

      // 기타 에러는 사용자에게 표시
      rethrow;
    }
  }

  /// 장소 저장 여부 확인
  static Future<bool> isSaved(int placeId) async {
    try {
      final response = await getAuth('/perfacto/api/saved-places/check/$placeId');
      return response['data'] as bool;
    } catch (e) {
      // 404 에러인 경우 false 반환 (백엔드 API 미구현)
      if (e.toString().contains('404_NOT_FOUND') ||
          e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        print('⚠️ DEBUG - 저장된 장소 확인 API가 아직 구현되지 않았습니다.');
        return false;
      }
      rethrow;
    }
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
    print('🔍 DEBUG - API login called');

    try {
      final response = await post('/perfacto/auth/login', {
        'email': email,
        'password': password,
      });

      print('🔍 DEBUG - login API response keys: ${response.keys}');
      print('🔍 DEBUG - login API full response: $response');

      // 응답 구조 확인: {code, message, data} 형태인지 확인
      final data = response['data'] ?? response;

      print('🔍 DEBUG - login data: $data');

      // 토큰 저장
      if (data['accessToken'] != null) {
        setTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );
      }

      return data;
    } catch (e) {
      print('❌ DEBUG - login API error: $e');
      rethrow;
    }
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

  /// 사용자 프로필 업데이트 (닉네임, 프로필 이미지)
  static Future<void> updateUserProfile({
    String? nickname,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickName'] = nickname;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

    if (body.isEmpty) {
      throw Exception('업데이트할 정보가 없습니다');
    }

    await patch('/perfacto/api/user/profile', body);
  }

  /// 이미지 파일 업로드 (Base64)
  static Future<String> uploadImage(String base64Image) async {
    try {
      final response = await postAuth('/perfacto/api/images/upload', {
        'image': base64Image,
      });

      // 백엔드에서 업로드된 이미지 URL 반환
      return response['data']['imageUrl'] as String;
    } catch (e) {
      print('❌ 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  // ==================== Match Score API ====================

  /// 특정 사용자와의 Match Score 조회
  static Future<Map<String, dynamic>> getMatchScore(int targetUserId) async {
    try {
      final response = await getAuth('/perfacto/api/match-score/$targetUserId');
      return response['data'];
    } catch (e) {
      print('❌ DEBUG - getMatchScore error: $e');
      // 백엔드 미구현 시 더미 데이터 반환
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Match Score API 미구현: 더미 데이터 반환');
        return {
          'userId': _accessToken != null ? 1 : 0,
          'targetUserId': targetUserId,
          'score': 0.0,
          'commonPlacesCount': 0,
          'compatibility': 'NEUTRAL',
          'calculatedAt': DateTime.now().toIso8601String(),
        };
      }
      rethrow;
    }
  }

  /// 내 팔로잉 중 Match Score Top 10
  static Future<List<Map<String, dynamic>>> getTopMatchScores() async {
    try {
      final response = await getAuth('/perfacto/api/match-score/top');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      print('❌ DEBUG - getTopMatchScores error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Top Match Score API 미구현: 빈 배열 반환');
        return [];
      }
      rethrow;
    }
  }

  /// 전체 사용자 중 Match Score 높은 순 (추천 친구)
  static Future<List<Map<String, dynamic>>> getRecommendedFriends({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await getAuth(
        '/perfacto/api/match-score/recommendations?page=$page&size=$size',
      );
      return List<Map<String, dynamic>>.from(response['data']['content']);
    } catch (e) {
      print('❌ DEBUG - getRecommendedFriends error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Recommended Friends API 미구현: 빈 배열 반환');
        return [];
      }
      rethrow;
    }
  }

  // ==================== Predicted Score API ====================

  /// 장소의 예측 점수 조회
  static Future<Map<String, dynamic>?> getPredictedScore(int placeId) async {
    try {
      final response = await getAuth('/perfacto/api/predicted-score/$placeId');
      return response['data'];
    } catch (e) {
      print('❌ DEBUG - getPredictedScore error: $e');
      // 로그인 안 했거나 데이터 부족 시 null 반환
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Predicted Score API 미구현: null 반환');
        return null;
      }
      return null;
    }
  }

  /// 여러 장소의 예측 점수 일괄 조회
  static Future<Map<int, Map<String, dynamic>>> getPredictedScoresBatch(
    List<int> placeIds,
  ) async {
    try {
      final response = await postAuth('/perfacto/api/predicted-score/batch', {
        'placeIds': placeIds,
      });

      final Map<int, Map<String, dynamic>> result = {};
      if (response['data'] is List) {
        for (final item in response['data']) {
          result[item['placeId'] as int] = item;
        }
      }
      return result;
    } catch (e) {
      print('❌ DEBUG - getPredictedScoresBatch error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Predicted Score Batch API 미구현: 빈 맵 반환');
        return {};
      }
      return {};
    }
  }

  // ==================== Gamification API ====================

  /// 글로벌 리더보드 조회
  static Future<List<Map<String, dynamic>>> getGlobalLeaderboard({
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await get(
        '/perfacto/every/leaderboard/global?page=$page&size=$size',
      );
      if (response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response['data']['content'] is List) {
        return List<Map<String, dynamic>>.from(response['data']['content']);
      }
      return [];
    } catch (e) {
      print('❌ DEBUG - getGlobalLeaderboard error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Global Leaderboard API 미구현: 빈 배열 반환');
        return [];
      }
      return [];
    }
  }

  /// 도시별 리더보드 조회
  static Future<List<Map<String, dynamic>>> getCityLeaderboard(
    String city, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await get(
        '/perfacto/every/leaderboard/city/$city?page=$page&size=$size',
      );
      if (response['data'] is List) {
        return List<Map<String, dynamic>>.from(response['data']);
      } else if (response['data']['content'] is List) {
        return List<Map<String, dynamic>>.from(response['data']['content']);
      }
      return [];
    } catch (e) {
      print('❌ DEBUG - getCityLeaderboard error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ City Leaderboard API 미구현: 빈 배열 반환');
        return [];
      }
      return [];
    }
  }

  /// 내 Streak 정보 조회
  static Future<Map<String, dynamic>> getMyStreak() async {
    try {
      final response = await getAuth('/perfacto/api/streak');
      return response['data'];
    } catch (e) {
      print('❌ DEBUG - getMyStreak error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Streak API 미구현: 더미 데이터 반환');
        return {
          'currentStreak': 0,
          'longestStreak': 0,
          'lastReviewDate': null,
          'reviewedToday': false,
          'hoursUntilStreakBreak': 24,
        };
      }
      rethrow;
    }
  }

  /// 내 잠금 해제 상태 조회
  static Future<Map<String, bool>> getUnlockedFeatures() async {
    try {
      final response = await getAuth('/perfacto/api/features/unlocked');
      return Map<String, bool>.from(response['data']);
    } catch (e) {
      print('❌ DEBUG - getUnlockedFeatures error: $e');
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Unlocked Features API 미구현: 빈 맵 반환');
        return {};
      }
      return {};
    }
  }

  // ==================== 태그 API ====================

  /// 리뷰 작성 시 태그 포함 (createReview 확장)
  ///
  /// 기존 createReview 메서드를 수정하여 tags 파라미터 추가
  static Future<Map<String, dynamic>> createReviewWithTags({
    required int placeId,
    required String overallRating, // 'GOOD', 'NEUTRAL', 'BAD'
    required List<String> reasons, // ReviewReason enum values
    List<String>? tags, // PlaceTag enum codes
    int? comparedPlaceId,
    String? comparisonResult, // 'BETTER', 'SIMILAR', 'WORSE'
  }) async {
    final Map<String, dynamic> body = {
      'placeId': placeId,
      'overallRating': overallRating,
      'reasons': reasons,
    };

    if (tags != null && tags.isNotEmpty) body['tags'] = tags;
    if (comparedPlaceId != null) body['comparedPlaceId'] = comparedPlaceId;
    if (comparisonResult != null) body['comparisonResult'] = comparisonResult;

    final response = await postAuth('/perfacto/api/reviews', body);
    return response['data'];
  }
}
