# home_page.dart 리팩토링 가이드

**현재 상태**: 2,559줄의 단일 파일
**목표**: 유지보수 가능한 4-5개 파일로 분할

---

## 📁 권장 파일 구조

```
lib/pages/home/
├── home_page.dart (300줄)              # 메인 페이지
├── home_state.dart (150줄)             # 상태 관리
├── marker_helper.dart (400줄)          # 마커 생성 로직
├── widgets/
│   ├── place_bottom_sheet.dart (600줄) # 장소 상세 바텀시트
│   ├── category_filter.dart (200줄)    # 카테고리 필터 UI
│   ├── fish_toggle_button.dart (100줄) # 물고기 토글 버튼
│   └── map_controls.dart (150줄)       # 지도 컨트롤 버튼들
└── utils/
    └── polygon_utils.dart (200줄)      # 폴리곤 계산 유틸리티
```

---

## 🔀 분할 계획

### 1단계: 상태 관리 분리 (home_state.dart)

**추출할 코드**:
```dart
class HomeState {
  final Set<Polygon> polygons;
  final Set<Marker> markers;
  final Map<String, int> districtGrades;
  final Set<String> selectedCategories;
  final List<PlaceModel> firestorePlaces;
  final Map<String, BitmapDescriptor> markerIconCache;

  bool isLoading;
  bool showSavedPlaces;
  bool markerIconsLoaded;

  HomeState({...});

  HomeState copyWith({...}) => HomeState(...);
}
```

**현재 위치**: Lines 31-52

---

### 2단계: 마커 헬퍼 분리 (marker_helper.dart)

**추출할 함수들**:
- `_createFishMarker()` (Lines 350-432)
- `_createCategoryMarker()` (Lines 435-534)
- `_preloadMarkerIcons()` (Lines 69-87)
- `_addFirestoreMarkers()` (Lines 152-198)

**새 클래스 구조**:
```dart
class MarkerHelper {
  static Future<Map<String, BitmapDescriptor>> preloadMarkerIcons() async {
    final cache = <String, BitmapDescriptor>{};
    cache['fish_colored'] = await _createFishMarker(isColored: true);
    cache['fish_uncolored'] = await _createFishMarker(isColored: false);
    cache['restaurant'] = await _createCategoryMarker('restaurant');
    cache['cafe'] = await _createCategoryMarker('cafe');
    cache['attraction'] = await _createCategoryMarker('attraction');
    cache['accommodation'] = await _createCategoryMarker('accommodation');
    return cache;
  }

  static Future<BitmapDescriptor> _createFishMarker({required bool isColored}) async {...}
  static Future<BitmapDescriptor> _createCategoryMarker(String category) async {...}

  static Set<Marker> createMarkers({
    required List<PlaceModel> places,
    required Set<String> selectedCategories,
    required Map<String, BitmapDescriptor> iconCache,
    required bool showSavedPlaces,
    required Function(PlaceModel) onTap,
  }) {...}
}
```

---

### 3단계: 바텀시트 분리 (widgets/place_bottom_sheet.dart)

**추출할 클래스**:
- `_BottomSheetContentForFirestore` (Lines ~800-2100)

**새 파일 구조**:
```dart
class PlaceBottomSheet extends StatefulWidget {
  final PlaceModel place;

  const PlaceBottomSheet({required this.place});

  @override
  State<PlaceBottomSheet> createState() => _PlaceBottomSheetState();
}

class _PlaceBottomSheetState extends State<PlaceBottomSheet> {
  // 기존 _BottomSheetContentForFirestore 로직
}
```

**사용법**:
```dart
// home_page.dart에서
void _showFirestorePlaceBottomSheet(BuildContext context, PlaceModel place) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlaceBottomSheet(place: place),
  );
}
```

---

### 4단계: 카테고리 필터 위젯 분리 (widgets/category_filter.dart)

**추출할 코드**: Lines 900-1000 (카테고리 필터 UI)

**새 위젯 구조**:
```dart
class CategoryFilter extends StatelessWidget {
  final Set<String> selectedCategories;
  final Function(String) onCategoryToggle;

  const CategoryFilter({
    required this.selectedCategories,
    required this.onCategoryToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCategoryChip('restaurant', '음식점', Icons.restaurant),
        _buildCategoryChip('cafe', '카페', Icons.local_cafe),
        _buildCategoryChip('attraction', '관광', Icons.place),
        _buildCategoryChip('accommodation', '숙박', Icons.hotel),
      ],
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon) {...}
}
```

---

### 5단계: 폴리곤 유틸리티 분리 (utils/polygon_utils.dart)

**추출할 함수들**:
- `_calculatePolygonCenter()` (Lines 338-348)
- `_getColorFromGrade()` (Lines 184-231)

**새 클래스 구조**:
```dart
class PolygonUtils {
  static LatLng calculateCenter(List<LatLng> points) {...}

  static Color getColorFromGrade(int grade) {...}

  static Polygon createDistrictPolygon({
    required String districtName,
    required List<LatLng> points,
    required int grade,
  }) {...}
}
```

---

## 🔄 마이그레이션 순서

### Phase 1: 준비 (30분)
1. 새 디렉토리 생성
```bash
mkdir -p lib/pages/home/widgets
mkdir -p lib/pages/home/utils
```

2. Git 브랜치 생성
```bash
git checkout -b refactor/split-home-page
```

### Phase 2: 마커 헬퍼 분리 (1시간)
1. `marker_helper.dart` 생성
2. 마커 생성 함수들 이동
3. `home_page.dart`에서 import 및 사용

### Phase 3: 바텀시트 분리 (2시간)
1. `widgets/place_bottom_sheet.dart` 생성
2. 바텀시트 클래스 이동
3. 테스트

### Phase 4: 위젯 분리 (1시간)
1. `widgets/category_filter.dart` 생성
2. `widgets/fish_toggle_button.dart` 생성
3. `widgets/map_controls.dart` 생성

### Phase 5: 유틸리티 분리 (30분)
1. `utils/polygon_utils.dart` 생성
2. 폴리곤 관련 함수 이동

### Phase 6: 테스트 및 검증 (1시간)
1. 전체 앱 테스트
2. 빌드 확인
3. Git 커밋

**총 예상 시간**: 6시간

---

## ✅ 검증 체크리스트

- [ ] 앱이 정상적으로 빌드되는가?
- [ ] 지도가 정상적으로 표시되는가?
- [ ] 마커 클릭 시 바텀시트가 열리는가?
- [ ] 카테고리 필터가 작동하는가?
- [ ] 물고기 토글 버튼이 작동하는가?
- [ ] 저장된 장소 표시가 정상인가?
- [ ] 성능 저하가 없는가?

---

## 📊 예상 효과

| 항목 | Before | After | 개선 |
|------|--------|-------|------|
| home_page.dart 크기 | 2,559줄 | 300줄 | **88% 감소** |
| 파일 수 | 1개 | 9개 | 모듈화 |
| 유지보수성 | 낮음 | 높음 | **대폭 개선** |
| 테스트 가능성 | 어려움 | 쉬움 | **개선** |
| 재사용성 | 불가능 | 가능 | **새 기능** |

---

## 🎯 빠른 시작 (최소 버전)

시간이 부족하면 최소한 이것만:

1. **마커 헬퍼 분리** (1시간)
   - 가장 큰 성능 영향
   - 코드 재사용 가능

2. **바텀시트 분리** (2시간)
   - 가독성 대폭 향상
   - 600줄 감소

이 2개만 해도 **home_page.dart가 1,500줄**으로 줄어듭니다!

---

**작성일**: 2026-02-06
**작성자**: Claude Code
**우선순위**: Medium (Phase 3에서 진행 권장)
