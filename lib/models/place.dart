import 'package:google_maps_flutter/google_maps_flutter.dart';

// 장소 정보 클래스
class Place {
  final String id;
  final String name;
  final String category;
  final String tag;
  final LatLng position;
  final String distance;
  final String address;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.tag,
    required this.position,
    required this.distance,
    required this.address,
  });
}
