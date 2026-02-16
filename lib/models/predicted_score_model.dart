import 'package:flutter/material.dart';

/// 예측 점수 모델 (협업 필터링 기반)
class PredictedScore {
  final int placeId;
  final double score; // 예측 점수 (0~10)
  final double confidence; // 신뢰도 (0~1)
  final int basedOnUsers; // 계산에 사용된 유사 사용자 수
  final String recommendation; // 추천 메시지

  PredictedScore({
    required this.placeId,
    required this.score,
    required this.confidence,
    required this.basedOnUsers,
    required this.recommendation,
  });

  factory PredictedScore.fromJson(Map<String, dynamic> json) {
    return PredictedScore(
      placeId: json['placeId'] is int
          ? json['placeId']
          : int.tryParse(json['placeId']?.toString() ?? '0') ?? 0,
      score: (json['score'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      basedOnUsers: json['basedOnUsers'] is int
          ? json['basedOnUsers']
          : int.tryParse(json['basedOnUsers']?.toString() ?? '0') ?? 0,
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'score': score,
      'confidence': confidence,
      'basedOnUsers': basedOnUsers,
      'recommendation': recommendation,
    };
  }

  /// 점수 표시 텍스트 (소수점 1자리)
  String get scoreText => score.toStringAsFixed(1);

  /// 신뢰도 텍스트
  String get confidenceText {
    if (confidence >= 0.8) return '매우 정확';
    if (confidence >= 0.6) return '정확';
    if (confidence >= 0.4) return '보통';
    return '참고용';
  }

  /// 점수에 따른 색상
  Color get scoreColor {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.lightGreen;
    if (score >= 4.0) return Colors.orange;
    return Colors.red;
  }

  /// 추천 여부 (점수 6점 이상)
  bool get isRecommended => score >= 6.0;

  /// 추천 아이콘
  IconData get recommendIcon {
    if (score >= 8.0) return Icons.thumb_up;
    if (score >= 6.0) return Icons.check_circle;
    if (score >= 4.0) return Icons.help_outline;
    return Icons.thumb_down;
  }
}

/// 예측 점수 계산 유틸리티
class PredictedScoreCalculator {
  /// 협업 필터링 기반 예측 점수 계산 (프론트엔드 시뮬레이션)
  ///
  /// User-Based Collaborative Filtering:
  /// 1. 유사한 취향의 사용자들 찾기 (Match Score 활용)
  /// 2. 해당 사용자들의 이 장소 평가 가중 평균 계산
  static double calculate({
    required int placeId,
    required List<Map<String, dynamic>> similarUsers,
  }) {
    double weightedSum = 0.0;
    double weightSum = 0.0;

    for (final user in similarUsers) {
      // 유사 사용자의 Match Score
      final matchScore = (user['matchScore'] ?? 0).toDouble();

      // 이 사용자의 placeId에 대한 리뷰
      final reviews = user['reviews'] as List<dynamic>?;
      if (reviews == null) continue;

      final placeReview = reviews.firstWhere(
        (r) => r['placeId'] == placeId,
        orElse: () => null,
      );

      if (placeReview != null) {
        final rating = placeReview['overallRating'] as String?;
        if (rating != null) {
          final weight = matchScore / 100; // 0~1 범위로 정규화
          weightedSum += weight * _ratingToScore(rating);
          weightSum += weight;
        }
      }
    }

    if (weightSum == 0) return 5.0; // 데이터 없을 시 중립 점수

    return weightedSum / weightSum;
  }

  /// 리뷰 등급을 점수로 변환
  static double _ratingToScore(String rating) {
    switch (rating.toUpperCase()) {
      case 'GOOD':
        return 8.5;
      case 'NEUTRAL':
        return 5.5;
      case 'BAD':
        return 2.5;
      default:
        return 5.0;
    }
  }

  /// 신뢰도 계산
  static double calculateConfidence({
    required int basedOnUsers,
    required double averageMatchScore,
  }) {
    // 사용자 수와 평균 Match Score 기반 신뢰도
    final userFactor = (basedOnUsers / 10).clamp(0.0, 1.0);
    final matchFactor = averageMatchScore / 100;

    return (userFactor * 0.6 + matchFactor * 0.4).clamp(0.0, 1.0);
  }

  /// 추천 메시지 생성
  static String generateRecommendation(double score, double confidence) {
    if (score >= 8.0) {
      return confidence >= 0.7
          ? '당신의 취향에 딱 맞을 것 같아요!'
          : '당신이 좋아할 만한 곳이에요';
    } else if (score >= 6.0) {
      return '방문해볼 만한 곳이에요';
    } else if (score >= 4.0) {
      return '취향에 따라 다를 수 있어요';
    } else {
      return '당신의 취향과 맞지 않을 수 있어요';
    }
  }
}
