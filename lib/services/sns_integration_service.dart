import 'firestore_service.dart';

/// SNS 통합 서비스 (Instagram, TikTok)
/// Firebase 기반 구현
class SnsIntegrationService {
  /// 공유된 URL에서 장소 정보 추출
  ///
  /// Instagram/TikTok 공유 링크에서 장소 정보 파싱
  /// 현재는 수동 입력 방식 (Firebase Functions로 자동 파싱 가능)
  static Future<Map<String, dynamic>?> extractPlaceFromUrl(String url) async {
    // SNS URL에서 장소 정보를 자동으로 추출하려면 Firebase Functions 필요
    // 현재는 수동 입력으로 대체
    final platform = detectPlatform(url);
    if (platform == null) {
      throw Exception('지원하지 않는 SNS 플랫폼입니다.');
    }

    return {
      'sourceUrl': url,
      'sourcePlatform': platform,
    };
  }

  /// Want to Try 리스트에 SNS에서 발견한 장소 추가
  static Future<void> addToWantToTry({
    required String placeName,
    String? address,
    required String sourceUrl,
    required String sourcePlatform, // 'instagram', 'tiktok'
    String? notes,
  }) async {
    try {
      await FirestoreService.addToWantToTry(
        placeName: placeName,
        address: address,
        sourceUrl: sourceUrl,
        sourcePlatform: sourcePlatform,
        notes: notes,
      );
    } catch (e) {
      print('❌ SnsIntegrationService.addToWantToTry error: $e');
      rethrow;
    }
  }

  /// URL에서 SNS 플랫폼 감지
  static String? detectPlatform(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('instagram.com') || lowerUrl.contains('instagr.am')) {
      return 'instagram';
    } else if (lowerUrl.contains('tiktok.com') || lowerUrl.contains('vm.tiktok.com')) {
      return 'tiktok';
    }

    return null;
  }

  /// SNS URL 유효성 검사
  static bool isValidSnsUrl(String url) {
    return detectPlatform(url) != null;
  }
}
