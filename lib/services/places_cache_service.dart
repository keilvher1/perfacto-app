import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/place_model.dart';

/// 장소 데이터 캐싱 서비스 (성능 최적화)
/// 백엔드 API가 느릴 때 캐시된 데이터를 먼저 표시하여 사용자 경험 개선
class PlacesCacheService {
  static const String _keyPlacesCache = 'places_cache_v1';
  static const String _keyCacheTimestamp = 'places_cache_timestamp';
  static const int _cacheTTL = 300000; // 5분 (밀리초)

  /// 장소 목록을 캐시에 저장
  static Future<void> cachePlaces(List<PlaceModel> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 장소 데이터를 JSON으로 변환하여 저장
      final placesJson = places.map((place) => place.toJson()).toList();
      await prefs.setString(_keyPlacesCache, jsonEncode(placesJson));

      // 현재 시간을 타임스탬프로 저장
      await prefs.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch);

      print('✅ PlacesCache: ${places.length}개 장소 캐시됨');
    } catch (e) {
      print('❌ PlacesCache 저장 실패: $e');
    }
  }

  /// 캐시된 장소 목록을 가져옴 (유효한 경우만)
  static Future<List<PlaceModel>?> getCachedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 캐시 데이터 확인
      final cachedJson = prefs.getString(_keyPlacesCache);
      final timestamp = prefs.getInt(_keyCacheTimestamp);

      if (cachedJson == null || timestamp == null) {
        print('ℹ️ PlacesCache: 캐시 없음');
        return null;
      }

      // 캐시 유효성 확인 (5분 이내)
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;

      if (age > _cacheTTL) {
        print('⏰ PlacesCache: 캐시 만료됨 (${(age / 1000).toStringAsFixed(0)}초 경과)');
        return null;
      }

      // JSON 파싱
      final List<dynamic> jsonList = jsonDecode(cachedJson);
      final places = jsonList
          .map((json) => PlaceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ PlacesCache: ${places.length}개 장소 로드됨 (${(age / 1000).toStringAsFixed(0)}초 전 캐시)');
      return places;
    } catch (e) {
      print('❌ PlacesCache 로드 실패: $e');
      return null;
    }
  }

  /// 캐시 삭제
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPlacesCache);
      await prefs.remove(_keyCacheTimestamp);
      print('🗑️ PlacesCache: 캐시 삭제됨');
    } catch (e) {
      print('❌ PlacesCache 삭제 실패: $e');
    }
  }

  /// 캐시 상태 확인
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyCacheTimestamp);

      if (timestamp == null) {
        return {'exists': false};
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      final isValid = age <= _cacheTTL;

      return {
        'exists': true,
        'isValid': isValid,
        'ageSeconds': (age / 1000).toInt(),
        'remainingSeconds': isValid ? ((_cacheTTL - age) / 1000).toInt() : 0,
      };
    } catch (e) {
      return {'exists': false, 'error': e.toString()};
    }
  }
}
