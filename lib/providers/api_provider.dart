import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// 랭킹 장소 목록을 가져오는 Provider
///
/// Example: ref.watch(rankingProvider(limit: 10))
final rankingProvider = FutureProvider.family<List<dynamic>, int>(
  (ref, limit) async {
    return await ApiService.getRanking(limit: limit);
  },
);

/// 특정 장소의 상세 정보를 가져오는 Provider
///
/// Example: ref.watch(placeDetailProvider(placeId))
final placeDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, placeId) async {
    return await ApiService.getPlace(placeId);
  },
);

/// 장소 검색 Provider
///
/// Example: ref.watch(searchPlacesProvider('카페'))
final searchPlacesProvider = FutureProvider.family<List<dynamic>, String>(
  (ref, query) async {
    return await ApiService.searchPlaces(query);
  },
);

/// 카테고리 목록을 가져오는 Provider
final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return await ApiService.getCategories();
});

/// 장소 목록을 가져오는 Provider (카테고리 필터링)
///
/// Example: ref.watch(placesByCategoryProvider(1))
final placesByCategoryProvider = FutureProvider.autoDispose.family<List<dynamic>, int>(
  (ref, categoryId) async {
    return await ApiService.getPlaces(categoryId: categoryId);
  },
);
