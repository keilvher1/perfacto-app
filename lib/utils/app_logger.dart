import 'package:flutter/foundation.dart';

/// 앱 전역 로깅 유틸리티
///
/// 개발 모드에서만 로그를 출력하며, 프로덕션 빌드에서는 자동으로 제거됩니다.
class AppLogger {
  /// 일반 로그
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  /// 에러 로그
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }

  /// 성공 로그
  static void success(String message) {
    if (kDebugMode) {
      print('✅ $message');
    }
  }

  /// 디버그 로그
  static void debug(String message) {
    if (kDebugMode) {
      print('🔍 DEBUG - $message');
    }
  }

  /// 경고 로그
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ $message');
    }
  }

  /// 정보 로그
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ $message');
    }
  }
}
