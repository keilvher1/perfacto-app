import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../models/place_model.dart';

/// 3단계 리뷰 작성 페이지
class ReviewWriteNewPage extends StatefulWidget {
  final PlaceModel place;

  const ReviewWriteNewPage({
    super.key,
    required this.place,
  });

  @override
  State<ReviewWriteNewPage> createState() => _ReviewWriteNewPageState();
}

class _ReviewWriteNewPageState extends State<ReviewWriteNewPage> {
  int _currentStep = 0;
  ReviewRating? _selectedRating;
  List<ReviewReason> _selectedReasons = [];
  PlaceModel? _comparedPlace;
  ComparisonResult? _comparisonResult;
  bool _isSubmitting = false;

  // 단계별 완료 여부 확인
  bool get _isStep1Complete => _selectedRating != null;
  bool get _isStep2Complete => _selectedReasons.isNotEmpty;
  bool get _canSubmit => _isStep1Complete && _isStep2Complete;

  // 선택된 평점에 따른 추천 이유 목록
  List<ReviewReason> get _recommendedReasons {
    if (_selectedRating == null) return [];

    switch (_selectedRating!) {
      case ReviewRating.good:
        return [
          ReviewReason.foodDelicious,
          ReviewReason.interiorNice,
          ReviewReason.musicGood,
          ReviewReason.serviceExcellent,
          ReviewReason.atmosphereGood,
          ReviewReason.valueForMoney,
          ReviewReason.wantToRevisit,
        ];
      case ReviewRating.neutral:
        return [
          ReviewReason.averageQuality,
          ReviewReason.fairPrice,
          ReviewReason.nothingSpecial,
        ];
      case ReviewRating.bad:
        return [
          ReviewReason.hygienePoor,
          ReviewReason.parkingLimited,
          ReviewReason.interiorUnappealing,
          ReviewReason.serviceUnfriendly,
          ReviewReason.tooExpensive,
          ReviewReason.longWaitTime,
          ReviewReason.tooNoisy,
        ];
    }
  }

  // 리뷰 제출
  Future<void> _submitReview() async {
    if (!_canSubmit || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createReview(
        placeId: widget.place.id,
        overallRating: _selectedRating!.name.toUpperCase(),
        reasons: _selectedReasons.map((r) => r.name.toUpperCase()).toList(),
        comparedPlaceId: _comparedPlace?.id,
        comparisonResult: _comparisonResult?.name.toUpperCase(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰가 성공적으로 등록되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('리뷰 등록에 실패했습니다: $e'),
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
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 진행 표시기
            _buildProgressIndicator(),

            // 컨텐츠
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildStep1(), // 평점 선택
                  _buildStep2(), // 이유 선택
                  _buildStep3(), // 카테고리 비교 (선택)
                ],
              ),
            ),

            // 하단 버튼
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.place.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // 진행 표시기
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF4E8AD9) : const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Step 1: 평점 선택 (신호등)
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이 장소는 어떠셨나요?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '신호등을 선택해 주세요',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8D8D8D),
            ),
          ),
          const SizedBox(height: 40),

          // 신호등 선택
          _buildRatingOption(
            rating: ReviewRating.good,
            color: Colors.green,
            icon: Icons.sentiment_very_satisfied,
            label: '좋아요',
            description: '만족스러운 경험이었어요',
          ),
          const SizedBox(height: 16),
          _buildRatingOption(
            rating: ReviewRating.neutral,
            color: Colors.orange,
            icon: Icons.sentiment_neutral,
            label: '보통이에요',
            description: '괜찮은 편이에요',
          ),
          const SizedBox(height: 16),
          _buildRatingOption(
            rating: ReviewRating.bad,
            color: Colors.red,
            icon: Icons.sentiment_dissatisfied,
            label: '별로예요',
            description: '아쉬운 점이 있었어요',
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOption({
    required ReviewRating rating,
    required Color color,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedRating == rating;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = rating;
          _selectedReasons.clear(); // 평점 변경 시 이유 초기화
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : const Color(0xFFD9D9D9),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4E8AD9),
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  // Step 2: 이유 선택
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRating == ReviewRating.good
                ? '어떤 점이 좋았나요?'
                : _selectedRating == ReviewRating.neutral
                    ? '어떤 점이 그랬나요?'
                    : '어떤 점이 아쉬웠나요?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '해당되는 것을 모두 선택해 주세요',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8D8D8D),
            ),
          ),
          const SizedBox(height: 24),

          // 이유 선택 칩들
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recommendedReasons.map((reason) {
              final isSelected = _selectedReasons.contains(reason);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedReasons.remove(reason);
                    } else {
                      _selectedReasons.add(reason);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4E8AD9) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4E8AD9) : const Color(0xFFD9D9D9),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _getReasonLabel(reason),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 3: 카테고리 비교 (선택사항)
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '같은 카테고리의\n다른 장소와 비교해 보세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '선택사항입니다',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8D8D8D),
            ),
          ),
          const SizedBox(height: 32),

          // 비교 장소 선택 (TODO: 실제로는 검색 화면으로 이동)
          GestureDetector(
            onTap: () {
              // TODO: 장소 검색 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('장소 검색 기능은 준비 중입니다')),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD9D9D9)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _comparedPlace?.name ?? '비교할 장소 선택',
                      style: TextStyle(
                        fontSize: 16,
                        color: _comparedPlace != null
                            ? Colors.black
                            : const Color(0xFF8D8D8D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_comparedPlace != null) ...[
            const SizedBox(height: 24),
            const Text(
              '어느 곳이 더 나았나요?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // 비교 결과 선택
            _buildComparisonOption(
              result: ComparisonResult.better,
              label: '${widget.place.name}이(가) 더 좋아요',
            ),
            const SizedBox(height: 12),
            _buildComparisonOption(
              result: ComparisonResult.similar,
              label: '비슷해요',
            ),
            const SizedBox(height: 12),
            _buildComparisonOption(
              result: ComparisonResult.worse,
              label: '${_comparedPlace!.name}이(가) 더 좋아요',
            ),
          ],

          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = 2; // 3단계를 건너뛰고 제출
                });
              },
              child: const Text(
                '비교하지 않고 건너뛰기',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8D8D8D),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonOption({
    required ComparisonResult result,
    required String label,
  }) {
    final isSelected = _comparisonResult == result;

    return GestureDetector(
      onTap: () {
        setState(() {
          _comparisonResult = result;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4E8AD9).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4E8AD9) : const Color(0xFFD9D9D9),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4E8AD9),
              ),
          ],
        ),
      ),
    );
  }

  // 하단 버튼
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
          // 이전 버튼
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF4E8AD9)),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text(
                      '이전',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4E8AD9),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // 다음/완료 버튼
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isSubmitting ? null : () {
                if (_currentStep == 0 && _isStep1Complete) {
                  setState(() {
                    _currentStep = 1;
                  });
                } else if (_currentStep == 1 && _isStep2Complete) {
                  setState(() {
                    _currentStep = 2;
                  });
                } else if (_currentStep == 2) {
                  _submitReview();
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _getNextButtonEnabled()
                      ? const Color(0xFF4E8AD9)
                      : const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _getNextButtonLabel(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _getNextButtonEnabled() {
    if (_currentStep == 0) return _isStep1Complete;
    if (_currentStep == 1) return _isStep2Complete;
    if (_currentStep == 2) return true; // 3단계는 선택사항
    return false;
  }

  String _getNextButtonLabel() {
    if (_currentStep == 0) return '다음';
    if (_currentStep == 1) return '다음';
    if (_currentStep == 2) return '완료';
    return '다음';
  }

  String _getReasonLabel(ReviewReason reason) {
    switch (reason) {
      case ReviewReason.foodDelicious:
        return '음식이 맛있어요';
      case ReviewReason.interiorNice:
        return '인테리어가 좋아요';
      case ReviewReason.musicGood:
        return '음악이 좋아요';
      case ReviewReason.serviceExcellent:
        return '서비스가 훌륭해요';
      case ReviewReason.atmosphereGood:
        return '분위기가 좋아요';
      case ReviewReason.valueForMoney:
        return '가성비가 좋아요';
      case ReviewReason.wantToRevisit:
        return '재방문 의사 있어요';
      case ReviewReason.averageQuality:
        return '평범해요';
      case ReviewReason.fairPrice:
        return '가격이 적당해요';
      case ReviewReason.nothingSpecial:
        return '특별한 점이 없어요';
      case ReviewReason.hygienePoor:
        return '위생이 아쉬워요';
      case ReviewReason.parkingLimited:
        return '주차가 불편해요';
      case ReviewReason.interiorUnappealing:
        return '인테리어가 별로예요';
      case ReviewReason.serviceUnfriendly:
        return '서비스가 불친절해요';
      case ReviewReason.tooExpensive:
        return '가격이 비싸요';
      case ReviewReason.longWaitTime:
        return '대기 시간이 길어요';
      case ReviewReason.tooNoisy:
        return '너무 시끄러워요';
    }
  }
}
