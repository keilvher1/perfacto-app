import 'package:flutter/material.dart';

/// Match Score (취향 궁합) 모델
class MatchScore {
  final int userId;
  final int targetUserId;
  final double score; // 0-100
  final int commonPlacesCount; // 공통 방문 장소 수
  final String compatibility; // 'VERY_SIMILAR', 'SIMILAR', 'NEUTRAL', 'DIFFERENT'
  final DateTime calculatedAt;

  MatchScore({
    required this.userId,
    required this.targetUserId,
    required this.score,
    required this.commonPlacesCount,
    required this.compatibility,
    required this.calculatedAt,
  });

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      targetUserId: json['targetUserId'] is int
          ? json['targetUserId']
          : int.tryParse(json['targetUserId']?.toString() ?? '0') ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      commonPlacesCount: json['commonPlacesCount'] is int
          ? json['commonPlacesCount']
          : int.tryParse(json['commonPlacesCount']?.toString() ?? '0') ?? 0,
      compatibility: json['compatibility'] ?? 'NEUTRAL',
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'targetUserId': targetUserId,
      'score': score,
      'commonPlacesCount': commonPlacesCount,
      'compatibility': compatibility,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// 궁합 텍스트
  String get compatibilityText {
    switch (compatibility) {
      case 'VERY_SIMILAR':
        return '취향이 매우 비슷해요!';
      case 'SIMILAR':
        return '비슷한 취향을 가지고 있어요';
      case 'NEUTRAL':
        return '보통이에요';
      case 'DIFFERENT':
        return '다른 취향을 가지고 있어요';
      default:
        return '';
    }
  }

  /// 점수에 따른 색상
  Color get scoreColor {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.grey;
  }

  /// 점수에 따른 이모지
  String get emoji {
    if (score >= 80) return '💚';
    if (score >= 60) return '💛';
    if (score >= 40) return '🧡';
    return '🤍';
  }

  /// 점수 표시 텍스트
  String get scoreText => '${score.toStringAsFixed(0)}%';
}

/// Match Score 계산 유틸리티
class MatchScoreCalculator {
  /// Match Score 계산 (프론트엔드 시뮬레이션)
  ///
  /// 실제로는 백엔드에서 계산하지만, 프론트엔드에서 테스트/시뮬레이션 용도
  static double calculate({
    required List<Map<String, dynamic>> userAReviews,
    required List<Map<String, dynamic>> userBReviews,
  }) {
    // 공통 방문 장소 찾기
    final userAPlaceIds =
        userAReviews.map((r) => r['placeId']).toSet();
    final userBPlaceIds =
        userBReviews.map((r) => r['placeId']).toSet();

    final commonPlaceIds = userAPlaceIds.intersection(userBPlaceIds);

    if (commonPlaceIds.isEmpty) return 0.0;

    double score = 0.0;

    for (final placeId in commonPlaceIds) {
      final reviewA = userAReviews.firstWhere((r) => r['placeId'] == placeId);
      final reviewB = userBReviews.firstWhere((r) => r['placeId'] == placeId);

      final ratingA = reviewA['overallRating'] as String?;
      final ratingB = reviewB['overallRating'] as String?;

      if (ratingA == null || ratingB == null) continue;

      if (ratingA == ratingB) {
        // 완전 일치
        score += 1.0;
      } else if ((ratingA == 'GOOD' && ratingB == 'NEUTRAL') ||
          (ratingA == 'NEUTRAL' && ratingB == 'GOOD') ||
          (ratingA == 'NEUTRAL' && ratingB == 'BAD') ||
          (ratingA == 'BAD' && ratingB == 'NEUTRAL')) {
        // 부분 일치 (한 단계 차이)
        score += 0.5;
      }
      // GOOD vs BAD = 0점
    }

    return (score / commonPlaceIds.length) * 100;
  }

  /// 궁합 등급 계산
  static String getCompatibility(double score) {
    if (score >= 80) return 'VERY_SIMILAR';
    if (score >= 60) return 'SIMILAR';
    if (score >= 40) return 'NEUTRAL';
    return 'DIFFERENT';
  }
}
