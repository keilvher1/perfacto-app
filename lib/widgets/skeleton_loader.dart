import 'package:flutter/material.dart';

/// 스켈레톤 로더 위젯
///
/// 데이터 로딩 중 표시되는 플레이스홀더 UI
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// 리스트 아이템 스켈레톤
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 아이콘/이미지 영역
          const SkeletonLoader(
            width: 60,
            height: 60,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 16),
          // 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 스켈레톤
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(
            width: double.infinity,
            height: 150,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 16),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// 프로필 스켈레톤
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // 프로필 이미지
        const SkeletonLoader(
          width: 80,
          height: 80,
          borderRadius: BorderRadius.all(Radius.circular(40)),
        ),
        const SizedBox(height: 16),
        // 이름
        SkeletonLoader(
          width: MediaQuery.of(context).size.width * 0.4,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        // 이메일
        SkeletonLoader(
          width: MediaQuery.of(context).size.width * 0.5,
          height: 16,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 24),
        // 통계
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
            (index) => Column(
              children: [
                SkeletonLoader(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 60,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
