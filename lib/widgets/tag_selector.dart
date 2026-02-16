import 'package:flutter/material.dart';
import '../models/tag_model.dart';

/// 태그 선택 위젯
class TagSelector extends StatefulWidget {
  final List<PlaceTag> selectedTags;
  final Function(List<PlaceTag>) onChanged;
  final int maxSelection;
  final String? categoryCode; // 카테고리에 맞는 태그 필터링

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.maxSelection = 5,
    this.categoryCode,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  List<PlaceTag> get _availableTags {
    if (widget.categoryCode != null) {
      return PlaceTag.getRecommendedTags(widget.categoryCode!);
    }
    return PlaceTag.all;
  }

  void _onTagToggle(PlaceTag tag) {
    final newTags = List<PlaceTag>.from(widget.selectedTags);

    if (newTags.contains(tag)) {
      // 이미 선택된 태그는 제거
      newTags.remove(tag);
    } else {
      // 최대 선택 개수 체크
      if (newTags.length >= widget.maxSelection) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('최대 ${widget.maxSelection}개까지 선택 가능합니다'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      newTags.add(tag);
    }

    widget.onChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 선택된 태그 카운트
        if (widget.selectedTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '선택됨: ${widget.selectedTags.length}/${widget.maxSelection}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // 태그 칩 리스트
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = widget.selectedTags.contains(tag);
            return _TagChip(
              tag: tag,
              isSelected: isSelected,
              onTap: () => _onTagToggle(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final PlaceTag tag;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              tag.label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 태그 표시 위젯 (읽기 전용)
class TagDisplay extends StatelessWidget {
  final List<PlaceTag> tags;
  final int? maxDisplay; // 최대 표시 개수

  const TagDisplay({
    super.key,
    required this.tags,
    this.maxDisplay,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final displayTags = maxDisplay != null && tags.length > maxDisplay!
        ? tags.sublist(0, maxDisplay!)
        : tags;

    final remainingCount =
        maxDisplay != null && tags.length > maxDisplay! ? tags.length - maxDisplay! : 0;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayTags.map((tag) => _TagDisplayChip(tag: tag)),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remainingCount',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagDisplayChip extends StatelessWidget {
  final PlaceTag tag;

  const _TagDisplayChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 3),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
