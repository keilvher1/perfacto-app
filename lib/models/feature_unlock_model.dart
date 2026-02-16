/// 잠금 해제 가능한 기능
enum UnlockableFeature {
  scores('scores', '점수 보기', 10, '리뷰 10개 작성'),
  matchScore('match_score', '취향 궁합', 15, '리뷰 15개 작성'),
  predictedScore('predicted_score', '예측 점수', 20, '리뷰 20개 작성'),
  leaderboard('leaderboard', '리더보드', 25, '리뷰 25개 작성'),
  advancedStats('advanced_stats', '상세 통계', 50, '리뷰 50개 작성');

  final String code;
  final String label;
  final int requiredReviews;
  final String description;

  const UnlockableFeature(
    this.code,
    this.label,
    this.requiredReviews,
    this.description,
  );

  /// 코드로 기능 찾기
  static UnlockableFeature? fromCode(String code) {
    try {
      return UnlockableFeature.values.firstWhere(
        (f) => f.code == code,
      );
    } catch (e) {
      return null;
    }
  }

  /// 잠금 해제 여부
  bool isUnlocked(int userReviewCount) {
    return userReviewCount >= requiredReviews;
  }

  /// 진행률 (0~100)
  int getProgress(int userReviewCount) {
    if (userReviewCount >= requiredReviews) return 100;
    return ((userReviewCount / requiredReviews) * 100).clamp(0, 100).toInt();
  }

  /// 남은 리뷰 개수
  int getRemainingReviews(int userReviewCount) {
    return (requiredReviews - userReviewCount).clamp(0, requiredReviews);
  }

  /// 잠금 해제까지 남은 텍스트
  String getProgressText(int userReviewCount) {
    final remaining = getRemainingReviews(userReviewCount);
    if (remaining == 0) return '잠금 해제됨!';
    return '리뷰 $remaining개 더 작성';
  }
}

/// 기능 잠금 해제 서비스
class FeatureUnlockService {
  /// 특정 기능이 잠금 해제되었는지 확인
  static bool isUnlocked(UnlockableFeature feature, int userReviewCount) {
    return feature.isUnlocked(userReviewCount);
  }

  /// 모든 기능의 잠금 해제 상태
  static Map<UnlockableFeature, bool> getAllUnlockStatus(int userReviewCount) {
    return {
      for (final feature in UnlockableFeature.values)
        feature: feature.isUnlocked(userReviewCount),
    };
  }

  /// 다음 잠금 해제 기능
  static UnlockableFeature? getNextFeatureToUnlock(int userReviewCount) {
    for (final feature in UnlockableFeature.values) {
      if (!feature.isUnlocked(userReviewCount)) {
        return feature;
      }
    }
    return null; // 모든 기능 해제됨
  }

  /// 진행률
  static int getProgress(UnlockableFeature feature, int userReviewCount) {
    return feature.getProgress(userReviewCount);
  }

  /// 전체 진행률 (%)
  static int getOverallProgress(int userReviewCount) {
    final total = UnlockableFeature.values.length;
    final unlocked = UnlockableFeature.values
        .where((f) => f.isUnlocked(userReviewCount))
        .length;
    return ((unlocked / total) * 100).round();
  }
}
