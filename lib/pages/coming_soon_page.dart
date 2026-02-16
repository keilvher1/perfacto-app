import 'package:flutter/material.dart';

/// 준비 중 페이지
class ComingSoonPage extends StatelessWidget {
  final String featureName;

  const ComingSoonPage({
    super.key,
    this.featureName = '이 기능',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘
                Icon(
                  Icons.construction_rounded,
                  size: 80,
                  color: const Color(0xFF4E8AD9).withOpacity(0.6),
                ),
                const SizedBox(height: 32),

                // 제목
                Text(
                  '$featureName은\n준비 중입니다',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B1B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // 설명
                Text(
                  '더 나은 서비스를 제공하기 위해\n열심히 준비하고 있습니다.\n조금만 기다려 주세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B1B1B).withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // 장식 요소
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4D8F2).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🚀 Coming Soon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E8AD9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
