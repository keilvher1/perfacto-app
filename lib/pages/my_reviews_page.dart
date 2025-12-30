import 'package:flutter/material.dart';
import 'package:perfacto/services/api_service.dart';
import 'package:perfacto/services/auth_service.dart';
import 'package:perfacto/models/review_model.dart';
import 'package:perfacto/pages/place_detail_page.dart';
import 'package:intl/intl.dart';

// ReviewRating enum import
export 'package:perfacto/models/review_model.dart' show ReviewRating;

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final userIdStr = AuthService.currentUserId;
      if (userIdStr == null) {
        throw Exception('로그인이 필요합니다');
      }

      final userId = int.parse(userIdStr);
      final reviewsData = await ApiService.getUserReviews(userId);

      final reviews = reviewsData
          .map((data) => ReviewModel.fromJson(data as Map<String, dynamic>))
          .toList();

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 리뷰 로딩 실패: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리뷰 삭제'),
        content: const Text('이 리뷰를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reviewIdInt = int.parse(reviewId);
        await ApiService.deleteReview(reviewIdInt);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리뷰가 삭제되었습니다')),
          );
        }

        _loadReviews(); // 리뷰 목록 새로고침
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('리뷰 삭제 실패: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('내가 쓴 리뷰'),
        backgroundColor: const Color(0xFF4E8AD9),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4E8AD9)),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFD9D9D9),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '리뷰를 불러올 수 없습니다',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8D8D8D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8D8D8D),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E8AD9),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            size: 64,
                            color: Color(0xFFD9D9D9),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '작성한 리뷰가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReviews,
                      color: const Color(0xFF4E8AD9),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return _buildReviewCard(review);
                        },
                      ),
                    ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final dateFormat = DateFormat('yyyy.MM.dd');
    final dateStr = review.createdAt != null
        ? dateFormat.format(review.createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // 장소 상세 페이지로 이동
          final placeIdInt = int.tryParse(review.placeId);
          if (placeIdInt != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailPage(placeId: placeIdInt),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 장소 이름 + 삭제 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      review.placeName ?? '장소 이름 없음',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4E8AD9),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _deleteReview(review.id),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 평가 + 날짜
              Row(
                children: [
                  // 신호등 평가 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: review.overallRating == ReviewRating.good
                          ? Colors.green.withOpacity(0.1)
                          : review.overallRating == ReviewRating.bad
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          review.overallRating == ReviewRating.good
                              ? Icons.sentiment_very_satisfied
                              : review.overallRating == ReviewRating.bad
                                  ? Icons.sentiment_very_dissatisfied
                                  : Icons.sentiment_neutral,
                          size: 16,
                          color: review.overallRating == ReviewRating.good
                              ? Colors.green
                              : review.overallRating == ReviewRating.bad
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.overallRating == ReviewRating.good
                              ? '좋았음'
                              : review.overallRating == ReviewRating.bad
                                  ? '별로임'
                                  : '보통',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: review.overallRating == ReviewRating.good
                                ? Colors.green
                                : review.overallRating == ReviewRating.bad
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 리뷰 내용
              if (review.comment != null && review.comment!.isNotEmpty)
                Text(
                  review.comment!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              // 이미지 미리보기
              if (review.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(review.imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 좋아요 수
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: Color(0xFF8D8D8D),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${review.likeCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
