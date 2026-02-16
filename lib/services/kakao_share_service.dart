import 'package:share_plus/share_plus.dart';

/// 카카오 공유 서비스
///
/// 참고: 완전한 카카오 SDK 통합을 위해서는 kakao_flutter_sdk_share 패키지 필요
/// 현재는 share_plus를 사용한 기본 공유 구현
class KakaoShareService {
  /// 장소 공유하기
  static Future<void> sharePlace({
    required String placeName,
    double? score,
    String? imageUrl,
    required String deepLink,
  }) async {
    try {
      String shareText = '🏪 $placeName';

      if (score != null) {
        shareText += '\n⭐ 내 점수: ${score.toStringAsFixed(1)}점';
      }

      shareText += '\n\n📍 Perfacto에서 자세히 보기:\n$deepLink';

      // share_plus를 사용한 기본 공유
      await Share.share(
        shareText,
        subject: '$placeName - Perfacto',
      );
    } catch (e) {
      print('❌ DEBUG - sharePlace error: $e');
      rethrow;
    }
  }

  /// 리뷰 공유하기
  static Future<void> shareReview({
    required String placeName,
    required String rating,
    required String deepLink,
  }) async {
    try {
      String emoji = _getRatingEmoji(rating);
      String shareText = '$emoji $placeName에 리뷰를 남겼어요!\n\n'
          '📝 평가: $rating\n'
          '\n📍 Perfacto에서 자세히 보기:\n$deepLink';

      await Share.share(
        shareText,
        subject: '$placeName 리뷰 - Perfacto',
      );
    } catch (e) {
      print('❌ DEBUG - shareReview error: $e');
      rethrow;
    }
  }

  /// 리더보드 순위 공유하기
  static Future<void> shareLeaderboard({
    required int rank,
    required int reviewCount,
    required int streak,
  }) async {
    try {
      String shareText = '🏆 Perfacto 리더보드 순위!\n\n'
          '📊 순위: $rank위\n'
          '✍️ 리뷰: $reviewCount개\n'
          '🔥 Streak: $streak일\n'
          '\n📍 Perfacto에서 함께 해요!';

      await Share.share(
        shareText,
        subject: 'Perfacto 리더보드',
      );
    } catch (e) {
      print('❌ DEBUG - shareLeaderboard error: $e');
      rethrow;
    }
  }

  /// 평점에 맞는 이모지 반환
  static String _getRatingEmoji(String rating) {
    switch (rating.toUpperCase()) {
      case 'GOOD':
        return '😊';
      case 'NEUTRAL':
        return '😐';
      case 'BAD':
        return '😞';
      default:
        return '📝';
    }
  }

  /// TODO: 카카오 SDK 통합 시 구현
  ///
  /// 완전한 카카오톡 공유 템플릿을 사용하려면:
  /// 1. pubspec.yaml에 kakao_flutter_sdk_share 추가
  /// 2. 카카오 개발자 센터에서 앱 등록
  /// 3. Android/iOS 네이티브 설정
  /// 4. 아래 메서드 구현
  ///
  /// ```dart
  /// static Future<void> shareToKakaoTalk({...}) async {
  ///   if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
  ///     await ShareClient.instance.shareDefault(template: template);
  ///   }
  /// }
  /// ```
}
