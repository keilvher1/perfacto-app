import 'package:firebase_performance/firebase_performance.dart';

/// Firebase Performance Monitoring 서비스
///
/// 앱 성능을 모니터링하고 병목 현상을 식별하기 위한 서비스
/// - 화면 로딩 시간 추적
/// - API 호출 성능 측정
/// - 커스텀 성능 지표 수집
class PerformanceService {
  static final FirebasePerformance _performance =
      FirebasePerformance.instance;

  /// Performance Monitoring 초기화
  ///
  /// 앱 시작 시 호출하여 자동 추적 활성화
  static Future<void> initialize() async {
    try {
      await _performance.setPerformanceCollectionEnabled(true);
      print('✅ Firebase Performance Monitoring 초기화 완료');
    } catch (e) {
      print('⚠️ Firebase Performance Monitoring 초기화 실패: $e');
    }
  }

  /// 커스텀 트레이스 시작
  ///
  /// 특정 작업의 성능을 측정하고 싶을 때 사용
  /// ```dart
  /// final trace = await PerformanceService.startTrace('load_places');
  /// // ... 작업 수행 ...
  /// await PerformanceService.stopTrace(trace);
  /// ```
  static Future<Trace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return trace;
  }

  /// 커스텀 트레이스 종료
  ///
  /// startTrace로 시작한 트레이스를 종료하고 결과를 Firebase에 전송
  static Future<void> stopTrace(Trace trace) async {
    await trace.stop();
  }

  /// 트레이스에 커스텀 메트릭 추가
  ///
  /// 예: 로딩된 아이템 개수, 처리한 데이터 크기 등
  static void setTraceMetric(Trace trace, String key, int value) {
    trace.setMetric(key, value);
  }

  /// 트레이스에 커스텀 속성 추가
  ///
  /// 예: 사용자 타입, 데이터 소스 등
  static void setTraceAttribute(Trace trace, String key, String value) {
    trace.putAttribute(key, value);
  }

  /// HTTP 요청 추적 생성
  ///
  /// API 호출 성능을 자동으로 측정
  /// ```dart
  /// final metric = PerformanceService.newHttpMetric(
  ///   'https://api.perfacto.com/places',
  ///   HttpMethod.Get,
  /// );
  /// await metric.start();
  /// // ... HTTP 요청 ...
  /// metric.responseCode = response.statusCode;
  /// metric.responsePayloadSize = response.data.length;
  /// await metric.stop();
  /// ```
  static HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // 주요 화면별 트레이스 이름
  static const String traceHomePageInit = 'home_page_init';
  static const String traceLoadPlaces = 'load_places';
  static const String traceLoadMarkers = 'load_markers';
  static const String traceLoadPolygons = 'load_polygons';
  static const String tracePlaceDetail = 'place_detail_load';
  static const String traceReviewSubmit = 'review_submit';
  static const String traceUserProfile = 'user_profile_load';

  // API 엔드포인트별 추적
  static const String apiGetPlaces = '/perfacto/every/places/ranking';
  static const String apiGetPlace = '/perfacto/api/places/';
  static const String apiGetReviews = '/perfacto/api/reviews/place/';
  static const String apiPostReview = '/perfacto/api/reviews';
}

/// 편리한 트레이스 래퍼 클래스
///
/// try-finally 패턴을 간단하게 사용하기 위한 헬퍼
/// ```dart
/// await PerformanceTrace.run('my_operation', () async {
///   // 측정할 작업
/// });
/// ```
class PerformanceTrace {
  /// 작업을 트레이스로 감싸서 실행
  static Future<T> run<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, int>? metrics,
    Map<String, String>? attributes,
  }) async {
    final trace = await PerformanceService.startTrace(traceName);

    try {
      // 커스텀 메트릭/속성 추가
      if (metrics != null) {
        metrics.forEach((key, value) {
          PerformanceService.setTraceMetric(trace, key, value);
        });
      }
      if (attributes != null) {
        attributes.forEach((key, value) {
          PerformanceService.setTraceAttribute(trace, key, value);
        });
      }

      return await operation();
    } finally {
      await PerformanceService.stopTrace(trace);
    }
  }
}
