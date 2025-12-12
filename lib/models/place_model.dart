import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String tag;
  final String distance;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final double rating;
  final int reviewCount;
  final bool isSaved;

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.tag,
    required this.distance,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrls = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isSaved = false,
  });

  // Firestore에서 데이터 가져오기
  factory PlaceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaceModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      tag: data['tag'] ?? '',
      distance: data['distance'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isSaved: data['isSaved'] ?? false,
    );
  }

  // Firestore에 저장하기
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'tag': tag,
      'distance': distance,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'isSaved': isSaved,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // LatLng 반환
  LatLng get location => LatLng(latitude, longitude);
}
