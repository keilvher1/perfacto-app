/// 장소 태그 시스템
enum PlaceTag {
  // 분위기
  dateNight('date_night', '데이트', '💕'),
  business('business', '비즈니스', '💼'),
  casual('casual', '캐주얼', '👕'),
  cozy('cozy', '아늑한', '🛋️'),
  trendy('trendy', '트렌디', '✨'),

  // 상황
  brunch('brunch', '브런치', '🍳'),
  lateNight('late_night', '야식', '🌙'),
  solo('solo', '혼밥', '🙋'),
  group('group', '단체', '👥'),
  family('family', '가족', '👨‍👩‍👧'),

  // 특징
  view('view', '뷰맛집', '🏞️'),
  petFriendly('pet_friendly', '반려동물', '🐕'),
  parking('parking', '주차가능', '🅿️'),
  reservation('reservation', '예약필수', '📅'),
  waiting('waiting', '웨이팅', '⏰'),

  // 추가 태그
  clean('clean', '깔끔한', '✨'),
  friendly('friendly', '친절한', '😊'),
  quiet('quiet', '조용한', '🤫'),
  instagrammable('instagrammable', '인스타감성', '📸');

  final String code;
  final String label;
  final String emoji;

  const PlaceTag(this.code, this.label, this.emoji);

  /// 태그 코드로 enum 찾기
  static PlaceTag? fromCode(String code) {
    try {
      return PlaceTag.values.firstWhere(
        (t) => t.code == code || t.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 여러 태그 코드를 enum 리스트로 변환
  static List<PlaceTag> fromCodes(List<String> codes) {
    return codes
        .map((code) => fromCode(code))
        .where((tag) => tag != null)
        .cast<PlaceTag>()
        .toList();
  }

  /// enum 리스트를 코드 리스트로 변환
  static List<String> toCodes(List<PlaceTag> tags) {
    return tags.map((tag) => tag.code).toList();
  }

  /// 카테고리별 추천 태그
  static List<PlaceTag> getRecommendedTags(String categoryCode) {
    switch (categoryCode) {
      case 'restaurant':
        return [
          PlaceTag.dateNight,
          PlaceTag.business,
          PlaceTag.family,
          PlaceTag.group,
          PlaceTag.view,
          PlaceTag.parking,
          PlaceTag.reservation,
        ];
      case 'bar':
        return [
          PlaceTag.dateNight,
          PlaceTag.casual,
          PlaceTag.trendy,
          PlaceTag.lateNight,
          PlaceTag.group,
          PlaceTag.waiting,
        ];
      case 'bakery':
        return [
          PlaceTag.brunch,
          PlaceTag.casual,
          PlaceTag.cozy,
          PlaceTag.petFriendly,
          PlaceTag.instagrammable,
        ];
      case 'coffee_tea':
        return [
          PlaceTag.brunch,
          PlaceTag.dateNight,
          PlaceTag.solo,
          PlaceTag.cozy,
          PlaceTag.trendy,
          PlaceTag.quiet,
          PlaceTag.petFriendly,
          PlaceTag.instagrammable,
        ];
      case 'dessert':
        return [
          PlaceTag.dateNight,
          PlaceTag.casual,
          PlaceTag.trendy,
          PlaceTag.lateNight,
          PlaceTag.instagrammable,
        ];
      default:
        return [];
    }
  }

  /// 태그 그룹
  static List<PlaceTag> get atmosphereTags => [
        PlaceTag.dateNight,
        PlaceTag.business,
        PlaceTag.casual,
        PlaceTag.cozy,
        PlaceTag.trendy,
      ];

  static List<PlaceTag> get situationTags => [
        PlaceTag.brunch,
        PlaceTag.lateNight,
        PlaceTag.solo,
        PlaceTag.group,
        PlaceTag.family,
      ];

  static List<PlaceTag> get featureTags => [
        PlaceTag.view,
        PlaceTag.petFriendly,
        PlaceTag.parking,
        PlaceTag.reservation,
        PlaceTag.waiting,
        PlaceTag.clean,
        PlaceTag.friendly,
        PlaceTag.quiet,
        PlaceTag.instagrammable,
      ];

  /// 전체 태그 리스트
  static List<PlaceTag> get all => PlaceTag.values;
}
