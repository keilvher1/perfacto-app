import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:perfacto/models/place_model.dart';

/// home_page.dart의 상태 관리 클래스
///
/// 모든 상태 변수를 하나의 불변 클래스로 관리하여
/// 상태 추적과 디버깅을 용이하게 함
class HomeState {
  // 지도 관련
  final Set<Polygon> polygons;
  final Set<Marker> markers;
  final Map<String, int> districtGrades;

  // 장소 데이터
  final List<PlaceModel> firestorePlaces;

  // 필터 상태
  final Set<String> selectedCategories;
  final bool showSavedPlaces; // false: 카테고리 마커, true: 저장된 장소 마커
  final bool isLocalMode; // Local/Global 모드

  // UI 상태
  final bool isLoading;

  // 마커 캐싱
  final Map<String, BitmapDescriptor> markerIconCache;
  final bool markerIconsLoaded;

  const HomeState({
    required this.polygons,
    required this.markers,
    required this.districtGrades,
    required this.firestorePlaces,
    required this.selectedCategories,
    required this.showSavedPlaces,
    required this.isLocalMode,
    required this.isLoading,
    required this.markerIconCache,
    required this.markerIconsLoaded,
  });

  /// 초기 상태 생성
  factory HomeState.initial() {
    return HomeState(
      polygons: {},
      markers: {},
      districtGrades: {},
      firestorePlaces: [],
      selectedCategories: {
        'restaurant',
        'cafe',
        'attraction',
        'accommodation',
      },
      showSavedPlaces: false,
      isLocalMode: false,
      isLoading: true,
      markerIconCache: {},
      markerIconsLoaded: false,
    );
  }

  /// 상태 복사 메서드 (불변성 유지)
  HomeState copyWith({
    Set<Polygon>? polygons,
    Set<Marker>? markers,
    Map<String, int>? districtGrades,
    List<PlaceModel>? firestorePlaces,
    Set<String>? selectedCategories,
    bool? showSavedPlaces,
    bool? isLocalMode,
    bool? isLoading,
    Map<String, BitmapDescriptor>? markerIconCache,
    bool? markerIconsLoaded,
  }) {
    return HomeState(
      polygons: polygons ?? this.polygons,
      markers: markers ?? this.markers,
      districtGrades: districtGrades ?? this.districtGrades,
      firestorePlaces: firestorePlaces ?? this.firestorePlaces,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      showSavedPlaces: showSavedPlaces ?? this.showSavedPlaces,
      isLocalMode: isLocalMode ?? this.isLocalMode,
      isLoading: isLoading ?? this.isLoading,
      markerIconCache: markerIconCache ?? this.markerIconCache,
      markerIconsLoaded: markerIconsLoaded ?? this.markerIconsLoaded,
    );
  }

  /// 카테고리 토글
  HomeState toggleCategory(String category) {
    final newCategories = Set<String>.from(selectedCategories);
    if (newCategories.contains(category)) {
      newCategories.remove(category);
    } else {
      newCategories.add(category);
    }
    return copyWith(selectedCategories: newCategories);
  }

  /// 저장 장소 표시 토글
  HomeState toggleSavedPlaces() {
    return copyWith(showSavedPlaces: !showSavedPlaces);
  }

  /// Local/Global 모드 토글
  HomeState toggleLocalMode() {
    return copyWith(isLocalMode: !isLocalMode);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeState &&
        other.polygons == polygons &&
        other.markers == markers &&
        other.districtGrades == districtGrades &&
        other.firestorePlaces == firestorePlaces &&
        other.selectedCategories == selectedCategories &&
        other.showSavedPlaces == showSavedPlaces &&
        other.isLocalMode == isLocalMode &&
        other.isLoading == isLoading &&
        other.markerIconCache == markerIconCache &&
        other.markerIconsLoaded == markerIconsLoaded;
  }

  @override
  int get hashCode {
    return Object.hash(
      polygons,
      markers,
      districtGrades,
      firestorePlaces,
      selectedCategories,
      showSavedPlaces,
      isLocalMode,
      isLoading,
      markerIconCache,
      markerIconsLoaded,
    );
  }
}
