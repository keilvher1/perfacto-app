import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../services/saved_places_service.dart';
import 'review_write_new_page.dart';

/// 장소 상세 페이지
class PlaceDetailPage extends StatefulWidget {
  final int placeId;

  const PlaceDetailPage({
    super.key,
    required this.placeId,
  });

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlaceModel? _place;
  List<ReviewModel> _allReviews = [];
  List<ReviewModel> _followingReviews = [];
  bool _isLoading = true;
  bool _isSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 장소 정보 로드
      print('🔍 DEBUG - Loading place: ${widget.placeId}');
      final placeData = await ApiService.getPlace(widget.placeId);
      print('🔍 DEBUG - Place data type: ${placeData.runtimeType}');
      print('🔍 DEBUG - Place data keys: ${placeData.keys}');

      _place = PlaceModel.fromJson(placeData);
      print('✅ DEBUG - Place loaded successfully');

      // 전체 리뷰 로드
      print('🔍 DEBUG - Loading reviews for place: ${widget.placeId}');
      final allReviewsData = await ApiService.getReviews(widget.placeId);
      print('🔍 DEBUG - Reviews data type: ${allReviewsData.runtimeType}');
      print('🔍 DEBUG - Reviews count: ${allReviewsData.length}');

      if (allReviewsData.isNotEmpty) {
        print('🔍 DEBUG - First review data: ${allReviewsData[0]}');
      }

      _allReviews = allReviewsData.map((r) => ReviewModel.fromJson(r)).toList();
      print('✅ DEBUG - Reviews loaded successfully');

      // 팔로잉 리뷰 로드 (로그인 시)
      try {
        final followingReviewsData =
            await ApiService.getFollowingReviews(widget.placeId);
        _followingReviews =
            followingReviewsData.map((r) => ReviewModel.fromJson(r)).toList();
      } catch (e) {
        print('⚠️ DEBUG - Following reviews error: $e');
        // 로그인하지 않았거나 팔로잉이 없는 경우
        _followingReviews = [];
      }

      // 저장 여부 확인 (로컬에서)
      try {
        _isSaved = await SavedPlacesService.isSaved(widget.placeId);
        print('🔍 DEBUG - Is saved: $_isSaved');
      } catch (e) {
        print('⚠️ DEBUG - Is saved check error: $e');
        _isSaved = false;
      }

      setState(() {
        _isLoading = false;
      });
      print('✅ DEBUG - All data loaded successfully');
    } catch (e, stackTrace) {
      print('❌ DEBUG - Load data error: $e');
      print('❌ DEBUG - Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaved() async {
    try {
      if (_isSaved) {
        await SavedPlacesService.unsavePlace(widget.placeId);
      } else {
        await SavedPlacesService.savePlace(widget.placeId);
      }

      setState(() {
        _isSaved = !_isSaved;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? '저장되었습니다' : '저장이 취소되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4E8AD9),
          ),
        ),
      );
    }

    if (_error != null || _place == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '장소 정보를 불러올 수 없습니다',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 장소 정보
            _buildPlaceInfo(),

            // 탭 바
            _buildTabBar(),

            // 탭 뷰
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReviewList(_followingReviews, isFollowingTab: true),
                  _buildReviewList(_allReviews, isFollowingTab: false),
                ],
              ),
            ),

            // 리뷰 작성 버튼
            _buildWriteReviewButton(),
          ],
        ),
      ),
    );
  }

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
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? const Color(0xFF4E8AD9) : null,
            ),
            onPressed: _toggleSaved,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 공유 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공유 기능은 준비 중입니다')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _place!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4E8AD9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _place!.category,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4E8AD9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_place!.district != null)
                Text(
                  _place!.district!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D8D8D),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_place!.address != null)
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF8D8D8D),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _place!.address!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.star,
                label: '평점',
                value: _place!.averageRating?.toStringAsFixed(1) ?? '-',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.rate_review_outlined,
                label: '리뷰',
                value: '${_allReviews.length}',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.bookmark_outline,
                label: '저장',
                value: '${_place!.saveCount ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8D8D8D)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8D8D8D),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4E8AD9),
        unselectedLabelColor: const Color(0xFF8D8D8D),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: const Color(0xFF4E8AD9),
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('팔로잉 리뷰'),
                if (_followingReviews.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E8AD9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_followingReviews.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: '전체 리뷰'),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<ReviewModel> reviews,
      {required bool isFollowingTab}) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowingTab ? Icons.people_outline : Icons.rate_review_outlined,
              size: 64,
              color: const Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 16),
            Text(
              isFollowingTab
                  ? '팔로잉한 사용자의 리뷰가 없습니다'
                  : '아직 리뷰가 없습니다',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8D8D8D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFollowingTab
                  ? '다른 사용자를 팔로우하거나\n전체 리뷰 탭을 확인해보세요'
                  : '첫 번째 리뷰를 작성해보세요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD9D9D9),
                child: Text(
                  review.userId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사용자 ${review.userId.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                  ],
                ),
              ),
              // 평점 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getRatingColor(review.overallRating).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getRatingIcon(review.overallRating),
                  color: _getRatingColor(review.overallRating),
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 이유 태그들
          if (review.reasons.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.reasons.map((reason) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E8AD9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getReasonLabel(reason),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4E8AD9),
                    ),
                  ),
                );
              }).toList(),
            ),

          // 비교 정보
          if (review.comparedPlaceId != null && review.comparisonResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows,
                    size: 16,
                    color: Color(0xFF8D8D8D),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getComparisonText(review.comparisonResult!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // 좋아요 수
          Row(
            children: [
              const Icon(
                Icons.thumb_up_outlined,
                size: 16,
                color: Color(0xFF8D8D8D),
              ),
              const SizedBox(width: 4),
              Text(
                '도움이 됨 ${review.likeCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8D8D8D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewButton() {
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
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewWriteNewPage(place: _place!),
            ),
          );

          if (result == true) {
            _loadData(); // 리뷰 작성 후 새로고침
          }
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF4E8AD9),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '리뷰 작성하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.good:
        return Colors.green;
      case ReviewRating.neutral:
        return Colors.orange;
      case ReviewRating.bad:
        return Colors.red;
    }
  }

  IconData _getRatingIcon(ReviewRating rating) {
    switch (rating) {
      case ReviewRating.good:
        return Icons.sentiment_very_satisfied;
      case ReviewRating.neutral:
        return Icons.sentiment_neutral;
      case ReviewRating.bad:
        return Icons.sentiment_dissatisfied;
    }
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

  String _getComparisonText(ComparisonResult result) {
    switch (result) {
      case ComparisonResult.better:
        return '다른 곳보다 더 좋아요';
      case ComparisonResult.similar:
        return '다른 곳과 비슷해요';
      case ComparisonResult.worse:
        return '다른 곳이 더 좋아요';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.year}.${date.month}.${date.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
