import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceModel {
  final int id;
  final String name;
  final String category;
  final String tag;
  final String distance;
  final String? address;
  final String? district;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final double rating;
  final double? averageRating;
  final int reviewCount;
  final int? saveCount;
  final bool isSaved;
  final int? eloRating; // ELO 랭킹 점수

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.tag,
    required this.distance,
    this.address,
    this.district,
    required this.latitude,
    required this.longitude,
    this.imageUrls = const [],
    this.rating = 0.0,
    this.averageRating,
    this.reviewCount = 0,
    this.saveCount,
    this.isSaved = false,
    this.eloRating,
  });

  // 안전한 double 파싱
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // 카테고리 ID를 문자열로 변환
  static String _categoryIdToString(int? categoryId) {
    switch (categoryId) {
      case 1:
        return 'restaurant';
      case 2:
        return 'accommodation';
      case 3:
        return 'cafe';
      case 4:
        return 'attraction';
      default:
        return 'attraction';
    }
  }

  // 카테고리 ID를 한글 태그로 변환
  static String _categoryIdToTag(int? categoryId) {
    switch (categoryId) {
      case 1:
        return '음식점';
      case 2:
        return '숙박';
      case 3:
        return '카페';
      case 4:
        return '관광지';
      default:
        return '기타';
    }
  }

  // JSON에서 데이터 가져오기
  factory PlaceModel.fromJson(Map<String, dynamic> data) {
    // category가 객체인 경우와 숫자인 경우 모두 처리
    int? categoryId;
    String? categoryCode;
    String? categoryName;

    if (data['category'] is Map) {
      final categoryMap = data['category'] as Map<String, dynamic>;
      categoryId = categoryMap['id'];
      categoryCode = categoryMap['code'];
      categoryName = categoryMap['name'];
    } else if (data['category'] is int) {
      categoryId = data['category'];
    } else if (data['categoryId'] != null) {
      categoryId = data['categoryId'];
    }

    return PlaceModel(
      id: data['id'] is int ? data['id'] : int.tryParse(data['id']?.toString() ?? '0') ?? 0,
      name: data['name'] ?? '',
      category: categoryCode ?? (data['category'] is String ? data['category'] : _categoryIdToString(categoryId)),
      tag: categoryName ?? (data['tag'] ?? _categoryIdToTag(categoryId)),
      distance: data['distance']?.toString() ?? '0km',
      address: data['address'],
      district: data['district'],
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      imageUrls: data['imageUrls'] != null
          ? (data['imageUrls'] is List
              ? List<String>.from(data['imageUrls'])
              : (data['imageUrls'] is String ? [data['imageUrls']] : []))
          : [],
      rating: _parseDouble(data['rating'] ?? data['averageRating']),
      averageRating: data['averageRating'] != null ? _parseDouble(data['averageRating']) : null,
      reviewCount: data['reviewCount'] is int
          ? data['reviewCount']
          : (int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0),
      saveCount: data['saveCount'] != null
          ? (data['saveCount'] is int ? data['saveCount'] : int.tryParse(data['saveCount'].toString()))
          : (data['bookmarkCount'] != null
              ? (data['bookmarkCount'] is int ? data['bookmarkCount'] : int.tryParse(data['bookmarkCount'].toString()))
              : null),
      isSaved: data['isSaved'] ?? false,
      eloRating: data['eloRating'] is int
          ? data['eloRating']
          : (data['eloRating'] != null ? int.tryParse(data['eloRating'].toString()) : null),
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
    };
  }

  // LatLng 반환
  LatLng get location => LatLng(latitude, longitude);
}
