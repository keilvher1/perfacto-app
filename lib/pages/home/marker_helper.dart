import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:perfacto/models/place_model.dart';

/// 마커 생성 및 관리 헬퍼 클래스
///
/// 마커 아이콘 생성, 캐싱, 마커 세트 생성 등의 로직을 담당
class MarkerHelper {
  /// 마커 아이콘을 미리 생성하여 캐싱
  ///
  /// 앱 시작 시 한 번만 호출하여 모든 마커 아이콘을 미리 생성
  static Future<Map<String, BitmapDescriptor>> preloadMarkerIcons() async {
    final cache = <String, BitmapDescriptor>{};

    try {
      // 물고기 마커 (colored/uncolored)
      cache['fish_colored'] = await _createFishMarker(isColored: true);
      cache['fish_uncolored'] = await _createFishMarker(isColored: false);

      // 카테고리별 마커
      cache['restaurant'] = await _createCategoryMarker('restaurant');
      cache['cafe'] = await _createCategoryMarker('cafe');
      cache['attraction'] = await _createCategoryMarker('attraction');
      cache['accommodation'] = await _createCategoryMarker('accommodation');

      return cache;
    } catch (e) {
      print('Error preloading marker icons: $e');
      rethrow;
    }
  }

  /// Firestore 장소 데이터에서 마커 세트 생성
  ///
  /// [places]: 표시할 장소 목록
  /// [selectedCategories]: 선택된 카테고리 필터
  /// [iconCache]: 사전 로드된 마커 아이콘 캐시
  /// [showSavedPlaces]: 저장된 장소 표시 여부
  /// [onTap]: 마커 탭 이벤트 핸들러
  static Set<Marker> createMarkers({
    required List<PlaceModel> places,
    required Set<String> selectedCategories,
    required Map<String, BitmapDescriptor> iconCache,
    required bool showSavedPlaces,
    required void Function(PlaceModel) onTap,
  }) {
    final Set<Marker> markers = {};

    for (var place in places) {
      // 카테고리 필터링
      if (!selectedCategories.contains(place.category)) {
        continue;
      }

      // 캐시된 마커 아이콘 사용
      BitmapDescriptor markerIcon;

      if (showSavedPlaces && place.isSaved) {
        // colored_fish 활성화 & 저장된 장소: 주황색 물고기로 표시
        markerIcon = iconCache['fish_colored']!;
      } else {
        // 그 외의 경우: 카테고리 색상으로 표시 (파란색 마커)
        markerIcon = iconCache[place.category] ?? iconCache['fish_uncolored']!;
      }

      final marker = Marker(
        markerId: MarkerId(place.id),
        position: place.location,
        icon: markerIcon,
        onTap: () => onTap(place),
      );
      markers.add(marker);
    }

    return markers;
  }

  /// 물고기 마커 아이콘 생성
  ///
  /// [isColored]: true면 주황색 (저장된 장소), false면 파란색 (일반 장소)
  static Future<BitmapDescriptor> _createFishMarker({
    bool isColored = false,
  }) async {
    const double markerSize = 60;
    const double circleSize = 40;
    const double reelSize = 20;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. reel 이미지 로드 및 그리기
    final reelData = await rootBundle.load('assets/icons/reel.png');
    final reelBytes = reelData.buffer.asUint8List();
    final reelImage = await decodeImageFromList(reelBytes);

    // reel 이미지를 마커 하단에 그리기
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
        circleSize - 8,
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

    // 3. 물고기 아이콘 그리기
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
      (circleSize - 8 + reelSize).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// 카테고리별 마커 아이콘 생성
  ///
  /// [category]: 카테고리 이름 (restaurant, cafe, attraction, accommodation)
  static Future<BitmapDescriptor> _createCategoryMarker(
    String category,
  ) async {
    const double markerSize = 60;
    const double circleSize = 40;
    const double reelSize = 20;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. reel 이미지 로드 및 그리기
    final reelData = await rootBundle.load('assets/icons/reel.png');
    final reelBytes = reelData.buffer.asUint8List();
    final reelImage = await decodeImageFromList(reelBytes);

    // reel 이미지를 마커 하단에 그리기
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
        circleSize - 8,
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
      (circleSize - 8 + reelSize).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// 텍스트 마커 아이콘 생성 (등급 표시용)
  ///
  /// [text]: 표시할 텍스트 (등급)
  /// [bgColor]: 배경 색상
  static Future<BitmapDescriptor> createTextMarker(
    String text,
    Color bgColor,
  ) async {
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
}
