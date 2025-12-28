import 'package:flutter/material.dart';
import 'package:perfacto/services/api_service.dart';
import 'package:perfacto/pages/user_places_page.dart';

/// 친구 리스트 페이지 (카카오톡 스타일)
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> _following = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 사용자 ID로 변경
      final userId = 1;
      final following = await ApiService.getFollowing(userId);

      setState(() {
        _following = List<Map<String, dynamic>>.from(following);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ApiService.searchUsers(query.trim());
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 오류: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow(int userId, bool isFollowing) async {
    try {
      if (isFollowing) {
        await ApiService.unfollow(userId);
      } else {
        await ApiService.follow(userId);
      }

      // 목록 새로고침
      await _loadFollowing();

      // 검색 결과도 업데이트
      if (_isSearching && _searchController.text.isNotEmpty) {
        await _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
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
        title: const Text(
          '친구',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // 검색바
          _buildSearchBar(),

          // 친구 리스트 또는 검색 결과
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4E8AD9)),
                  )
                : _isSearching
                    ? _buildSearchResults()
                    : _buildFriendsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _searchUsers,
        decoration: InputDecoration(
          hintText: '친구 검색 (이름 또는 아이디)',
          hintStyle: const TextStyle(
            color: Color(0xFF8D8D8D),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8D8D8D)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF8D8D8D)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _searchResults = [];
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 16),
            const Text(
              '팔로잉이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8D8D8D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '검색으로 친구를 찾아보세요',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      color: const Color(0xFF4E8AD9),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final user = _following[index];
          return _buildUserCard(user, isFollowing: true);
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.trim().isNotEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8D8D8D),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isFollowing = _following.any((f) => f['id'] == user['id']);
        return _buildUserCard(user, isFollowing: isFollowing);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, {required bool isFollowing}) {
    final userId = user['id'] as int;
    final userName = user['nickName'] ?? user['name'] ?? 'Unknown';
    final profileImage = user['profileImageUrl'] as String?;

    return GestureDetector(
      onTap: () {
        // 친구의 장소 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserPlacesPage(
              userId: userId,
              userName: userName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFD9D9D9),
              backgroundImage: profileImage != null && profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage == null || profileImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user['followerCount'] != null)
                    Text(
                      '팔로워 ${user['followerCount']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                ],
              ),
            ),

            // 팔로우 버튼
            ElevatedButton(
              onPressed: () => _toggleFollow(userId, isFollowing),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? const Color(0xFFD9D9D9)
                    : const Color(0xFF4E8AD9),
                foregroundColor: isFollowing ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                isFollowing ? '팔로잉' : '팔로우',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
