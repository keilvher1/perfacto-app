/// API 설정 관리
///
/// 환경 변수를 통해 API 엔드포인트를 관리합니다.
/// 개발/스테이징/프로덕션 환경별로 다른 URL 사용 가능
class ApiConfig {
  /// API Base URL
  ///
  /// 빌드 시 환경 변수로 주입:
  /// ```
  /// flutter run --dart-define=API_BASE_URL=https://api.perfacto.com
  /// ```
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.perfacto.com', // 기본값 (프로덕션)
  );

  /// 개발 환경 여부
  static const bool isDevelopment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  ) == 'development';

  /// API 타임아웃 (밀리초)
  static const int timeoutMs = int.fromEnvironment(
    'API_TIMEOUT_MS',
    defaultValue: 30000,
  );

  /// 재시도 횟수
  static const int maxRetries = int.fromEnvironment(
    'API_MAX_RETRIES',
    defaultValue: 3,
  );

  /// 디버그 로그 출력 여부
  static bool get enableDebugLog => isDevelopment;

  /// Google Maps API Key
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBAanV6MxGlXWU26eSHHzMtSNC02K6w2wA',
  );

  /// 환경 정보 출력
  static void printConfig() {
    if (enableDebugLog) {
      print('🔧 API Configuration:');
      print('  - Base URL: $baseUrl');
      print('  - Environment: ${isDevelopment ? 'Development' : 'Production'}');
      print('  - Timeout: ${timeoutMs}ms');
      print('  - Max Retries: $maxRetries');
    }
  }
}
