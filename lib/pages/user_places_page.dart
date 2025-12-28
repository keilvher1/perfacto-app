import 'package:flutter/material.dart';
import 'package:perfacto/models/place_model.dart';
import 'package:perfacto/services/api_service.dart';
import 'package:perfacto/pages/place_detail_page.dart';

/// 특정 사용자의 저장한 장소 + 리뷰 남긴 장소 페이지
class UserPlacesPage extends StatefulWidget {
  final int userId;
  final String userName;

  const UserPlacesPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserPlacesPage> createState() => _UserPlacesPageState();
}

class _UserPlacesPageState extends State<UserPlacesPage> {
  List<PlaceModel> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserPlaces();
  }

  Future<void> _loadUserPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getUserPlaces(widget.userId);
      setState(() {
        _places = data.map((p) => PlaceModel.fromJson(p)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
        title: Text(
          '${widget.userName}님의 장소',
          style: const TextStyle(
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
                        onPressed: _loadUserPlaces,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _places.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 64,
                            color: Color(0xFFD9D9D9),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.userName}님의 장소가 없습니다',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUserPlaces,
                      color: const Color(0xFF4E8AD9),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _places.length,
                        itemBuilder: (context, index) {
                          return _buildPlaceCard(_places[index]);
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
              child: place.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        place.imageUrls.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.place,
                            size: 40,
                            color: Colors.white,
                          );
                        },
                      ),
                    )
                  : const Icon(
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
                        '${place.reviewCount}',
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

            // 북마크 아이콘 (저장 상태 표시)
            if (place.isSaved)
              const Icon(
                Icons.bookmark,
                color: Color(0xFF4E8AD9),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
