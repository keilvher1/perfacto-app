/// 리더보드 엔트리 모델
class LeaderboardEntry {
  final int rank;
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final int reviewCount;
  final int totalPoints;
  final int currentStreak;
  final int? rankChange; // +2, -1, null(변동없음)

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.reviewCount,
    required this.totalPoints,
    required this.currentStreak,
    this.rankChange,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] is int
          ? json['rank']
          : int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      userId: json['userId'] is int
          ? json['userId']
          : int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      nickname: json['nickname'] ?? 'Unknown',
      profileImageUrl: json['profileImageUrl'],
      reviewCount: json['reviewCount'] is int
          ? json['reviewCount']
          : int.tryParse(json['reviewCount']?.toString() ?? '0') ?? 0,
      totalPoints: json['totalPoints'] is int
          ? json['totalPoints']
          : int.tryParse(json['totalPoints']?.toString() ?? '0') ?? 0,
      currentStreak: json['currentStreak'] is int
          ? json['currentStreak']
          : int.tryParse(json['currentStreak']?.toString() ?? '0') ?? 0,
      rankChange: json['rankChange'] is int
          ? json['rankChange']
          : (json['rankChange'] != null
              ? int.tryParse(json['rankChange'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'reviewCount': reviewCount,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'rankChange': rankChange,
    };
  }

  /// 순위 변동 텍스트
  String get rankChangeText {
    if (rankChange == null || rankChange == 0) return '-';
    return rankChange! > 0 ? '+${rankChange!}' : '${rankChange!}';
  }

  /// 순위 변동 여부
  bool get hasRankChange => rankChange != null && rankChange != 0;

  /// 순위 상승 여부
  bool get isRankUp => rankChange != null && rankChange! > 0;
}
