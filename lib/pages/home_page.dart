import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';
import '../services/places_cache_service.dart';
import '../providers/firestore_provider.dart';
import '../widgets/place_bottom_sheet.dart';
import '../widgets/category_chip_widget.dart';
import '../utils/distance_calculator.dart';
import 'my_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  GoogleMapController? mapController;
  static const LatLng _pohangCenter = LatLng(36.019, 129.343);
  static const int _baseGrade = 70;
  static const int _maxGrade = 100;

  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  final Map<String, int> _districtGrades = {};
  bool _showSavedPlaces =
      false; // false: uncolored_fish (카테고리 마커), true: colored_fish (저장된 장소 마커)

  // 카테고리 필터
  final Set<String> _selectedCategories = {
    'restaurant',
    'cafe',
    'attraction',
    'accommodation',
  }; // 초기값: 모든 카테고리 선택

  // 백엔드 API 데이터
  List<PlaceModel> _firestorePlaces = [];

  // 🎯 마커 아이콘 캐시 (성능 최적화)
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  bool _markerIconsLoaded = false;

  // 바텀시트 중복 열림 방지
  bool _isBottomSheetOpen = false;

  // 검색 기능
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<PlaceModel> _filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    _preloadMarkerIcons(); // 마커 아이콘 미리 로드
    _loadGeoJsonData();
    _loadPlacesFromBackend();
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 마커 아이콘을 미리 생성하여 캐싱 (성능 최적화)
  /// Flutter Web에서는 Canvas 기반 커스텀 아이콘이 불안정하므로
  /// defaultMarkerWithHue를 기본으로 사용하고, 커스텀 아이콘은 폴백으로 시도
  Future<void> _preloadMarkerIcons() async {
    try {
      // Web 호환 기본 마커 아이콘 (항상 동작)
      _markerIconCache['fish_colored'] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      _markerIconCache['fish_uncolored'] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _markerIconCache['restaurant'] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _markerIconCache['cafe'] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      _markerIconCache['attraction'] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _markerIconCache['accommodation'] = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

      print('✅ Default marker icons loaded');

      // 커스텀 아이콘 시도 (성공하면 덮어쓰기)
      try {
        _markerIconCache['fish_colored'] = await _createFishMarker(isColored: true);
        _markerIconCache['fish_uncolored'] = await _createFishMarker(isColored: false);
        _markerIconCache['restaurant'] = await _createCategoryMarker('restaurant');
        _markerIconCache['cafe'] = await _createCategoryMarker('cafe');
        _markerIconCache['attraction'] = await _createCategoryMarker('attraction');
        _markerIconCache['accommodation'] = await _createCategoryMarker('accommodation');
        print('✅ Custom marker icons loaded');
      } catch (e) {
        print('⚠️ Custom marker icons failed, using defaults: $e');
      }

      setState(() {
        _markerIconsLoaded = true;
      });

      // 아이콘 로드 완료 후 마커가 이미 있으면 업데이트
      if (_firestorePlaces.isNotEmpty) {
        _updateMarkers();
      }
    } catch (e) {
      print('Error preloading marker icons: $e');
    }
  }

  // 백엔드에서 장소 데이터 가져오기 (Riverpod Provider + 캐싱)
  Future<void> _loadPlacesFromBackend() async {
    try {
      print('🔄 Loading places from Firestore (cache disabled for debugging)...');

      // 1. 캐시 비활성화 - 항상 Firestore에서 최신 데이터 가져오기
      // final cachedPlaces = await PlacesCacheService.getCachedPlaces();
      // if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
      //   if (mounted) {
      //     setState(() {
      //       _firestorePlaces = cachedPlaces;
      //       _isLoading = false;
      //     });
      //     _updateMarkers();
      //   }
      // }

      // 2. Riverpod Provider 캐시 무효화 및 최신 데이터 가져오기
      ref.invalidate(allPlacesProvider);  // Provider 캐시 무효화
      final allPlaces = await ref.read(allPlacesProvider.future);
      print('✅ Loaded ${allPlaces.length} places from Firestore');

      // 3. 거리 계산 및 업데이트
      final updatedPlaces = await _calculateDistancesForPlaces(allPlaces);

      // 4. 최신 데이터를 캐시에 저장
      if (updatedPlaces.isNotEmpty) {
        await PlacesCacheService.cachePlaces(updatedPlaces);
      }

      // 5. UI 업데이트
      if (mounted) {
        setState(() {
          _firestorePlaces = updatedPlaces;
          _isLoading = false;
        });
        _updateMarkers();
      }

    } catch (e) {
      print('Error loading places: $e');

      // 에러 발생 시 캐시라도 사용
      final cachedPlaces = await PlacesCacheService.getCachedPlaces();
      if (cachedPlaces != null && cachedPlaces.isNotEmpty && mounted) {
        setState(() {
          _firestorePlaces = cachedPlaces;
          _isLoading = false;
        });
        _updateMarkers();
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 장소 목록의 거리 계산
  Future<List<PlaceModel>> _calculateDistancesForPlaces(List<PlaceModel> places) async {
    try {
      // 현재 위치 가져오기
      final currentPosition = await DistanceCalculator.getCurrentLocation();

      if (currentPosition == null) {
        print('⚠️ 위치 권한이 없거나 위치 서비스가 비활성화되어 있습니다.');
        return places;
      }

      print('📍 현재 위치: ${currentPosition.latitude}, ${currentPosition.longitude}');

      // 각 장소의 거리 계산
      final updatedPlaces = places.map((place) {
        final distance = DistanceCalculator.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          place.latitude,
          place.longitude,
        );
        final formattedDistance = DistanceCalculator.formatDistance(distance);

        return place.copyWith(distance: formattedDistance);
      }).toList();

      print('✅ ${updatedPlaces.length}개 장소의 거리 계산 완료');
      return updatedPlaces;

    } catch (e) {
      print('❌ 거리 계산 중 오류 발생: $e');
      return places;
    }
  }

  // 백엔드 장소를 마커로 추가 (캐시된 아이콘 사용)
  void _addFirestoreMarkers() {
    // 마커 아이콘이 아직 로드되지 않았으면 기본 아이콘으로 진행
    if (!_markerIconsLoaded) {
      print('⏳ Marker icons not loaded yet, using default icons');
    }

    print('🎯 _addFirestoreMarkers called with ${_firestorePlaces.length} places');
    print('📋 Selected categories: $_selectedCategories');

    final Set<Marker> newMarkers = {};

    for (var place in _firestorePlaces) {
      print('📍 Processing place: ${place.name}, category: "${place.category}"');

      // 카테고리 필터링 (물고기 필터와 무관하게 적용)
      if (!_selectedCategories.contains(place.category)) {
        print('  ❌ Skipped - category not in selected: "${place.category}"');
        continue; // 선택되지 않은 카테고리는 스킵
      }

      print('  ✅ Adding marker for: ${place.name}');

      // 🎯 캐시된 마커 아이콘 사용 (성능 최적화, 폴백 포함)
      BitmapDescriptor markerIcon;

      if (_showSavedPlaces && place.isSaved) {
        markerIcon = _markerIconCache['fish_colored'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      } else {
        markerIcon = _markerIconCache[place.category] ??
            _markerIconCache['fish_uncolored'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }

      final marker = Marker(
        markerId: MarkerId(place.id),
        position: place.location,
        icon: markerIcon,
        onTap: () {
          _showFirestorePlaceBottomSheet(context, place);
        },
      );
      print('  🗺️  Marker created: ${place.name} at ${place.location}');
      newMarkers.add(marker);
    }

    print('📊 Total markers created: ${newMarkers.length}');
    print('📊 Current _markers before setState: ${_markers.length}');

    setState(() {
      // 기존 Firestore 마커 제거하고 새로운 마커 추가
      final removedCount = _markers.length;
      _markers.removeWhere(
        (marker) =>
            _firestorePlaces.any((place) => place.id == marker.markerId.value),
      );
      print('📊 Removed ${removedCount - _markers.length} old markers');
      _markers.addAll(newMarkers);
      print('📊 Total _markers after setState: ${_markers.length}');
    });
  }

  // 마커 업데이트 메서드
  void _updateMarkers() {
    _addFirestoreMarkers();
  }

  // 검색 기능
  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();

      if (_searchQuery.isEmpty) {
        _filteredPlaces = [];
        return;
      }

      // 장소명, 주소, 카테고리로 검색
      _filteredPlaces = _firestorePlaces.where((place) {
        final name = place.name.toLowerCase();
        final address = (place.address ?? '').toLowerCase();
        final category = place.tag.toLowerCase();

        return name.contains(_searchQuery) ||
               address.contains(_searchQuery) ||
               category.contains(_searchQuery);
      }).toList();
    });
  }

  // 카테고리별 아이콘 반환
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'attraction':
        return Icons.place;
      case 'accommodation':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  // PlaceModel을 사용하는 바텀시트 표시
  void _showFirestorePlaceBottomSheet(BuildContext context, PlaceModel place) {
    // 이미 바텀시트가 열려있으면 무시
    if (_isBottomSheetOpen) {
      print('⚠️ 바텀시트가 이미 열려있습니다. 중복 열기를 방지합니다.');
      return;
    }

    _isBottomSheetOpen = true;
    PlaceBottomSheet.show(context, place).then((_) {
      // 바텀시트가 닫히면 플래그 초기화
      if (mounted) {
        setState(() {
          _isBottomSheetOpen = false;
        });
      }
    });
  }

  Color _getColorFromGrade(int grade) {
    const int baseR = 78;
    const int baseG = 138;
    const int baseB = 217;

    double ratio;
    int r, g, b;

    if (grade <= 50) {
      r = (255 * 0.9 + baseR * 0.1).round().clamp(0, 255);
      g = (255 * 0.9 + baseG * 0.1).round().clamp(0, 255);
      b = (255 * 0.9 + baseB * 0.1).round().clamp(0, 255);
    } else if (grade <= _baseGrade) {
      ratio = (grade - 50) / (_baseGrade - 50);
      int lightR = (baseR + (255 - baseR) * 0.5).round();
      int lightG = (baseG + (255 - baseG) * 0.5).round();
      int lightB = (baseB + (255 - baseB) * 0.5).round();

      r = (lightR + (baseR - lightR) * ratio).round().clamp(0, 255);
      g = (lightG + (baseG - lightG) * ratio).round().clamp(0, 255);
      b = (lightB + (baseB - lightB) * ratio).round().clamp(0, 255);
    } else {
      ratio = (grade - _baseGrade) / (_maxGrade - _baseGrade);
      r = (baseR * (1 - ratio * 0.6)).round().clamp(0, 255);
      g = (baseG * (1 - ratio * 0.6)).round().clamp(0, 255);
      b = (baseB * (1 - ratio * 0.6)).round().clamp(0, 255);
    }

    return Color.fromARGB(255, r, g, b);
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/pohang_districts.json',
      );
      final Map<String, dynamic> geoJson = json.decode(jsonString);

      // features 배열 검증
      final List<dynamic>? features = geoJson['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) {
        debugPrint('⚠️ GeoJSON features is null or empty');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final random = Random();

      for (var feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];
        final String districtName = properties['adm_nm'] ?? 'Unknown';
        final String shortName = _extractShortName(districtName);

        if (!_districtGrades.containsKey(shortName)) {
          _districtGrades[shortName] = random.nextInt(101);
        }

        final int grade = _districtGrades[shortName]!;
        final Color color = _getColorFromGrade(grade);

        if (geometry['type'] == 'Polygon') {
          _addPolygonFromCoordinates(
            shortName,
            districtName,
            grade,
            geometry['coordinates'],
            color,
          );
        } else if (geometry['type'] == 'MultiPolygon') {
          _addMultiPolygonFromCoordinates(
            shortName,
            districtName,
            grade,
            geometry['coordinates'],
            color,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading GeoJSON: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _extractShortName(String fullName) {
    final parts = fullName.split(' ');
    return parts.isNotEmpty ? parts.last : fullName;
  }

  void _addPolygonFromCoordinates(
    String shortName,
    String fullName,
    int grade,
    List<dynamic> coordinates,
    Color color,
  ) {
    // coordinates 배열 검증
    if (coordinates.isEmpty || coordinates[0] == null) {
      debugPrint('⚠️ Invalid polygon coordinates for $shortName');
      return;
    }

    final List<LatLng> points = [];
    for (var ring in coordinates[0]) {
      if (ring == null || ring.length < 2) continue;
      try {
        final double lng = ring[0].toDouble();
        final double lat = ring[1].toDouble();
        points.add(LatLng(lat, lng));
      } catch (e) {
        debugPrint('⚠️ Invalid coordinate format: $e');
        continue;
      }
    }

    // 유효한 점이 3개 이상일 때만 폴리곤 생성
    if (points.length < 3) {
      debugPrint('⚠️ Not enough valid points for polygon $shortName');
      return;
    }

    _polygons.add(
      Polygon(
        polygonId: PolygonId('${shortName}_${_polygons.length}'),
        points: points,
        fillColor: color.withOpacity(0.6),
        strokeColor: color.withOpacity(0.8),
        strokeWidth: 2,
      ),
    );

    // 폴리곤 중심점 계산하여 등급 표시 (주석처리)
    // final center = _calculatePolygonCenter(points);
    // _addGradeMarker(shortName, center, grade);
  }

  void _addMultiPolygonFromCoordinates(
    String shortName,
    String fullName,
    int grade,
    List<dynamic> coordinates,
    Color color,
  ) {
    List<LatLng> allPoints = [];

    for (var polygon in coordinates) {
      // polygon 배열 검증
      if (polygon == null || polygon.isEmpty || polygon[0] == null) {
        debugPrint('⚠️ Invalid multipolygon coordinates for $shortName');
        continue;
      }

      final List<LatLng> points = [];
      for (var ring in polygon[0]) {
        if (ring == null || ring.length < 2) continue;
        try {
          final double lng = ring[0].toDouble();
          final double lat = ring[1].toDouble();
          points.add(LatLng(lat, lng));
        } catch (e) {
          debugPrint('⚠️ Invalid coordinate format: $e');
          continue;
        }
      }

      allPoints.addAll(points);

      _polygons.add(
        Polygon(
          polygonId: PolygonId('${shortName}_${_polygons.length}'),
          points: points,
          fillColor: color.withOpacity(0.6),
          strokeColor: color.withOpacity(0.8),
          strokeWidth: 2,
        ),
      );
    }

    // MultiPolygon의 전체 중심점 계산하여 등급 표시 (주석처리)
    // if (allPoints.isNotEmpty) {
    //   final center = _calculatePolygonCenter(allPoints);
    //   _addGradeMarker(shortName, center, grade);
    // }
  }

  Future<BitmapDescriptor> _createFishMarker({bool isColored = false}) async {
    const double markerSize = 60;
    const double circleSize = 40;
    const double reelSize = 20; // 정사각형으로 변경

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. reel 이미지 로드 및 그리기
    final reelData = await rootBundle.load('assets/icons/reel.png');
    final reelBytes = reelData.buffer.asUint8List();
    final reelImage = await decodeImageFromList(reelBytes);

    // reel 이미지를 마커 하단에 그리기 (원본 비율 유지)
    canvas.drawImageRect(
      reelImage,
      Rect.fromLTWH(
        0,
        0,
        reelImage.width.toDouble(),
        reelImage.height.toDouble(),
      ),
      Rect.fromLTWH(
        markerSize / 2 - reelSize / 2,
        circleSize - 8, // 8픽셀 위로 올림
        reelSize,
        reelSize,
      ),
      Paint(),
    );

    // 2. 원 배경 그리기 (isColored에 따라 주황색 또는 파란색)
    final circlePaint = Paint()
      ..color = isColored ? const Color(0xFFD96941) : const Color(0xFF4E8AD9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(markerSize / 2, circleSize / 2),
      circleSize / 2,
      circlePaint,
    );

    // 3. 물고기 아이콘 그리기 (간단한 물고기 모양)
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 물고기 몸통 (타원형)
    final fishBodyRect = Rect.fromCenter(
      center: Offset(markerSize / 2, circleSize / 2),
      width: 15,
      height: 9,
    );
    canvas.drawOval(fishBodyRect, iconPaint);

    // 물고기 꼬리 (삼각형)
    final tailPath = Path()
      ..moveTo(markerSize / 2 - 7.5, circleSize / 2)
      ..lineTo(markerSize / 2 - 12.5, circleSize / 2 - 4)
      ..lineTo(markerSize / 2 - 12.5, circleSize / 2 + 4)
      ..close();
    canvas.drawPath(tailPath, iconPaint);

    // 물고기 눈
    final eyePaint = Paint()
      ..color = isColored ? const Color(0xFFD96941) : const Color(0xFF4E8AD9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(markerSize / 2 + 2.5, circleSize / 2 - 1),
      1.5,
      eyePaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      markerSize.toInt(),
      (circleSize - 8 + reelSize).toInt(), // reel 위치 + 크기
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // 카테고리별 마커 아이콘 생성
  Future<BitmapDescriptor> _createCategoryMarker(String category) async {
    const double markerSize = 60;
    const double circleSize = 40;
    const double reelSize = 20; // 정사각형으로 변경

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. reel 이미지 로드 및 그리기
    final reelData = await rootBundle.load('assets/icons/reel.png');
    final reelBytes = reelData.buffer.asUint8List();
    final reelImage = await decodeImageFromList(reelBytes);

    // reel 이미지를 마커 하단에 그리기 (원본 비율 유지)
    canvas.drawImageRect(
      reelImage,
      Rect.fromLTWH(
        0,
        0,
        reelImage.width.toDouble(),
        reelImage.height.toDouble(),
      ),
      Rect.fromLTWH(
        markerSize / 2 - reelSize / 2,
        circleSize - 8, // 8픽셀 위로 올림
        reelSize,
        reelSize,
      ),
      Paint(),
    );

    // 2. 파란색 원 배경 그리기
    final circlePaint = Paint()
      ..color = const Color(0xFF4E8AD9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(markerSize / 2, circleSize / 2),
      circleSize / 2,
      circlePaint,
    );

    // 3. 카테고리별 Material Icon 그리기
    IconData iconData;
    switch (category.toLowerCase()) {
      case 'restaurant':
      case '음식점':
        iconData = Icons.restaurant;
        break;
      case 'accommodation':
      case '숙박':
      case '숙박업소':
        iconData = Icons.hotel;
        break;
      case 'cafe':
      case '카페':
        iconData = Icons.local_cafe;
        break;
      case 'attraction':
      case '관광':
      case '가볼만한곳':
        iconData = Icons.flag;
        break;
      default:
        iconData = Icons.place;
    }

    // Material Icon을 텍스트로 그리기
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: iconData.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // 아이콘을 원 중앙에 그리기
    canvas.save();
    canvas.translate(
      markerSize / 2 - textPainter.width / 2,
      circleSize / 2 - textPainter.height / 2,
    );
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      markerSize.toInt(),
      (circleSize - 8 + reelSize).toInt(), // reel 위치 + 크기
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }


  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // 지도 전체 화면
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: const CameraPosition(
                        target: _pohangCenter,
                        zoom: 11,
                      ),
                      polygons: _polygons,
                      markers: _markers,
                      mapType: MapType.normal,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),

                    // 검색바 영역
                    Positioned(
                      top: 24,
                      left: 24,
                      right: 24,
                      child: Row(
                        children: [
                          // 검색바
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF8F6F0,
                                ).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.menu,
                                    color: Colors.grey[600],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: _performSearch,
                                      decoration: InputDecoration(
                                        hintText: '어디로 떠나볼까요?',
                                        border: InputBorder.none,
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF8D8D8D),
                                          fontSize: 19,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  _performSearch('');
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 프로필 이미지 (MyPage로 이동)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4E8AD9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/icons/fisher.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 카테고리 버튼
                    Positioned(
                      top: 100, // 24 + 52 + 24
                      left: 24,
                      right: 0,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            CategoryChipWidget(
                              label: '음식점',
                              icon: Icons.restaurant,
                              isSelected: _selectedCategories.contains('restaurant'),
                              onTap: () => _toggleCategoryFilter('restaurant'),
                            ),
                            const SizedBox(width: 10),
                            CategoryChipWidget(
                              label: '카페',
                              icon: Icons.local_cafe,
                              isSelected: _selectedCategories.contains('cafe'),
                              onTap: () => _toggleCategoryFilter('cafe'),
                            ),
                            const SizedBox(width: 10),
                            CategoryChipWidget(
                              label: '가볼만한 곳',
                              icon: Icons.place,
                              isSelected: _selectedCategories.contains('attraction'),
                              onTap: () => _toggleCategoryFilter('attraction'),
                            ),
                            const SizedBox(width: 10),
                            CategoryChipWidget(
                              label: '숙박',
                              icon: Icons.hotel,
                              isSelected: _selectedCategories.contains('accommodation'),
                              onTap: () => _toggleCategoryFilter('accommodation'),
                            ),
                            const SizedBox(width: 24), // 오른쪽 패딩
                          ],
                        ),
                      ),
                    ),

                    // 검색 결과 리스트
                    if (_filteredPlaces.isNotEmpty)
                      Positioned(
                        top: 170,
                        left: 24,
                        right: 24,
                        bottom: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F6F0),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  '검색 결과 ${_filteredPlaces.length}개',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _filteredPlaces.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final place = _filteredPlaces[index];
                                    return ListTile(
                                      leading: Icon(
                                        _getCategoryIcon(place.category),
                                        color: const Color(0xFF4E8AD9),
                                      ),
                                      title: Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${place.tag} · ${place.address ?? ""}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        // 검색 결과 클릭 시 지도 중심 이동 및 바텀시트 표시
                                        mapController?.animateCamera(
                                          CameraUpdate.newLatLngZoom(place.location, 15),
                                        );
                                        _showFirestorePlaceBottomSheet(context, place);
                                        // 검색 초기화
                                        _searchController.clear();
                                        _performSearch('');
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 좌측 하단 리뷰 청결도 카드 (주석처리)
                    /* Positioned(
                      left: 24,
                      bottom: 16,
                      child: Container(
                        width: 51,
                        height: 108,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F0),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Text(
                              '리뷰\n청결도',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF4E8AD9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '99',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '%',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 5.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4E8AD9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '포항',
                                style: TextStyle(
                                  color: Color(0xFFF8F6F0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ), */

                    // 우측 상단 필터 버튼 (colored_fish/uncolored_fish 토글)
                    Positioned(
                      right: 24,
                      top: 150,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSavedPlaces = !_showSavedPlaces;
                            _updateMarkers(); // 마커 업데이트
                          });
                        },
                        child: Container(
                          width: 49,
                          height: 49,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F6F0),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              _showSavedPlaces
                                  ? 'assets/icons/colored_fish.png'
                                  : 'assets/icons/uncolored_fish.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 우측 하단 메인 플로팅 버튼 (현재 위치로 이동)
                    Positioned(
                      right: 24,
                      bottom: 16,
                      child: Container(
                        width: 49,
                        height: 49,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F0),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.my_location_outlined,
                            color: Color(0xFF4E8AD9),
                            size: 28,
                          ),
                          onPressed: () {
                            // 현재 위치로 이동 (포항 중심으로 이동)
                            mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                const CameraPosition(
                                  target: _pohangCenter,
                                  zoom: 12.0,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // 카테고리 필터 토글
  void _toggleCategoryFilter(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
    _updateMarkers();
  }
}
