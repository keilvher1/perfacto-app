import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin, sin, pi;

/// 거리 계산 유틸리티
class DistanceCalculator {
  /// 두 좌표 간의 거리 계산 (Haversine formula)
  /// 반환값: km 단위
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// 거리를 문자열로 포맷팅
  /// 1km 미만: "XXXm"
  /// 1km 이상: "X.Xkm"
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      final meters = (distanceInKm * 1000).round();
      return '${meters}m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  /// 현재 위치 가져오기
  static Future<Position?> getCurrentLocation() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 현재 위치 가져오기
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// 현재 위치에서 장소까지의 거리 계산
  static Future<String> getDistanceFromCurrentLocation(
    double targetLat,
    double targetLon,
  ) async {
    try {
      final Position? position = await getCurrentLocation();

      if (position == null) {
        return '거리 정보 없음';
      }

      final double distance = calculateDistance(
        position.latitude,
        position.longitude,
        targetLat,
        targetLon,
      );

      return formatDistance(distance);
    } catch (e) {
      print('Error calculating distance: $e');
      return '거리 정보 없음';
    }
  }
}
