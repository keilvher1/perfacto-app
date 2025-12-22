import 'package:flutter/material.dart';
import 'package:perfacto/models/place_model.dart';
import 'package:perfacto/services/api_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  bool _isLoading = true;
  List<PlaceModel> _places = [];
  String _errorMessage = '';

  // 필터 상태
  int? _selectedCategoryId;
  String? _selectedDistrict;

  // 카테고리 목록
  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': '전체'},
    {'id': 1, 'name': '음식점'},
    {'id': 2, 'name': '숙박'},
    {'id': 3, 'name': '카페'},
    {'id': 4, 'name': '관광지'},
  ];

  // 구역 목록
  final List<String?> _districts = [
    null, // 전체
    '남구',
    '북구',
    '동구',
    '서구',
  ];

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await ApiService.getRanking(
        categoryId: _selectedCategoryId,
        district: _selectedDistrict,
        limit: 50,
      );

      final places = data.map((json) => PlaceModel.fromJson(json)).toList();

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getCategoryName() {
    if (_selectedCategoryId == null) return '전체';
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategoryId,
      orElse: () => {'name': '전체'},
    );
    return category['name'];
  }

  String _getDistrictName() {
    return _selectedDistrict ?? '포항';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('ELO RANKINGS'),
        backgroundColor: const Color(0xFF4E8AD9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 필터 섹션
          _buildFilterSection(),

          // 랭킹 타이틀
          _buildRankingTitle(),

          // 랭킹 리스트
          Expanded(
            child: _buildRankingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 지역 필터
          Expanded(
            child: _buildFilterDropdown(
              label: 'Region',
              value: _selectedDistrict,
              items: _districts.map((district) {
                return DropdownMenuItem<String?>(
                  value: district,
                  child: Text(district ?? '전체'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value;
                });
                _loadRanking();
              },
            ),
          ),
          const SizedBox(width: 16),

          // 카테고리 필터
          Expanded(
            child: _buildFilterDropdown(
              label: 'Category',
              value: _selectedCategoryId,
              items: _categories.map((category) {
                return DropdownMenuItem<int?>(
                  value: category['id'],
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
                _loadRanking();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8D8D8D),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        '${_getDistrictName()} ${_getCategoryName()} Ranking',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRankingList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4E8AD9),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF8D8D8D),
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8D8D8D),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRanking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4E8AD9),
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Color(0xFF8D8D8D),
            ),
            SizedBox(height: 16),
            Text(
              '등록된 장소가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return _buildRankingItem(index + 1, place);
      },
    );
  }

  Widget _buildRankingItem(int rank, PlaceModel place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 순위
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? const Color(0xFF4E8AD9).withOpacity(0.1)
                  : const Color(0xFFF8F6F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3
                      ? const Color(0xFF4E8AD9)
                      : const Color(0xFF8D8D8D),
                ),
              ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Color(0xFFFFB800),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(place.averageRating ?? place.rating).toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '리뷰 ${place.reviewCount}개',
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

          // ELO 점수 (rating을 ELO로 표시 - 실제로는 eloRating 필드를 사용해야 함)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(place.rating * 200 + 800).toInt()}', // 임시로 rating을 ELO 범위로 변환
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4E8AD9),
                ),
              ),
              const Text(
                'ELO',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8D8D8D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
