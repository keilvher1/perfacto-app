// 리뷰 전체 평가 (신호등 방식)
enum ReviewRating {
  good, // 좋았음
  neutral, // 보통
  bad // 별로임
}

// 리뷰 이유 선택지
enum ReviewReason {
  // 긍정적
  foodDelicious,
  interiorNice,
  musicGood,
  serviceExcellent,
  atmosphereGood,
  valueForMoney,
  wantToRevisit,
  // 중립적
  averageQuality,
  fairPrice,
  nothingSpecial,
  // 부정적
  hygienePoor,
  parkingLimited,
  interiorUnappealing,
  serviceUnfriendly,
  tooExpensive,
  longWaitTime,
  tooNoisy
}

// 카테고리 비교 결과
enum ComparisonResult {
  better, // 이곳이 더 좋았음
  similar, // 비슷했음
  worse // 저곳이 더 좋았음
}

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final String placeId;
  final String placeName;

  // 3단계 리뷰 시스템
  final ReviewRating overallRating; // 1단계: 전체 평가
  final List<ReviewReason> reasons; // 2단계: 이유 선택
  final String? comparedPlaceId; // 3단계: 비교 장소 ID
  final String? comparedPlaceName; // 비교 장소 이름
  final ComparisonResult? comparison; // 비교 결과

  final int likeCount;
  final bool isLikedByMe;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.placeId,
    required this.placeName,
    required this.overallRating,
    required this.reasons,
    this.comparedPlaceId,
    this.comparedPlaceName,
    this.comparison,
    required this.likeCount,
    required this.isLikedByMe,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      userName: json['userName'] ?? 'Unknown',
      userProfileImage: json['userProfileImage'],
      placeId: json['placeId'].toString(),
      placeName: json['placeName'] ?? '',
      overallRating: _parseRating(json['overallRating']),
      reasons: (json['reasons'] as List<dynamic>?)
              ?.map((r) => _parseReason(r.toString()))
              .where((r) => r != null)
              .cast<ReviewReason>()
              .toList() ??
          [],
      comparedPlaceId: json['comparedPlaceId']?.toString(),
      comparedPlaceName: json['comparedPlaceName'],
      comparison: json['comparison'] != null
          ? _parseComparison(json['comparison'])
          : null,
      likeCount: json['likeCount'] ?? 0,
      isLikedByMe: json['isLikedByMe'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static ReviewRating _parseRating(String? rating) {
    switch (rating?.toUpperCase()) {
      case 'GOOD':
        return ReviewRating.good;
      case 'BAD':
        return ReviewRating.bad;
      default:
        return ReviewRating.neutral;
    }
  }

  static ReviewReason? _parseReason(String reason) {
    final map = {
      'FOOD_DELICIOUS': ReviewReason.foodDelicious,
      'INTERIOR_NICE': ReviewReason.interiorNice,
      'MUSIC_GOOD': ReviewReason.musicGood,
      'SERVICE_EXCELLENT': ReviewReason.serviceExcellent,
      'ATMOSPHERE_GOOD': ReviewReason.atmosphereGood,
      'VALUE_FOR_MONEY': ReviewReason.valueForMoney,
      'WANT_TO_REVISIT': ReviewReason.wantToRevisit,
      'AVERAGE_QUALITY': ReviewReason.averageQuality,
      'FAIR_PRICE': ReviewReason.fairPrice,
      'NOTHING_SPECIAL': ReviewReason.nothingSpecial,
      'HYGIENE_POOR': ReviewReason.hygienePoor,
      'PARKING_LIMITED': ReviewReason.parkingLimited,
      'INTERIOR_UNAPPEALING': ReviewReason.interiorUnappealing,
      'SERVICE_UNFRIENDLY': ReviewReason.serviceUnfriendly,
      'TOO_EXPENSIVE': ReviewReason.tooExpensive,
      'LONG_WAIT_TIME': ReviewReason.longWaitTime,
      'TOO_NOISY': ReviewReason.tooNoisy,
    };
    return map[reason];
  }

  static ComparisonResult? _parseComparison(String comparison) {
    switch (comparison.toUpperCase()) {
      case 'BETTER':
        return ComparisonResult.better;
      case 'WORSE':
        return ComparisonResult.worse;
      default:
        return ComparisonResult.similar;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'overallRating': overallRating.name.toUpperCase(),
      'reasons': reasons.map((r) => _reasonToString(r)).toList(),
      'comparedPlaceId': comparedPlaceId,
      'comparison': comparison?.name.toUpperCase(),
    };
  }

  static String _reasonToString(ReviewReason reason) {
    final map = {
      ReviewReason.foodDelicious: 'FOOD_DELICIOUS',
      ReviewReason.interiorNice: 'INTERIOR_NICE',
      ReviewReason.musicGood: 'MUSIC_GOOD',
      ReviewReason.serviceExcellent: 'SERVICE_EXCELLENT',
      ReviewReason.atmosphereGood: 'ATMOSPHERE_GOOD',
      ReviewReason.valueForMoney: 'VALUE_FOR_MONEY',
      ReviewReason.wantToRevisit: 'WANT_TO_REVISIT',
      ReviewReason.averageQuality: 'AVERAGE_QUALITY',
      ReviewReason.fairPrice: 'FAIR_PRICE',
      ReviewReason.nothingSpecial: 'NOTHING_SPECIAL',
      ReviewReason.hygienePoor: 'HYGIENE_POOR',
      ReviewReason.parkingLimited: 'PARKING_LIMITED',
      ReviewReason.interiorUnappealing: 'INTERIOR_UNAPPEALING',
      ReviewReason.serviceUnfriendly: 'SERVICE_UNFRIENDLY',
      ReviewReason.tooExpensive: 'TOO_EXPENSIVE',
      ReviewReason.longWaitTime: 'LONG_WAIT_TIME',
      ReviewReason.tooNoisy: 'TOO_NOISY',
    };
    return map[reason] ?? '';
  }

  // 평점을 숫자로 변환 (평균 계산용)
  double get numericRating {
    switch (overallRating) {
      case ReviewRating.good:
        return 5.0;
      case ReviewRating.neutral:
        return 3.0;
      case ReviewRating.bad:
        return 1.0;
    }
  }

  // 이유의 한글 표시
  static String getReasonText(ReviewReason reason) {
    final map = {
      ReviewReason.foodDelicious: '음식이 맛있음',
      ReviewReason.interiorNice: '인테리어가 예쁨',
      ReviewReason.musicGood: '나오는 노래가 좋음',
      ReviewReason.serviceExcellent: '서비스가 좋음',
      ReviewReason.atmosphereGood: '분위기가 좋음',
      ReviewReason.valueForMoney: '가성비가 좋음',
      ReviewReason.wantToRevisit: '재방문 의사 있음',
      ReviewReason.averageQuality: '무난함',
      ReviewReason.fairPrice: '가격 대비 괜찮음',
      ReviewReason.nothingSpecial: '특별한 점 없음',
      ReviewReason.hygienePoor: '위생이 더러움',
      ReviewReason.parkingLimited: '주차공간이 협소함',
      ReviewReason.interiorUnappealing: '인테리어 디자인이 마음에 들지 않음',
      ReviewReason.serviceUnfriendly: '서비스가 불친절함',
      ReviewReason.tooExpensive: '가격이 비쌈',
      ReviewReason.longWaitTime: '대기 시간이 김',
      ReviewReason.tooNoisy: '시끄러움',
    };
    return map[reason] ?? '';
  }
}
