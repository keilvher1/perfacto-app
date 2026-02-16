import 'package:flutter/material.dart';
import '../models/predicted_score_model.dart';

/// 예측 점수 표시 위젯
class PredictedScoreWidget extends StatelessWidget {
  final PredictedScore predictedScore;
  final bool compact; // 간단한 표시 모드

  const PredictedScoreWidget({
    super.key,
    required this.predictedScore,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildFullView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 점수 표시
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: predictedScore.scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                predictedScore.scoreText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                    const SizedBox(width: 4),
                    const Text(
                      '예측 점수',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        predictedScore.confidenceText,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  predictedScore.recommendation,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${predictedScore.basedOnUsers}명의 유사 취향 기반',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: predictedScore.scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: predictedScore.scoreColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: predictedScore.scoreColor,
          ),
          const SizedBox(width: 4),
          Text(
            '예측 ${predictedScore.scoreText}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: predictedScore.scoreColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 예측 점수 배지 (간단 표시)
class PredictedScoreBadge extends StatelessWidget {
  final PredictedScore predictedScore;

  const PredictedScoreBadge({super.key, required this.predictedScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: predictedScore.scoreColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            predictedScore.scoreText,
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
