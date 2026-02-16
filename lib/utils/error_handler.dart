import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_logger.dart';

/// 앱 전역 에러 핸들러
///
/// 모든 에러를 사용자 친화적인 메시지로 변환하고, 적절한 처리를 제공합니다.
class ErrorHandler {
  /// Firebase Auth 에러 메시지
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return '등록되지 않은 이메일입니다.';
        case 'wrong-password':
          return '비밀번호가 올바르지 않습니다.';
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'weak-password':
          return '비밀번호는 6자 이상이어야 합니다.';
        case 'invalid-email':
          return '유효하지 않은 이메일 형식입니다.';
        case 'user-disabled':
          return '비활성화된 계정입니다.';
        case 'too-many-requests':
          return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요.';
        case 'operation-not-allowed':
          return '이 인증 방식은 현재 사용할 수 없습니다.';
        case 'requires-recent-login':
          return '보안을 위해 다시 로그인해주세요.';
        default:
          return '로그인 중 오류가 발생했습니다. (${error.code})';
      }
    }
    return '인증 중 오류가 발생했습니다.';
  }

  /// Firestore 에러 메시지
  static String getFirestoreErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return '접근 권한이 없습니다.';
        case 'not-found':
          return '요청한 데이터를 찾을 수 없습니다.';
        case 'already-exists':
          return '이미 존재하는 데이터입니다.';
        case 'resource-exhausted':
          return '서버가 바쁩니다. 잠시 후 다시 시도해주세요.';
        case 'cancelled':
          return '요청이 취소되었습니다.';
        case 'deadline-exceeded':
          return '요청 시간이 초과되었습니다.';
        case 'unavailable':
          return '서비스를 사용할 수 없습니다. 네트워크 연결을 확인해주세요.';
        default:
          return '데이터 처리 중 오류가 발생했습니다. (${error.code})';
      }
    }
    return '데이터 처리 중 오류가 발생했습니다.';
  }

  /// 네트워크 에러 메시지
  static String getNetworkErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return '네트워크 연결을 확인해주세요.';
    }

    if (errorString.contains('timeout')) {
      return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
    }

    if (errorString.contains('404')) {
      return '요청한 리소스를 찾을 수 없습니다.';
    }

    if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    return '네트워크 요청 중 오류가 발생했습니다.';
  }

  /// 일반 에러 메시지 (catch-all)
  static String getGenericErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    }

    if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return getNetworkErrorMessage(error);
    }

    return '오류가 발생했습니다. 다시 시도해주세요.';
  }

  /// 사용자에게 에러 표시 (SnackBar)
  static void showError(BuildContext context, dynamic error, {String? customMessage}) {
    final message = customMessage ?? getGenericErrorMessage(error);

    // 로깅 (개발 모드에서만)
    AppLogger.error('Error occurred', error);

    // 사용자에게 표시
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: '확인',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// 성공 메시지 표시
  static void showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// 경고 메시지 표시
  static void showWarning(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  /// 재시도 가능한 작업 실행
  static Future<T> retryOperation<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delayBetweenRetries = const Duration(seconds: 2),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;

    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (error) {
        final isLastAttempt = attempts >= maxRetries;
        final canRetry = shouldRetry == null || shouldRetry(error);

        if (isLastAttempt || !canRetry) {
          AppLogger.error('Operation failed after $attempts attempts', error);
          rethrow;
        }

        AppLogger.warning('Attempt $attempts failed, retrying in ${delayBetweenRetries.inSeconds}s...');
        await Future.delayed(delayBetweenRetries);
      }
    }
  }

  /// 네트워크 오류인지 확인 (재시도 가능 여부 판단)
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout');
  }
}
