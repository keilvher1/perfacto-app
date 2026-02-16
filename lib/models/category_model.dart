import 'package:flutter/material.dart';

/// Beli 스타일 5대 카테고리
enum PlaceCategory {
  restaurant('restaurant', '음식점', '🍽️', Colors.orange),
  bar('bar', '바', '🍺', Colors.amber),
  bakery('bakery', '베이커리', '🥐', Colors.brown),
  coffeeTea('coffee_tea', '카페', '☕', Color(0xFF6F4E37)),
  dessert('dessert', '디저트', '🍦', Colors.pink);

  final String code;
  final String label;
  final String emoji;
  final Color color;

  const PlaceCategory(this.code, this.label, this.emoji, this.color);

  /// 카테고리 코드로 enum 찾기
  static PlaceCategory fromCode(String code) {
    return PlaceCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => PlaceCategory.restaurant,
    );
  }

  /// 카테고리 ID (기존 시스템)를 새 카테고리로 매핑
  static PlaceCategory fromLegacyId(int categoryId) {
    switch (categoryId) {
      case 1:
        return PlaceCategory.restaurant;
      case 2:
        return PlaceCategory.restaurant; // 숙박 → 음식점으로 임시 매핑
      case 3:
        return PlaceCategory.coffeeTea;
      case 4:
        return PlaceCategory.restaurant; // 관광지 → 음식점으로 임시 매핑
      default:
        return PlaceCategory.restaurant;
    }
  }

  /// 카테고리 이름으로 enum 찾기
  static PlaceCategory? fromName(String name) {
    try {
      return PlaceCategory.values.firstWhere(
        (c) => c.label == name || c.code == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// 전체 카테고리 목록
  static List<PlaceCategory> get all => PlaceCategory.values;

  /// 카테고리 ID로 변환 (백엔드 호환성)
  int toLegacyId() {
    switch (this) {
      case PlaceCategory.restaurant:
        return 1;
      case PlaceCategory.bar:
        return 1; // 바 → 음식점 ID로 임시 매핑
      case PlaceCategory.bakery:
        return 1; // 베이커리 → 음식점 ID로 임시 매핑
      case PlaceCategory.coffeeTea:
        return 3;
      case PlaceCategory.dessert:
        return 3; // 디저트 → 카페 ID로 임시 매핑
    }
  }

  /// 카테고리 설명
  String get description {
    switch (this) {
      case PlaceCategory.restaurant:
        return '한식, 중식, 일식, 양식, 분식 등 다양한 음식점';
      case PlaceCategory.bar:
        return '술집, 호프, 바 등 음주 공간';
      case PlaceCategory.bakery:
        return '빵집, 베이커리, 제과점';
      case PlaceCategory.coffeeTea:
        return '카페, 커피숍, 티하우스';
      case PlaceCategory.dessert:
        return '디저트, 아이스크림, 케이크';
    }
  }
}
