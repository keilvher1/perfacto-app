import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// 카테고리 탭 바 위젯
class CategoryTabBar extends StatelessWidget {
  final PlaceCategory selectedCategory;
  final Function(PlaceCategory) onCategoryChanged;

  const CategoryTabBar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: PlaceCategory.values.length,
        itemBuilder: (context, index) {
          final category = PlaceCategory.values[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: _CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => onCategoryChanged(category),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final PlaceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? category.color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? category.color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
