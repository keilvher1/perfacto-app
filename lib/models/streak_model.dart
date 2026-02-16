/// 사용자 Streak 모델
class UserStreak {
  final int currentStreak; // 현재 연속 일수
  final int longestStreak; // 최장 기록
  final DateTime? lastReviewDate; // 마지막 리뷰 날짜
  final bool reviewedToday; // 오늘 리뷰 작성 여부
  final int hoursUntilStreakBreak; // Streak 끊기기까지 남은 시간

  UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastReviewDate,
    required this.reviewedToday,
    required this.hoursUntilStreakBreak,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['currentStreak'] is int
          ? json['currentStreak']
          : int.tryParse(json['currentStreak']?.toString() ?? '0') ?? 0,
      longestStreak: json['longestStreak'] is int
          ? json['longestStreak']
          : int.tryParse(json['longestStreak']?.toString() ?? '0') ?? 0,
      lastReviewDate: json['lastReviewDate'] != null
          ? DateTime.parse(json['lastReviewDate'])
          : null,
      reviewedToday: json['reviewedToday'] ?? false,
      hoursUntilStreakBreak: json['hoursUntilStreakBreak'] is int
          ? json['hoursUntilStreakBreak']
          : int.tryParse(json['hoursUntilStreakBreak']?.toString() ?? '24') ??
              24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReviewDate': lastReviewDate?.toIso8601String(),
      'reviewedToday': reviewedToday,
      'hoursUntilStreakBreak': hoursUntilStreakBreak,
    };
  }

  /// Streak 이모지
  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7) return '🔥';
    return '✨';
  }

  /// 동기 부여 메시지
  String get motivationMessage {
    if (reviewedToday) {
      return '오늘 리뷰 완료! 내일도 이어가세요!';
    }
    if (hoursUntilStreakBreak <= 6) {
      return '⚠️ Streak이 ${hoursUntilStreakBreak}시간 후 끊겨요!';
    }
    return '오늘 리뷰를 작성해서 Streak을 이어가세요!';
  }

  /// Streak 상태 (긴급, 보통)
  bool get isUrgent => !reviewedToday && hoursUntilStreakBreak <= 6;
}
