import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/place_model.dart';

/// 카테고리별 장소 목록을 가져오는 Provider
///
/// Example: ref.watch(firestore PlacesProvider('restaurant'))
final firestorePlacesProvider = FutureProvider.family<List<PlaceModel>, String>(
  (ref, categoryCode) async {
    return await FirestoreService.getPlacesByCategory(categoryCode: categoryCode);
  },
);

/// 모든 카테고리의 장소를 가져오는 Provider
final allPlacesProvider = FutureProvider<List<PlaceModel>>((ref) async {
  final categories = ['restaurant', 'accommodation', 'cafe', 'attraction'];
  final List<PlaceModel> allPlaces = [];

  for (String categoryCode in categories) {
    try {
      final places = await FirestoreService.getPlacesByCategory(
        categoryCode: categoryCode,
      );
      allPlaces.addAll(places);
    } catch (e) {
      print('Error loading $categoryCode: $e');
    }
  }

  return allPlaces;
});

/// 사용자가 저장한 장소 ID 목록을 관리하는 StateNotifier
class SavedPlacesNotifier extends StateNotifier<Set<String>> {
  SavedPlacesNotifier() : super({});

  /// 장소 저장
  void savePlace(String placeId) {
    state = {...state, placeId};
  }

  /// 장소 저장 취소
  void unsavePlace(String placeId) {
    state = state.where((id) => id != placeId).toSet();
  }

  /// 장소가 저장되어 있는지 확인
  bool isSaved(String placeId) {
    return state.contains(placeId);
  }

  /// 저장된 장소 목록 초기화
  void setSavedPlaces(Set<String> placeIds) {
    state = placeIds;
  }
}

/// 저장된 장소 ID 목록 Provider
final savedPlacesProvider = StateNotifierProvider<SavedPlacesNotifier, Set<String>>(
  (ref) => SavedPlacesNotifier(),
);
