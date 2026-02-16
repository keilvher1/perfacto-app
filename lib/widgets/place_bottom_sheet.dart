import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../models/place_model.dart';
import '../models/review_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/saved_places_service.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/cached_image_widget.dart';
import '../pages/login_page.dart';
import '../pages/review_write_new_page.dart';

/// 장소 상세 정보를 표시하는 바텀시트 위젯
///
/// 기능:
/// - 장소 정보 표시 (이름, 주소, 카테고리, 태그 등)
/// - 리뷰/사진 탭 표시
/// - 저장/공유/리뷰작성 기능
/// - 드래그 가능한 3단계 크기 (0.2, 0.5, 0.95)
class PlaceBottomSheet extends ConsumerStatefulWidget {
  final PlaceModel place;

  const PlaceBottomSheet({
    super.key,
    required this.place,
  });

  /// 바텀시트를 표시하는 정적 메서드
  static Future<void> show(BuildContext context, PlaceModel place) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => PlaceBottomSheet(
        key: ValueKey(place.id),
        place: place,
      ),
    );
  }

  @override
  ConsumerState<PlaceBottomSheet> createState() => _PlaceBottomSheetState();
}

class _PlaceBottomSheetState extends ConsumerState<PlaceBottomSheet>
    with SingleTickerProviderStateMixin {
  double _currentSize = 0.5;
  late TabController _tabController;
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isAddressExpanded = false;
  late bool _isSaved; // Track local saved state

  @override
  void initState() {
    super.initState();
    _isSaved = widget.place.isSaved; // Initialize from place data
    _tabController = TabController(length: 3, vsync: this);
    _loadReviews();
  }

  // 리뷰 데이터를 한 번만 로드
  Future<void> _loadReviews() async {
    try {
      print('🔄 Loading reviews for place: ${widget.place.id}');

      // Firestore에서 리뷰 가져오기
      final reviews = await FirestoreService.getReviews(
        widget.place.id,
        limit: 20,
      );

      print('✅ Loaded ${reviews.length} reviews');

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading reviews: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Toggle save/bookmark state (로컬 저장 사용)
  Future<void> _toggleSave() async {
    try {
      if (_isSaved) {
        // Remove from saved places
        await SavedPlacesService.unsavePlace(widget.place.id);
      } else {
        // Add to saved places
        await SavedPlacesService.savePlace(widget.place.id);
      }

      // Update local state
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved ? '저장되었습니다.' : '저장이 취소되었습니다.',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF4E8AD9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('오류가 발생했습니다'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          setState(() {
            _currentSize = notification.extent;
          });
          return true;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.2, 0.5, 0.95],
          snapAnimationDuration: const Duration(milliseconds: 200),
          builder: (context, scrollController) {
            final isMinimized = _currentSize < 0.21;

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F0),
                borderRadius: isMinimized
                    ? BorderRadius.zero
                    : const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
              ),
              child: SizedBox(
                height: double.infinity,
                child: Column(
                  children: [
                    // Drag handle
                    _buildDragHandle(scrollController),

                    // Header (place name, tag, close button)
                    _buildHeader(isMinimized),

                    // Distance and address with expand button
                    if (!isMinimized) _buildAddressSection(),

                    // 바텀시트가 크게 열렸을 때만 탭 표시
                    if (_currentSize > 0.7) ...[
                      _buildTabBar(),
                      _buildTabBarView(),
                    ] else if (_currentSize > 0.15) ...[
                      _buildDefaultContent(),
                    ],

                    // 하단 버튼 바
                    _buildBottomActionBar(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Drag handle 위젯
  Widget _buildDragHandle(ScrollController scrollController) {
    return SizedBox(
      height: 30,
      child: ListView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        children: [
          SizedBox(
            height: 20,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 14),
                width: 39,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFCDC8),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header 위젯 (장소 이름, 카테고리, 닫기 버튼)
  Widget _buildHeader(bool isMinimized) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.place.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.place.category,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  if (!isMinimized)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E8AD9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.place.tag,
                        style: const TextStyle(
                          color: Color(0xFFF8F6F0),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 주소 섹션 위젯
  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.place.distance,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.place.address ?? "",
                  style: const TextStyle(
                    color: Color(0xFF414141),
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isAddressExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isAddressExpanded = !_isAddressExpanded;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          // 주소 상세 팝업
          if (_isAddressExpanded) _buildExpandedAddress(),
        ],
      ),
    );
  }

  // 확장된 주소 정보 위젯
  Widget _buildExpandedAddress() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: ShapeDecoration(
        color: const Color(0xFFF8F6F0),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 0.50,
            color: Color(0xFFCFCDC8),
          ),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressRow('도로명', widget.place.address ?? ""),
          const SizedBox(height: 4),
          _buildAddressRow('지번', widget.place.address ?? ""),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // 주소 행 위젯
  Widget _buildAddressRow(String label, String address) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: label == '도로명' ? 37 : 27,
          height: 18,
          decoration: ShapeDecoration(
            color: const Color(0xFFF8F6F0),
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: Color(0xFFCFCDC8),
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8D8D8D),
              fontSize: 12,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          address,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF414141),
          ),
        ),
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: address));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('주소가 복사되었습니다'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('복사'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF4E8AD9),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  // TabBar 위젯
  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black,
      labelStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      indicatorColor: Colors.black,
      indicatorWeight: 2,
      tabs: const [
        Tab(text: '홈'),
        Tab(text: '리뷰'),
        Tab(text: '사진'),
      ],
    );
  }

  // TabBarView 위젯
  Widget _buildTabBarView() {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // 홈 탭
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: _buildHomeTabContent(),
          ),

          // 리뷰 탭
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: _buildReviewTabContent(),
          ),

          // 사진 탭
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: _buildPhotoTabContent(),
          ),
        ],
      ),
    );
  }

  // 기본 콘텐츠 (탭 없이)
  Widget _buildDefaultContent() {
    return Expanded(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리뷰 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildReviewSection(),
            ),
            const SizedBox(height: 24),

            // 사진 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPhotoSection(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 리뷰 섹션 위젯
  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
            ),
          )
        else if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 리뷰가 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length > 2 ? 2 : _reviews.length,
            itemBuilder: (context, index) {
              return _buildReviewCard(_reviews[index]);
            },
          ),
      ],
    );
  }

  // 사진 섹션 위젯
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
            ),
          )
        else if (_reviews.expand((r) => r.imageUrls).isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 사진이 없습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _reviews.expand((r) => r.imageUrls).length > 5
                  ? 5
                  : _reviews.expand((r) => r.imageUrls).length,
              itemBuilder: (context, index) {
                final allImages = _reviews.expand((r) => r.imageUrls).toList();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedImageWidget(
                      imageUrl: allImages[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // 하단 액션 바 위젯
  Widget _buildBottomActionBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F0),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        children: [
          // 공유 버튼
          _buildShareButton(),
          const SizedBox(width: 8),

          // 저장 버튼
          _buildSaveButton(),
          const SizedBox(width: 12),

          // 리뷰작성 버튼 (확장)
          Expanded(child: _buildReviewButton()),
        ],
      ),
    );
  }

  // 공유 버튼 위젯
  Widget _buildShareButton() {
    return GestureDetector(
      onTap: () async {
        final shareText =
            '${widget.place.name}\n${widget.place.address ?? ""}\n평점: ${widget.place.rating}';
        await Share.share(
          shareText,
          subject: widget.place.name,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFCFCDC8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/upload.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 6),
            const Text(
              '공유',
              style: TextStyle(
                color: Color(0xFF414141),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 저장 버튼 위젯
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: () async {
        try {
          // Riverpod provider를 사용하여 로그인 상태 확인
          final isLoggedIn = ref.read(isLoggedInProvider);
          if (!isLoggedIn) {
            // Show login page if not logged in
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
            );
            // If login successful, try saving again
            if (result == true && mounted) {
              _toggleSave();
            }
            return;
          }

          // Toggle save state
          _toggleSave();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('오류가 발생했습니다: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _isSaved
              ? const Color(0xFF4E8AD9).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: _isSaved
                ? const Color(0xFF4E8AD9)
                : const Color(0xFFCFCDC8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _isSaved
                  ? 'assets/icons/colored_fish.png'
                  : 'assets/icons/fish.png',
              width: 26,
              height: 26,
            ),
            const SizedBox(width: 6),
            Text(
              _isSaved ? '저장됨' : '저장',
              style: TextStyle(
                color: _isSaved
                    ? const Color(0xFF4E8AD9)
                    : const Color(0xFF414141),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 리뷰 작성 버튼 위젯
  Widget _buildReviewButton() {
    return GestureDetector(
      onTap: () async {
        // Riverpod provider를 사용하여 로그인 상태 확인
        final isLoggedIn = ref.read(isLoggedInProvider);
        if (!isLoggedIn) {
          // 로그인되지 않은 경우 로그인 페이지 표시
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
          // 로그인 성공 시 리뷰 작성 페이지로 이동
          if (result == true && mounted) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewWriteNewPage(
                  place: widget.place,
                ),
              ),
            );
          }
        } else {
          // 이미 로그인된 경우
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewWriteNewPage(
                place: widget.place,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 32,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF4E8AD9),
          borderRadius: BorderRadius.circular(52),
        ),
        alignment: Alignment.center,
        child: const Text(
          '리뷰작성',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // 홈 탭 콘텐츠
  Widget _buildHomeTabContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '장소 정보',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '평점: ${widget.place.rating} (리뷰 ${widget.place.reviewCount}개)',
            style: const TextStyle(fontSize: 14, color: Color(0xFF414141)),
          ),
          const SizedBox(height: 8),
          Text(
            '위치: ${widget.place.address ?? ""}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF414141)),
          ),
        ],
      ),
    );
  }

  // 리뷰 탭 콘텐츠
  Widget _buildReviewTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '아직 리뷰가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  // 사진 탭 콘텐츠
  Widget _buildPhotoTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E8AD9)),
        ),
      );
    }

    final allImages = _reviews.expand((review) => review.imageUrls).toList();

    if (allImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '아직 사진이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedImageWidget(
            imageUrl: allImages[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  // 리뷰 카드
  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 리뷰 헤더 (사용자명, 날짜)
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFF4E8AD9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 리뷰 이미지들
          if (review.imageUrls.isNotEmpty) ...[
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 165,
                    margin: EdgeInsets.only(
                      right: index < review.imageUrls.length - 1 ? 10 : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedImageWidget(
                        imageUrl: review.imageUrls[index],
                        width: 165,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 리뷰 텍스트
          Text(
            review.comment ?? "",
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1B1B1B),
              height: 1.58,
            ),
          ),

          const SizedBox(height: 12),

          // 도움돼요 버튼
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '도움돼요',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
  }
}
