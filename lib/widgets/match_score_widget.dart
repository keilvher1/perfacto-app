import 'package:flutter/material.dart';
import '../models/match_score_model.dart';

/// Match Score 표시 위젯
class MatchScoreWidget extends StatelessWidget {
  final MatchScore matchScore;
  final bool showDetails;
  final VoidCallback? onTap;

  const MatchScoreWidget({
    super.key,
    required this.matchScore,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: matchScore.scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: matchScore.scoreColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  matchScore.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '취향 궁합',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  matchScore.scoreText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: matchScore.scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: matchScore.score / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(matchScore.scoreColor),
                minHeight: 8,
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 12),
              Text(
                matchScore.compatibilityText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '공통 방문 장소: ${matchScore.commonPlacesCount}곳',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 간단한 Match Score 배지 (작은 사이즈)
class MatchScoreBadge extends StatelessWidget {
  final MatchScore matchScore;

  const MatchScoreBadge({super.key, required this.matchScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: matchScore.scoreColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            matchScore.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            matchScore.scoreText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
