import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/saved_places_service.dart';
import 'place_detail_page.dart';
import 'login_page.dart';

/// 저장된 장소 페이지
class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({super.key});

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  List<PlaceModel> _savedPlaces = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadPlaces();
  }

  Future<void> _checkLoginAndLoadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 로그인 여부 확인
    final loggedIn = await AuthService.isLoggedIn();

    if (!loggedIn) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoggedIn = true;
    });

    await _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 로컬에서 저장된 장소 ID 목록 가져오기
      final savedIds = await SavedPlacesService.getSavedPlaceIds();
      print('🔍 DEBUG - 저장된 장소 ID: $savedIds');

      if (savedIds.isEmpty) {
        setState(() {
          _savedPlaces = [];
          _isLoading = false;
        });
        return;
      }

      // 전체 카테고리의 장소 데이터 가져오기
      final List<PlaceModel> allPlaces = [];
      for (int categoryId = 1; categoryId <= 4; categoryId++) {
        try {
          final places = await ApiService.getPlaces(categoryId: categoryId, size: 100);
          for (var placeData in places) {
            allPlaces.add(PlaceModel.fromJson(placeData));
          }
        } catch (e) {
          print('❌ DEBUG - 카테고리 $categoryId 로딩 실패: $e');
        }
      }

      // 저장된 ID에 해당하는 장소만 필터링
      final savedPlaces = allPlaces.where((place) => savedIds.contains(place.id)).toList();
      print('✅ DEBUG - 저장된 장소 ${savedPlaces.length}개 로드됨');

      setState(() {
        _savedPlaces = savedPlaces;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG - _loadSavedPlaces error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unsavePlace(int placeId) async {
    try {
      // 로컬에서 저장 취소
      await SavedPlacesService.unsavePlace(placeId);
      await _loadSavedPlaces(); // 새로고침

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장이 취소되었습니다')),
        );
      }
    } catch (e) {
      print('❌ DEBUG - _unsavePlace error: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '저장한 장소',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4E8AD9)),
            )
          : !_isLoggedIn
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.login,
                        size: 64,
                        color: Color(0xFF4E8AD9),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '로그인이 필요합니다',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '저장한 장소를 보려면 로그인해주세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8D8D8D),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E8AD9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          ).then((loggedIn) {
                            // 로그인 후 돌아왔을 때 다시 로드
                            if (loggedIn == true) {
                              _checkLoginAndLoadPlaces();
                            }
                          });
                        },
                        child: const Text('로그인하기'),
                      ),
                    ],
                  ),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text('데이터를 불러올 수 없습니다'),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadSavedPlaces,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _savedPlaces.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: Color(0xFFD9D9D9),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '저장한 장소가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '마음에 드는 장소를 저장해보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSavedPlaces,
                      color: const Color(0xFF4E8AD9),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _savedPlaces.length,
                        itemBuilder: (context, index) {
                          return _buildPlaceCard(_savedPlaces[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPlaceCard(PlaceModel place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailPage(placeId: place.id),
          ),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            // 장소 이미지 (임시로 아이콘 사용)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.place,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // 장소 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4E8AD9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      place.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4E8AD9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (place.address != null)
                    Text(
                      place.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D8D8D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        place.averageRating?.toStringAsFixed(1) ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.rate_review_outlined,
                        size: 14,
                        color: Color(0xFF8D8D8D),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${place.reviewCount ?? 0}',
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

            // 저장 해제 버튼
            IconButton(
              icon: const Icon(
                Icons.bookmark,
                color: Color(0xFF4E8AD9),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('저장 취소'),
                    content: Text('${place.name}을(를) 저장 목록에서 제거하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  _unsavePlace(place.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
