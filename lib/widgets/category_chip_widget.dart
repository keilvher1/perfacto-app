import 'package:flutter/material.dart';

/// 카테고리 필터 칩 위젯
///
/// 기능:
/// - 선택/비선택 상태 표시
/// - 카테고리별 아이콘과 레이블 표시
/// - 탭 시 선택 상태 토글
class CategoryChipWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChipWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 37,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4E8AD9).withOpacity(0.9)
              : const Color(0xFFF8F6F0).withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF1B1B1B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1B1B1B),
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 유틸리티 클래스
class CategoryHelper {
  /// 카테고리 레이블을 ID로 변환
  static String getCategoryId(String label) {
    switch (label) {
      case '음식점':
        return 'restaurant';
      case '카페':
        return 'cafe';
      case '가볼만한 곳':
        return 'attraction';
      case '숙박':
        return 'accommodation';
      default:
        return label.toLowerCase();
    }
  }

  /// 카테고리 ID를 레이블로 변환
  static String getCategoryLabel(String id) {
    switch (id) {
      case 'restaurant':
        return '음식점';
      case 'cafe':
        return '카페';
      case 'attraction':
        return '가볼만한 곳';
      case 'accommodation':
        return '숙박';
      default:
        return id;
    }
  }

  /// 카테고리별 아이콘 반환
  static IconData getCategoryIcon(String id) {
    switch (id) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'attraction':
        return Icons.place;
      case 'accommodation':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }
}
