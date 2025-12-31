import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 저장된 장소를 로컬에서 관리하는 서비스
/// (백엔드 API 순환 참조 문제로 인한 임시 해결책)
class SavedPlacesService {
  static const String _keySavedPlaceIds = 'saved_place_ids';

  /// 장소 저장
  static Future<void> savePlace(int placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = await getSavedPlaceIds();
    
    if (!savedIds.contains(placeId)) {
      savedIds.add(placeId);
      await prefs.setString(_keySavedPlaceIds, jsonEncode(savedIds));
      print('✅ 로컬 저장: placeId=$placeId');
    }
  }

  /// 장소 저장 취소
  static Future<void> unsavePlace(int placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = await getSavedPlaceIds();
    
    savedIds.remove(placeId);
    await prefs.setString(_keySavedPlaceIds, jsonEncode(savedIds));
    print('✅ 로컬 저장 취소: placeId=$placeId');
  }

  /// 저장된 장소 ID 목록 조회
  static Future<List<int>> getSavedPlaceIds() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIdsJson = prefs.getString(_keySavedPlaceIds);
    
    if (savedIdsJson == null || savedIdsJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(savedIdsJson);
      return decoded.map((id) => id as int).toList();
    } catch (e) {
      print('❌ 저장된 장소 ID 파싱 오류: $e');
      return [];
    }
  }

  /// 장소 저장 여부 확인
  static Future<bool> isSaved(int placeId) async {
    final savedIds = await getSavedPlaceIds();
    return savedIds.contains(placeId);
  }

  /// 모든 저장된 장소 삭제
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedPlaceIds);
  }
}
