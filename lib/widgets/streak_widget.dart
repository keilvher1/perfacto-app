import 'package:flutter/material.dart';
import '../models/streak_model.dart';

/// Streak 표시 위젯
class StreakWidget extends StatelessWidget {
  final UserStreak streak;
  final VoidCallback onWriteReview;

  const StreakWidget({
    super.key,
    required this.streak,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = streak.isUrgent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [Colors.orange.shade100, Colors.red.shade100]
              : [Colors.orange.shade50, Colors.yellow.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red.shade300 : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                streak.streakEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 8),
              Text(
                '${streak.currentStreak}일',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            streak.motivationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUrgent ? Colors.red.shade700 : Colors.grey[700],
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          if (!streak.reviewedToday) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onWriteReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('리뷰 작성하기'),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '최장 기록: ${streak.longestStreak}일',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// 간단한 Streak 배지
class StreakBadge extends StatelessWidget {
  final UserStreak streak;

  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            streak.streakEmoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '${streak.currentStreak}일',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
