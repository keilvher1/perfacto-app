import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firestore_service.dart';

/// 저장된 장소를 Firestore와 로컬에서 관리하는 서비스
/// Firestore를 primary로 사용하고, SharedPreferences는 캐시/오프라인 지원용
class SavedPlacesService {
  static const String _keySavedPlaceIds = 'saved_place_ids';

  /// 장소 저장 (Firestore + 로컬 캐시)
  static Future<void> savePlace(String placeId) async {
    try {
      // 1. Firestore에 저장 (primary storage)
      await FirestoreService.savePlace(placeId);
      print('✅ Firestore에 저장: placeId=$placeId');

      // 2. 로컬 캐시에도 저장
      final prefs = await SharedPreferences.getInstance();
      final savedIds = await getSavedPlaceIds();

      if (!savedIds.contains(placeId)) {
        savedIds.add(placeId);
        await prefs.setString(_keySavedPlaceIds, jsonEncode(savedIds));
        print('✅ 로컬 캐시에 저장: placeId=$placeId');
      }
    } catch (e) {
      print('❌ 장소 저장 실패: $e');

      // Firestore 실패 시에도 로컬에는 저장
      final prefs = await SharedPreferences.getInstance();
      final savedIds = await getSavedPlaceIds();

      if (!savedIds.contains(placeId)) {
        savedIds.add(placeId);
        await prefs.setString(_keySavedPlaceIds, jsonEncode(savedIds));
        print('⚠️ 로컬에만 저장 (Firestore 동기화 대기): placeId=$placeId');
      }

      rethrow;
    }
  }

  /// 장소 저장 취소 (Firestore + 로컬 캐시)
  static Future<void> unsavePlace(String placeId) async {
    try {
      // 1. Firestore에서 삭제 (primary storage)
      await FirestoreService.unsavePlace(placeId);
      print('✅ Firestore에서 삭제: placeId=$placeId');

      // 2. 로컬 캐시에서도 삭제
      final prefs = await SharedPreferences.getInstance();
      final savedIds = await getSavedPlaceIds();

      savedIds.remove(placeId);
      await prefs.setString(_keySavedPlaceIds, jsonEncode(savedIds));
      print('✅ 로컬 캐시에서 삭제: placeId=$placeId');
    } catch (e) {
      print('❌ 장소 삭제 실패: $e');

      // Firestore 실패 시에도 로컬에서는 삭제
      final prefs = await SharedPreferences.getInstance();
      final savedIds = await getSavedPlaceIds();

      savedIds.remove(placeId);
      await prefs.setString(_keySavedPlaceIds, jsonEncode(savedIds));
      print('⚠️ 로컬에서만 삭제 (Firestore 동기화 대기): placeId=$placeId');

      rethrow;
    }
  }

  /// 저장된 장소 ID 목록 조회 (Firestore 우선, 실패 시 로컬 캐시)
  static Future<List<String>> getSavedPlaceIds() async {
    try {
      // 1. Firestore에서 조회 시도
      final places = await FirestoreService.getSavedPlaces();
      final placeIds = places.map((place) => place.id).toList();

      if (placeIds.isNotEmpty) {
        // 로컬 캐시 업데이트
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keySavedPlaceIds, jsonEncode(placeIds));
        print('✅ Firestore에서 ${placeIds.length}개 장소 조회 완료');
      }

      return placeIds;
    } catch (e) {
      print('⚠️ Firestore 조회 실패, 로컬 캐시 사용: $e');

      // 2. Firestore 실패 시 로컬 캐시에서 조회
      final prefs = await SharedPreferences.getInstance();
      final savedIdsJson = prefs.getString(_keySavedPlaceIds);

      if (savedIdsJson == null || savedIdsJson.isEmpty) {
        return [];
      }

      try {
        final List<dynamic> decoded = jsonDecode(savedIdsJson);
        return decoded.map((id) => id.toString()).toList();
      } catch (e) {
        print('❌ 저장된 장소 ID 파싱 오류: $e');
        return [];
      }
    }
  }

  /// 장소 저장 여부 확인 (Firestore 우선)
  static Future<bool> isSaved(String placeId) async {
    try {
      return await FirestoreService.isSaved(placeId);
    } catch (e) {
      print('⚠️ Firestore 조회 실패, 로컬 캐시 사용: $e');
      final savedIds = await getSavedPlaceIds();
      return savedIds.contains(placeId);
    }
  }

  /// 모든 저장된 장소 삭제
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedPlaceIds);
    print('✅ 로컬 캐시 삭제 완료');
    // 참고: Firestore 데이터는 삭제하지 않음 (사용자가 명시적으로 삭제 요청 시에만)
  }

  /// Firestore와 로컬 캐시 동기화
  static Future<void> syncWithFirestore() async {
    try {
      final places = await FirestoreService.getSavedPlaces();
      final placeIds = places.map((place) => place.id).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySavedPlaceIds, jsonEncode(placeIds));

      print('✅ Firestore 동기화 완료: ${placeIds.length}개 장소');
    } catch (e) {
      print('❌ Firestore 동기화 실패: $e');
    }
  }
}
