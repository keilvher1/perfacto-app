import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// 팔로잉/팔로워 목록 페이지
class FollowListPage extends StatefulWidget {
  final int userId;
  final int initialTabIndex; // 0: 팔로잉, 1: 팔로워

  const FollowListPage({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _following = [];
  List<dynamic> _followers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
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
      final following = await ApiService.getFollowing(widget.userId);
      final followers = await ApiService.getFollowers(widget.userId);

      setState(() {
        _following = following;
        _followers = followers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(int targetUserId, bool isCurrentlyFollowing) async {
    try {
      if (isCurrentlyFollowing) {
        await ApiService.unfollow(targetUserId);
      } else {
        await ApiService.follow(targetUserId);
      }

      // 데이터 새로고침
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyFollowing ? '언팔로우했습니다' : '팔로우했습니다'),
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
          '팔로우',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
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
            Tab(text: '팔로잉 ${_following.length}'),
            Tab(text: '팔로워 ${_followers.length}'),
          ],
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
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFollowList(_following, isFollowingTab: true),
                    _buildFollowList(_followers, isFollowingTab: false),
                  ],
                ),
    );
  }

  Widget _buildFollowList(List<dynamic> users, {required bool isFollowingTab}) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowingTab ? Icons.person_add_outlined : Icons.people_outline,
              size: 64,
              color: const Color(0xFFD9D9D9),
            ),
            const SizedBox(height: 16),
            Text(
              isFollowingTab ? '팔로잉한 사용자가 없습니다' : '팔로워가 없습니다',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(user, isFollowingTab);
      },
    );
  }

  Widget _buildUserCard(dynamic user, bool isFollowingTab) {
    final userId = user['id'] as int;
    final nickname = user['nickname'] as String? ?? '사용자';
    final profileImage = user['profileImage'] as String?;
    final isFollowing = user['isFollowing'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // 프로필 이미지
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFD9D9D9),
            backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
            child: profileImage == null
                ? Text(
                    nickname.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (user['reviewCount'] != null)
                  Text(
                    '리뷰 ${user['reviewCount']}개',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D8D8D),
                    ),
                  ),
              ],
            ),
          ),

          // 팔로우 버튼
          GestureDetector(
            onTap: () => _toggleFollow(userId, isFollowing),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isFollowing
                    ? Colors.white
                    : const Color(0xFF4E8AD9),
                border: Border.all(
                  color: isFollowing
                      ? const Color(0xFFD9D9D9)
                      : const Color(0xFF4E8AD9),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFollowing ? '팔로잉' : '팔로우',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isFollowing
                      ? const Color(0xFF8D8D8D)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
