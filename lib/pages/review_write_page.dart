import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'location_verification_page.dart';
import 'point_reward_page.dart';
import '../services/firestore_service.dart';
import '../models/review_model.dart';

class ReviewWritePage extends StatefulWidget {
  final String placeName;
  final String placeId;

  const ReviewWritePage({
    super.key,
    required this.placeName,
    required this.placeId,
  });

  @override
  State<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends State<ReviewWritePage> {
  final TextEditingController _reviewController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  bool _isLocationVerified = false;
  List<File> _selectedImages = [];
  double _progressValue = 0.0; // 0.0 = 0%, 0.5 = 50%, 0.8 = 80%, 1.0 = 100%
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // 이미지 선택
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xFile) => File(xFile.path)).toList();
        });
        _updateProgress();
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  // 진행률 계산
  void _updateProgress() {
    double progress = 0.0;

    // 위치 인증: 50%
    if (_isLocationVerified) {
      progress += 0.5;
    }

    // 이미지 업로드: 30%
    if (_selectedImages.isNotEmpty) {
      progress += 0.3;
    }

    // 리뷰 200자 이상 작성: 20%
    if (_reviewController.text.trim().length >= 200) {
      progress += 0.2;
    }

    setState(() {
      _progressValue = progress;
    });
  }

  // 등록 버튼 활성화 여부
  bool get _canSubmit {
    return _isLocationVerified && _selectedImages.isNotEmpty && !_isSubmitting;
  }

  // 리뷰 등록
  Future<void> _submitReview() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. 이미지 업로드
      List<String> imageUrls = await _firestoreService.uploadReviewImages(_selectedImages);

      // 2. 리뷰 데이터 생성
      final user = FirebaseAuth.instance.currentUser;
      final review = ReviewModel(
        id: '',
        placeId: widget.placeId,
        placeName: widget.placeName,
        userId: user?.uid ?? 'anonymous',
        reviewText: _reviewController.text.trim(),
        imageUrls: imageUrls,
        isLocationVerified: _isLocationVerified,
        createdAt: DateTime.now(),
      );

      // 3. Firestore에 저장
      final reviewId = await _firestoreService.addReview(review);

      if (reviewId != null && mounted) {
        // 포인트 정산 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PointRewardPage(
              hasGpsVerification: _isLocationVerified,
              photoCount: _selectedImages.length,
              hasReview: _reviewController.text.trim().isNotEmpty,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰 등록에 실패했습니다. 다시 시도해주세요.'),
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

  // 이미지 삭제
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _updateProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    widget.placeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 진행 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4E8AD9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PERFACT',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFA5A4A0),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      '+20P',
                      style: TextStyle(
                        color: Color(0xFF4E8AD9),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 제목
                    const Text(
                      '리뷰를 작성하고 다녀온 지역의\n리뷰 청결도를 높여보세요',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 위치인증하기 버튼
                    GestureDetector(
                      onTap: () async {
                        // 위치 인증 페이지로 이동
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationVerificationPage(
                              placeName: widget.placeName,
                              placeId: widget.placeId,
                            ),
                          ),
                        );

                        // 인증 성공 시 상태 업데이트
                        if (result == true && mounted) {
                          setState(() {
                            _isLocationVerified = true;
                          });
                          _updateProgress();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 81,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF8D8D8D),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          color: _isLocationVerified
                              ? const Color(0xFF4E8AD9).withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '위치인증하기',
                              style: TextStyle(
                                color: _isLocationVerified
                                    ? const Color(0xFF4E8AD9)
                                    : const Color(0xFF414141),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFA5A4A0),
                                  width: 0.5,
                                ),
                              ),
                              child: const Text(
                                '+50P',
                                style: TextStyle(
                                  color: Color(0xFF4E8AD9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 사진/영상 추가하기
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: 187,
                          maxHeight: _selectedImages.isEmpty ? 187 : 400,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF8D8D8D),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _selectedImages.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '사진/영상 추가하기',
                                        style: TextStyle(
                                          color: Color(0xFF414141),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xFFA5A4A0),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: const Text(
                                          '+30P',
                                          style: TextStyle(
                                            color: Color(0xFF4E8AD9),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    '장소와 무관한 내용은 제외해주세요\n타인의 프라이버시를 존중해주세요',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF8D8D8D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.67,
                                    ),
                                  ),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  '대표',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                        itemCount: _selectedImages.length,
                                        itemBuilder: (context, index) {
                                          return Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(
                                                  _selectedImages[index],
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () => _removeImage(index),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.6),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 리뷰 작성 영역
                    Container(
                      width: double.infinity,
                      height: 187,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF8D8D8D),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextField(
                                controller: _reviewController,
                                maxLines: null,
                                maxLength: 300,
                                decoration: const InputDecoration(
                                  hintText: '리뷰를 작성해 주세요',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF8D8D8D),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  border: InputBorder.none,
                                  counterText: '',
                                ),
                                onChanged: (value) {
                                  _updateProgress();
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_reviewController.text.trim().length >= 200)
                                  const Text(
                                    '성실작성 기준이 충족되었어요!',
                                    style: TextStyle(
                                      color: Color(0xFF4E8AD9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${_reviewController.text.length}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '/300',
                                        style: TextStyle(
                                          color: Color(0xFF8D8D8D),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 리뷰 작성 유의사항
                    const Text(
                      '리뷰 작성 유의사항',
                      style: TextStyle(
                        color: Color(0xFF4E8AD9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 하단 그라데이션 및 등록 버튼
            Container(
              height: 41,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00F8F6F0),
                    Color(0xFFF8F6F0),
                  ],
                ),
              ),
            ),
            Container(
              height: 83,
              color: const Color(0xFFF8F6F0),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: GestureDetector(
                  onTap: _canSubmit ? _submitReview : null,
                  child: Container(
                    width: double.infinity,
                    height: 57,
                    decoration: BoxDecoration(
                      color: _canSubmit
                          ? const Color(0xFF4E8AD9)
                          : const Color(0xFFCFCDC8),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF8F6F0),
                                ),
                              ),
                            )
                          : const Text(
                              '등록하기',
                              style: TextStyle(
                                color: Color(0xFFF8F6F0),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
