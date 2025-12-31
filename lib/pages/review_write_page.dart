import 'package:flutter/material.dart';
import 'package:perfacto/services/api_service.dart';

class ReviewWritePage extends StatefulWidget {
  final int placeId;
  final String placeName;

  const ReviewWritePage({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends State<ReviewWritePage> {
  // 3단계 리뷰 시스템 상태
  int _currentStep = 1;

  // 1단계: 전체 평가
  String? _overallRating;

  // 2단계: 이유 선택
  final Set<String> _selectedReasons = {};

  // 3단계: 비교 (선택사항)
  int? _comparedPlaceId;
  String? _comparisonResult;

  bool _isSubmitting = false;

  // 평가 옵션
  final List<Map<String, dynamic>> _ratingOptions = [
    {'value': 'GOOD', 'label': '좋아요', 'icon': Icons.sentiment_satisfied, 'color': Color(0xFF4E8AD9)},
    {'value': 'NEUTRAL', 'label': '괜찮아요', 'icon': Icons.sentiment_neutral, 'color': Color(0xFFFFA726)},
    {'value': 'BAD', 'label': '별로예요', 'icon': Icons.sentiment_dissatisfied, 'color': Color(0xFFE57373)},
  ];

  // 이유 옵션 (각 평가별)
  final Map<String, List<Map<String, String>>> _reasonsByRating = {
    'GOOD': [
      {'value': 'CLEAN', 'label': '깨끗해요'},
      {'value': 'FRIENDLY', 'label': '친절해요'},
      {'value': 'DELICIOUS', 'label': '맛있어요'},
      {'value': 'ATMOSPHERE', 'label': '분위기가 좋아요'},
      {'value': 'REASONABLE', 'label': '가격이 합리적이에요'},
      {'value': 'LOCATION', 'label': '위치가 좋아요'},
    ],
    'NEUTRAL': [
      {'value': 'ORDINARY', 'label': '평범해요'},
      {'value': 'ACCEPTABLE', 'label': '무난해요'},
      {'value': 'PRICE_MATCH', 'label': '가격대비 괜찮아요'},
    ],
    'BAD': [
      {'value': 'DIRTY', 'label': '지저분해요'},
      {'value': 'UNFRIENDLY', 'label': '불친절해요'},
      {'value': 'NOT_DELICIOUS', 'label': '맛없어요'},
      {'value': 'NOISY', 'label': '시끄러워요'},
      {'value': 'EXPENSIVE', 'label': '비싸요'},
      {'value': 'INCONVENIENT', 'label': '불편해요'},
    ],
  };

  List<Map<String, String>> get _currentReasonOptions {
    if (_overallRating == null) return [];
    return _reasonsByRating[_overallRating] ?? [];
  }

  bool get _canProceedToStep2 => _overallRating != null;
  bool get _canProceedToStep3 => _selectedReasons.isNotEmpty;
  bool get _canSubmit => _selectedReasons.isNotEmpty && !_isSubmitting;

  Future<void> _submitReview() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createReview(
        placeId: widget.placeId,
        overallRating: _overallRating!,
        reasons: _selectedReasons.toList(),
        comparedPlaceId: _comparedPlaceId,
        comparisonResult: _comparisonResult,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰가 등록되었습니다'),
            backgroundColor: Color(0xFF4E8AD9),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리뷰 등록 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: Text(widget.placeName),
        backgroundColor: const Color(0xFF4E8AD9),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 진행 표시
          _buildProgressIndicator(),

          // 단계별 컨텐츠
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
            ),
          ),

          // 하단 버튼
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber <= _currentStep;
          final isCompleted = stepNumber < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF4E8AD9) : const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이 장소는 어떠셨나요?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '전체적인 평가를 선택해주세요',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8D8D8D),
          ),
        ),
        const SizedBox(height: 32),

        ..._ratingOptions.map((option) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildRatingOption(
            value: option['value'] as String,
            label: option['label'] as String,
            icon: option['icon'] as IconData,
            color: option['color'] as Color,
          ),
        )),
      ],
    );
  }

  Widget _buildRatingOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _overallRating == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _overallRating = value;
          _selectedReasons.clear(); // 평가 변경 시 이유 초기화
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFD9D9D9),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : const Color(0xFF8D8D8D),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '어떤 점이 그러셨나요?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '해당되는 이유를 모두 선택해주세요',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8D8D8D),
          ),
        ),
        const SizedBox(height: 32),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _currentReasonOptions.map((reason) {
            final isSelected = _selectedReasons.contains(reason['value']);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedReasons.remove(reason['value']);
                  } else {
                    _selectedReasons.add(reason['value']!);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4E8AD9) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF4E8AD9) : const Color(0xFFD9D9D9),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  reason['label']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '다른 장소와 비교해보세요',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '선택사항입니다. 건너뛰어도 됩니다.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8D8D8D),
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: const Center(
            child: Text(
              '비교 기능은 추후 업데이트 예정입니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF4E8AD9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4E8AD9),
                  ),
                ),
              ),
            ),

          if (_currentStep > 1) const SizedBox(width: 12),

          Expanded(
            flex: _currentStep == 1 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _getNextButtonAction(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _getNextButtonColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    if (_currentStep == 1) {
      return _canProceedToStep2 ? () {
        setState(() {
          _currentStep = 2;
        });
      } : null;
    } else if (_currentStep == 2) {
      return _canProceedToStep3 ? () {
        setState(() {
          _currentStep = 3;
        });
      } : null;
    } else {
      return _canSubmit ? _submitReview : null;
    }
  }

  Color _getNextButtonColor() {
    final canProceed = _currentStep == 1 ? _canProceedToStep2 :
                       _currentStep == 2 ? _canProceedToStep3 :
                       _canSubmit;
    return canProceed ? const Color(0xFF4E8AD9) : const Color(0xFFCFCDC8);
  }

  String _getNextButtonText() {
    if (_currentStep == 3) {
      return '등록하기';
    }
    return '다음';
  }
}
