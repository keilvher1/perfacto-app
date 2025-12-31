import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/place_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/saved_places_service.dart';
import '../services/places_cache_service.dart';
import 'login_page.dart';
import 'my_page.dart';
import 'review_write_new_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? mapController;
  static const LatLng _pohangCenter = LatLng(36.019, 129.343);
  static const Color _baseColor = Color(0xFF4E8AD9);
  static const int _baseGrade = 70;
  static const int _minGrade = 0;
  static const int _maxGrade = 100;

  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isLocalMode = true;
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

  @override
  void initState() {
    super.initState();
    _loadGeoJsonData();
    _loadPlacesFromBackend();
  }

  // 백엔드에서 장소 데이터 가져오기 (캐싱 사용)
  Future<void> _loadPlacesFromBackend() async {
    print('🔍 DEBUG - _loadPlacesFromBackend 시작');

    try {
      // 1. 캐시부터 확인하여 즉시 표시
      final cachedPlaces = await PlacesCacheService.getCachedPlaces();
      if (cachedPlaces != null && cachedPlaces.isNotEmpty) {
        print('⚡ 캐시된 데이터 먼저 표시: ${cachedPlaces.length}개 장소');
        if (mounted) {
          setState(() {
            _firestorePlaces = cachedPlaces;
            _isLoading = false;
          });
          _updateMarkers();
        }
      }

      // 2. 백그라운드에서 최신 데이터 가져오기
      print('🔄 백그라운드에서 최신 데이터 가져오는 중...');
      final List<PlaceModel> allPlaces = [];

      // 카테고리 ID: 1=음식점, 2=숙박, 3=카페, 4=관광지
      for (int categoryId = 1; categoryId <= 4; categoryId++) {
        print('🔍 DEBUG - 카테고리 $categoryId 로딩 시작');
        try {
          final places = await ApiService.getPlaces(categoryId: categoryId, size: 100);
          print('🔍 DEBUG - 카테고리 $categoryId: ${places.length}개 장소 로드됨');
          for (var placeData in places) {
            allPlaces.add(PlaceModel.fromJson(placeData));
          }
        } catch (e) {
          print('❌ DEBUG - 카테고리 $categoryId 로딩 실패: $e');
        }
      }

      print('🔍 DEBUG - 총 ${allPlaces.length}개 장소 데이터 수집 완료');

      // 3. 최신 데이터를 캐시에 저장
      if (allPlaces.isNotEmpty) {
        await PlacesCacheService.cachePlaces(allPlaces);
        print('💾 최신 데이터 캐시에 저장됨');
      }

      // 4. UI 업데이트
      if (mounted) {
        setState(() {
          _firestorePlaces = allPlaces;
          _isLoading = false;
        });
        _updateMarkers();
      }

      print('✅ DEBUG - 총 ${allPlaces.length}개의 장소 로드 완료');
    } catch (e) {
      print('❌ DEBUG - 장소 데이터 로딩 실패: $e');

      // 에러 발생 시 캐시라도 사용
      final cachedPlaces = await PlacesCacheService.getCachedPlaces();
      if (cachedPlaces != null && cachedPlaces.isNotEmpty && mounted) {
        print('⚠️ 에러 발생, 캐시 데이터 사용: ${cachedPlaces.length}개 장소');
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

  // 백엔드 장소를 마커로 추가
  void _addFirestoreMarkers() async {
    final Set<Marker> newMarkers = {};

    print('=== 마커 업데이트 시작 ===');
    print('전체 장소 수: ${_firestorePlaces.length}');
    print('선택된 카테고리: $_selectedCategories');

    for (var place in _firestorePlaces) {
      // 카테고리 필터링 (물고기 필터와 무관하게 적용)
      if (!_selectedCategories.contains(place.category)) {
        print('필터링됨: ${place.name} (${place.category})');
        continue; // 선택되지 않은 카테고리는 스킵
      }
      print('포함됨: ${place.name} (${place.category})');

      // 마커 아이콘 선택 로직
      BitmapDescriptor markerIcon;

      if (_showSavedPlaces && place.isSaved) {
        // colored_fish 활성화 & 저장된 장소: 주황색 물고기로 표시
        markerIcon = await _createFishMarker(isColored: true);
      } else {
        // 그 외의 경우: 카테고리 색상으로 표시 (파란색 마커)
        markerIcon = await _createCategoryMarker(place.category);
      }

      final marker = Marker(
        markerId: MarkerId(place.id.toString()),
        position: place.location,
        icon: markerIcon,
        onTap: () {
          _showFirestorePlaceBottomSheet(context, place);
        },
      );
      newMarkers.add(marker);
    }

    print('생성된 마커 수: ${newMarkers.length}');
    print('=== 마커 업데이트 완료 ===');

    setState(() {
      // 기존 Firestore 마커 제거하고 새로운 마커 추가
      _markers.removeWhere(
        (marker) =>
            _firestorePlaces.any((place) => place.id.toString() == marker.markerId.value),
      );
      _markers.addAll(newMarkers);
    });
  }

  // 마커 업데이트 메서드
  void _updateMarkers() {
    _addFirestoreMarkers();
  }

  // PlaceModel을 사용하는 바텀시트 표시
  void _showFirestorePlaceBottomSheet(BuildContext context, PlaceModel place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => _BottomSheetContentForFirestore(
        key: ValueKey(place.id),
        place: place,
      ),
    );
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
      final List<dynamic> features = geoJson['features'];
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
    final List<LatLng> points = [];
    for (var ring in coordinates[0]) {
      final double lng = ring[0].toDouble();
      final double lat = ring[1].toDouble();
      points.add(LatLng(lat, lng));
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
      final List<LatLng> points = [];
      for (var ring in polygon[0]) {
        final double lng = ring[0].toDouble();
        final double lat = ring[1].toDouble();
        points.add(LatLng(lat, lng));
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

  LatLng _calculatePolygonCenter(List<LatLng> points) {
    double totalLat = 0;
    double totalLng = 0;

    for (var point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(totalLat / points.length, totalLng / points.length);
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

  Future<BitmapDescriptor> _createTextMarker(String text, Color bgColor) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 텍스트 (% 기호 추가, 크기 증가 및 가시성 향상)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$text%',
        style: TextStyle(
          color: bgColor,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.white, offset: Offset(2, 2), blurRadius: 3),
            Shadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 3),
            Shadow(color: Colors.white, offset: Offset(2, -2), blurRadius: 3),
            Shadow(color: Colors.white, offset: Offset(-2, 2), blurRadius: 3),
            Shadow(color: Colors.white, offset: Offset(0, 0), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final size = Size(textPainter.width + 4, textPainter.height + 4);

    textPainter.paint(canvas, Offset(2, 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  void _addGradeMarker(String shortName, LatLng position, int grade) async {
    final color = _getColorFromGrade(grade);
    final icon = await _createTextMarker(grade.toString(), color);

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('grade_$shortName'),
          position: position,
          anchor: const Offset(0.5, 0.5),
          icon: icon,
        ),
      );
    });
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
                                  const Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: '어디로 떠나볼까요?',
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(
                                          color: Color(0xFF8D8D8D),
                                          fontSize: 19,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                            _buildCategoryChip('음식점', Icons.restaurant),
                            const SizedBox(width: 10),
                            _buildCategoryChip('카페', Icons.local_cafe),
                            const SizedBox(width: 10),
                            _buildCategoryChip('가볼만한 곳', Icons.place),
                            const SizedBox(width: 10),
                            _buildCategoryChip('숙박', Icons.hotel),
                            const SizedBox(width: 24), // 오른쪽 패딩
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

  // 카테고리 레이블을 ID로 변환
  String _getCategoryId(String label) {
    switch (label) {
      case '음식점':
        return 'restaurant';
      case '카페':
        return 'cafe';
      case '가볼만한 곳':
        return 'attraction';
      case '숙박':
        return 'accommodation';
      default:
        return label.toLowerCase();
    }
  }

  // 카테고리 필터 토글
  void _toggleCategoryFilter(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
        print('카테고리 제거: $categoryId');
      } else {
        _selectedCategories.add(categoryId);
        print('카테고리 추가: $categoryId');
      }
      print('선택된 카테고리: $_selectedCategories');
    });
    _updateMarkers();
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    final categoryId = _getCategoryId(label);
    final isSelected = _selectedCategories.contains(categoryId);

    return GestureDetector(
      onTap: () => _toggleCategoryFilter(categoryId),
      child: Container(
        height: 37,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4E8AD9).withOpacity(0.9)
              : const Color(0xFFF8F6F0).withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF1B1B1B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1B1B1B),
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLocalMode = label == 'Local';
        });
      },
      child: Container(
        width: 63,
        height: 30,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected
              ? (label == 'Local'
                    ? const Color(0xFF4E8AD9)
                    : const Color(0xFFCFCDC8))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (label == 'Local' ? Colors.white : const Color(0xFF8D8D8D))
                : const Color(0xFFCFCDC8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Bottom Sheet Widget Classes
// Firestore PlaceModel을 위한 바텀시트
class _BottomSheetContentForFirestore extends StatefulWidget {
  final PlaceModel place;

  const _BottomSheetContentForFirestore({super.key, required this.place});

  @override
  State<_BottomSheetContentForFirestore> createState() =>
      _BottomSheetContentForFirestoreState();
}

class _BottomSheetContentForFirestoreState
    extends State<_BottomSheetContentForFirestore>
    with SingleTickerProviderStateMixin {
  double _currentSize = 0.5;
  late TabController _tabController;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isAddressExpanded = false;
  late bool _isSaved; // Track local saved state

  @override
  void initState() {
    super.initState();
    _isSaved = widget.place.isSaved; // Initialize from place data
    _tabController = TabController(length: 3, vsync: this);
    _loadReviews();
  }

  // 리뷰 데이터를 한 번만 로드
  Future<void> _loadReviews() async {
    try {
      // TODO: 백엔드 API에서 리뷰 가져오기
      final reviews = <ReviewModel>[];
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Toggle save/bookmark state (로컬 저장 사용)
  Future<void> _toggleSave() async {
    try {
      // import 추가 필요: import '../services/saved_places_service.dart';
      if (_isSaved) {
        // Remove from saved places
        await SavedPlacesService.unsavePlace(widget.place.id);
      } else {
        // Add to saved places
        await SavedPlacesService.savePlace(widget.place.id);
      }

      // Update local state
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved ? '저장되었습니다.' : '저장이 취소되었습니다.',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF4E8AD9),
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG - _toggleSave error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          setState(() {
            _currentSize = notification.extent;
          });
          return true;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.2, 0.5, 0.95],
          snapAnimationDuration: const Duration(milliseconds: 200),
          builder: (context, scrollController) {
            final isMinimized = _currentSize < 0.21;

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F0),
                borderRadius: isMinimized
                    ? BorderRadius.zero
                    : const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
              ),
              child:
                  // isMinimized
                  //     ? Padding(
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 20,
                  //           vertical: 12,
                  //         ),
                  //         child: Column(
                  //           children: [
                  //             Row(
                  //               children: [
                  //                 Expanded(
                  //                   child: Text.rich(
                  //                     TextSpan(
                  //                       children: [
                  //                         TextSpan(
                  //                           text: widget.place.name,
                  //                           style: const TextStyle(
                  //                             color: Colors.black,
                  //                             fontSize: 16,
                  //                             fontWeight: FontWeight.w600,
                  //                           ),
                  //                         ),
                  //                         const TextSpan(text: '  '),
                  //                         TextSpan(
                  //                           text: widget.place.category,
                  //                           style: const TextStyle(
                  //                             color: Color(0xFF8D8D8D),
                  //                             fontSize: 14,
                  //                             fontWeight: FontWeight.w400,
                  //                           ),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                     overflow: TextOverflow.ellipsis,
                  //                     maxLines: 1,
                  //                   ),
                  //                 ),
                  //                 IconButton(
                  //                   icon: const Icon(Icons.close, size: 24),
                  //                   onPressed: () => Navigator.pop(context),
                  //                   padding: EdgeInsets.zero,
                  //                   constraints: const BoxConstraints(
                  //                     minWidth: 36,
                  //                     minHeight: 36,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             Container(
                  //               height: 70,
                  //               decoration: const BoxDecoration(
                  //                 color: Color(0xFFF8F6F0),
                  //               ),
                  //               padding: const EdgeInsets.symmetric(
                  //                 horizontal: 20,
                  //                 vertical: 10,
                  //               ),
                  //               child: Row(
                  //                 children: [
                  //                   // 공유 버튼 (아이콘만)
                  //                   Container(
                  //                     width: 50,
                  //                     height: 50,
                  //                     decoration: BoxDecoration(
                  //                       color: Colors.white,
                  //                       shape: BoxShape.circle,
                  //                       border: Border.all(
                  //                         color: const Color(0xFFCFCDC8),
                  //                         width: 1,
                  //                       ),
                  //                     ),
                  //                     child: IconButton(
                  //                       icon: const Icon(
                  //                         Icons.share_outlined,
                  //                         color: Color(0xFF414141),
                  //                         size: 24,
                  //                       ),
                  //                       onPressed: () async {
                  //                         final shareText =
                  //                             '${widget.place.name}\n${widget.place.address ?? ""}\n평점: ${widget.place.rating}';
                  //                         await Share.share(
                  //                           shareText,
                  //                           subject: widget.place.name,
                  //                         );
                  //                       },
                  //                     ),
                  //                   ),
                  //                   const SizedBox(width: 10),
                  //
                  //                   // 저장 버튼 (아이콘만)
                  //                   Container(
                  //                     width: 50,
                  //                     height: 50,
                  //                     decoration: BoxDecoration(
                  //                       color: Colors.white,
                  //                       shape: BoxShape.circle,
                  //                       border: Border.all(
                  //                         color: const Color(0xFFCFCDC8),
                  //                         width: 1,
                  //                       ),
                  //                     ),
                  //                     child: IconButton(
                  //                       icon: Icon(
                  //                         widget.place.isSaved
                  //                             ? Icons.bookmark
                  //                             : Icons.bookmark_border,
                  //                         color: const Color(0xFF414141),
                  //                         size: 24,
                  //                       ),
                  //                       onPressed: () async {
                  //                         final firestoreService =
                  //                             FirestoreService();
                  //                         final success = await firestoreService
                  //                             .updatePlace(widget.place.id, {
                  //                               'isSaved': !widget.place.isSaved,
                  //                             });
                  //
                  //                         if (success && mounted) {
                  //                           ScaffoldMessenger.of(
                  //                             context,
                  //                           ).showSnackBar(
                  //                             SnackBar(
                  //                               content: Text(
                  //                                 widget.place.isSaved
                  //                                     ? '저장이 취소되었습니다.'
                  //                                     : '저장되었습니다.',
                  //                               ),
                  //                               duration: const Duration(
                  //                                 seconds: 1,
                  //                               ),
                  //                             ),
                  //                           );
                  //                         }
                  //                       },
                  //                     ),
                  //                   ),
                  //                   const SizedBox(width: 12),
                  //
                  //                   // 리뷰작성 버튼 (확장)
                  //                   Expanded(
                  //                     child: GestureDetector(
                  //                       onTap: () async {
                  //                         // 로그인 여부 확인
                  //                         final user =
                  //                             FirebaseAuth.instance.currentUser;
                  //                         if (user == null) {
                  //                           // 로그인되지 않은 경우 로그인 페이지 표시
                  //                           final result = await Navigator.push(
                  //                             context,
                  //                             MaterialPageRoute(
                  //                               builder: (context) =>
                  //                                   const LoginPage(),
                  //                             ),
                  //                           );
                  //                           // 로그인 성공 시 리뷰 작성 페이지로 이동
                  //                           if (result == true && mounted) {
                  //                             Navigator.pop(context); // 바텀시트 닫기
                  //                             Navigator.push(
                  //                               context,
                  //                               MaterialPageRoute(
                  //                                 builder: (context) =>
                  //                                     ReviewWritePage(
                  //                                       placeName:
                  //                                           widget.place.name,
                  //                                       placeId: widget.place.id,
                  //                                     ),
                  //                               ),
                  //                             );
                  //                           }
                  //                         } else {
                  //                           // 이미 로그인된 경우 리뷰 작성 페이지로 이동
                  //                           Navigator.pop(context); // 바텀시트 닫기
                  //                           Navigator.push(
                  //                             context,
                  //                             MaterialPageRoute(
                  //                               builder: (context) =>
                  //                                   ReviewWritePage(
                  //                                     placeName: widget.place.name,
                  //                                     placeId: widget.place.id,
                  //                                   ),
                  //                             ),
                  //                           );
                  //                         }
                  //                       },
                  //                       child: Container(
                  //                         height: 50,
                  //                         decoration: BoxDecoration(
                  //                           color: const Color(0xFF4E8AD9),
                  //                           borderRadius: BorderRadius.circular(8),
                  //                         ),
                  //                         alignment: Alignment.center,
                  //                         child: const Text(
                  //                           '리뷰작성',
                  //                           style: TextStyle(
                  //                             color: Colors.white,
                  //                             fontSize: 16,
                  //                             fontWeight: FontWeight.w600,
                  //                           ),
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       )
                  //     :
                  SizedBox(
                    height: double.infinity,
                    child: Column(
                      children: [
                        // Drag handle (이 부분만 scrollController 사용)
                        SizedBox(
                          height: 30,
                          child: ListView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 20,
                                child: Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 14),
                                    width: 39,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCFCDC8),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Header (place name, tag, close button)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SingleChildScrollView(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            widget.place.name,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.place.category,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      if (!isMinimized)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 17,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4E8AD9),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            widget.place.tag,
                                            style: const TextStyle(
                                              color: Color(0xFFF8F6F0),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Distance and address with expand button
                        if (!isMinimized)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.place.distance,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.place.address ?? "",
                                        style: const TextStyle(
                                          color: Color(0xFF414141),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isAddressExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isAddressExpanded =
                                              !_isAddressExpanded;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                // 주소 상세 팝업
                                if (_isAddressExpanded)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: ShapeDecoration(
                                      color: const Color(0xFFF8F6F0),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                          width: 0.50,
                                          color: Color(0xFFCFCDC8),
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 37,
                                              height: 18,
                                              decoration: ShapeDecoration(
                                                color: const Color(
                                                  0xFFF8F6F0,
                                                ) /* White */,
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: const Color(
                                                      0xFFCFCDC8,
                                                    ) /* White_600 */,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                '도로명',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF8D8D8D,
                                                  ) /* Black_200 */,
                                                  fontSize: 12,
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              widget.place.address ?? "",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF414141),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: widget.place.address ?? "",
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '주소가 복사되었습니다',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.copy,
                                                size: 16,
                                              ),
                                              label: const Text('복사'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF4E8AD9,
                                                ),
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              width: 27,
                                              height: 18,
                                              decoration: ShapeDecoration(
                                                color: const Color(
                                                  0xFFF8F6F0,
                                                ) /* White */,
                                                shape: RoundedRectangleBorder(
                                                  side: BorderSide(
                                                    width: 1,
                                                    color: const Color(
                                                      0xFFCFCDC8,
                                                    ) /* White_600 */,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                '지번',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF8D8D8D,
                                                  ) /* Black_200 */,
                                                  fontSize: 12,
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              widget.place.address ?? "",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF414141),
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: widget.place.address ?? "",
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '주소가 복사되었습니다',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 1,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.copy,
                                                size: 16,
                                              ),
                                              label: const Text('복사'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF4E8AD9,
                                                ),
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        // 바텀시트가 크게 열렸을 때만 탭 표시
                        if (_currentSize > 0.7) ...[
                          // TabBar
                          TabBar(
                            controller: _tabController,
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.black,
                            labelStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                            indicatorColor: Colors.black,
                            indicatorWeight: 2,
                            tabs: const [
                              Tab(text: '홈'),
                              Tab(text: '리뷰'),
                              Tab(text: '사진'),
                            ],
                          ),

                          // TabBarView (독립적인 스크롤)
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // 홈 탭
                                SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: _buildHomeTabContent(),
                                ),

                                // 리뷰 탭
                                SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: _buildReviewTabContent(),
                                ),

                                // 사진 탭
                                SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: _buildPhotoTabContent(),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_currentSize > 0.15) ...[
                          // 탭 없이 기본 정보만 표시 (독립적인 스크롤)
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 리뷰 섹션
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_isLoading)
                                          const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF4E8AD9),
                                                  ),
                                            ),
                                          )
                                        else if (_reviews.isEmpty)
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 32,
                                                  ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.rate_review_outlined,
                                                    size: 48,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    '아직 리뷰가 없습니다',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: _reviews.length > 2
                                                ? 2
                                                : _reviews.length,
                                            itemBuilder: (context, index) {
                                              return _buildReviewCard(
                                                _reviews[index],
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // 사진 섹션
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_isLoading)
                                          const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF4E8AD9),
                                                  ),
                                            ),
                                          )
                                        else if (_reviews
                                            .expand((r) => r.imageUrls)
                                            .isEmpty)
                                          Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 32,
                                                  ),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .photo_library_outlined,
                                                    size: 48,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    '아직 사진이 없습니다',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            height: 100,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount:
                                                  _reviews
                                                          .expand(
                                                            (r) => r.imageUrls,
                                                          )
                                                          .length >
                                                      5
                                                  ? 5
                                                  : _reviews
                                                        .expand(
                                                          (r) => r.imageUrls,
                                                        )
                                                        .length,
                                              itemBuilder: (context, index) {
                                                final allImages = _reviews
                                                    .expand((r) => r.imageUrls)
                                                    .toList();
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8,
                                                      ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      allImages[index],
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ],
                        // 최소 크기일 때는 콘텐츠 숨김 (오버플로우 방지)
                        // if (_currentSize <= 0.15)
                        //   const SizedBox.shrink(),
                        // 하단 버튼 바
                        Container(
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F6F0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              // 공유 버튼
                              GestureDetector(
                                onTap: () async {
                                  final shareText =
                                      '${widget.place.name}\n${widget.place.address ?? ""}\n평점: ${widget.place.rating}';
                                  await Share.share(
                                    shareText,
                                    subject: widget.place.name,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(0xFFCFCDC8),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        'assets/icons/upload.png',
                                        width: 24,
                                        height: 24,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '공유',
                                        style: TextStyle(
                                          color: Color(0xFF414141),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 저장 버튼
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    // Check if user is logged in
                                    final isLoggedIn = await AuthService.isLoggedIn();
                                    if (!isLoggedIn) {
                                      // Show login page if not logged in
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginPage(),
                                        ),
                                      );
                                      // If login successful, try saving again
                                      if (result == true && mounted) {
                                        _toggleSave();
                                      }
                                      return;
                                    }

                                    // Toggle save state
                                    _toggleSave();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('오류가 발생했습니다: $e'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isSaved
                                        ? const Color(0xFF4E8AD9).withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: _isSaved
                                          ? const Color(0xFF4E8AD9)
                                          : const Color(0xFFCFCDC8),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        _isSaved
                                            ? 'assets/icons/colored_fish.png'
                                            : 'assets/icons/fish.png',
                                        width: 26,
                                        height: 26,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isSaved ? '저장됨' : '저장',
                                        style: TextStyle(
                                          color: _isSaved
                                              ? const Color(0xFF4E8AD9)
                                              : const Color(0xFF414141),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 리뷰작성 버튼 (확장)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    // 로그인 여부 확인
                                    final isLoggedIn = await AuthService.isLoggedIn();
                                    if (!isLoggedIn) {
                                      // 로그인되지 않은 경우 로그인 페이지 표시
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage(),
                                        ),
                                      );
                                      // 로그인 성공 시 리뷰 작성 페이지로 이동
                                      if (result == true && mounted) {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ReviewWriteNewPage(
                                              place: widget.place,
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      // 이미 로그인된 경우
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewWriteNewPage(
                                            place: widget.place,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 32,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4E8AD9),
                                      borderRadius: BorderRadius.circular(52),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '리뷰작성',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }

  // 홈 탭
  Widget _buildHomeTab(ScrollController scrollController) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '장소 정보',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '평점: ${widget.place.rating} (리뷰 ${widget.place.reviewCount}개)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF414141),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '위치: ${widget.place.address ?? ""}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF414141),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 리뷰 탭
  Widget _buildReviewTab(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 리뷰가 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  // 사진 탭
  Widget _buildPhotoTab(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
        ),
      );
    }

    final allImages = _reviews.expand((review) => review.imageUrls).toList();

    if (allImages.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '아직 사진이 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            allImages[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFFCFCDC8),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4E8AD9),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFCFCDC8),
                child: const Icon(Icons.broken_image, color: Color(0xFF8D8D8D)),
              );
            },
          ),
        );
      },
    );
  }

  // 리뷰 카드
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리뷰 헤더 (사용자명, 날짜)
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF4E8AD9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                  ],
                ),
              ),
              // Location verification badge removed
              if (false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E8AD9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '위치인증완료',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4E8AD9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 리뷰 이미지들
          if (review.imageUrls.isNotEmpty) ...[
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 165,
                    margin: EdgeInsets.only(
                      right: index < review.imageUrls.length - 1 ? 10 : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        review.imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFCFCDC8),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4E8AD9),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 리뷰 텍스트
          Text(
            review.comment ?? "",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1B1B1B),
              height: 1.58,
            ),
          ),

          const SizedBox(height: 12),

          // 도움돼요 버튼
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '도움돼요',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
  }

  // scrollController 없이 동작하는 탭 컨텐츠 메서드들
  Widget _buildHomeTabContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '장소 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '평점: ${widget.place.rating} (리뷰 ${widget.place.reviewCount}개)',
            style: const TextStyle(fontSize: 14, color: Color(0xFF414141)),
          ),
          const SizedBox(height: 8),
          Text(
            '위치: ${widget.place.address ?? ""}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF414141)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '아직 리뷰가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildPhotoTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
        ),
      );
    }

    final allImages = _reviews.expand((review) => review.imageUrls).toList();

    if (allImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '아직 사진이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            allImages[index],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: const Color(0xFFCFCDC8),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4E8AD9),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFCFCDC8),
                child: const Icon(Icons.broken_image, color: Color(0xFF8D8D8D)),
              );
            },
          ),
        );
      },
    );
  }
}
