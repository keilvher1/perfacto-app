import 'package:flutter/material.dart';
import 'package:perfacto/services/auth_service.dart';
import 'package:perfacto/services/api_service.dart';
import 'login_page.dart';
import 'follow_list_page.dart';
import 'saved_places_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userProfile;
  int _followingCount = 0;
  int _followerCount = 0;
  int _reviewCount = 0;
  int _savedPlacesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final isLoggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    if (isLoggedIn) {
      try {
        // TODO: 실제 사용자 ID를 가져와야 함 (임시로 1 사용)
        final userId = 1; // AuthService에서 가져와야 함

        // 팔로잉/팔로워 수
        final following = await ApiService.getFollowing(userId);
        final followers = await ApiService.getFollowers(userId);

        // 내 리뷰 수
        final reviews = await ApiService.getUserReviews(userId);

        // 저장된 장소 수
        final savedPlaces = await ApiService.getSavedPlaces();

        setState(() {
          _followingCount = following.length;
          _followerCount = followers.length;
          _reviewCount = reviews.length;
          _savedPlacesCount = savedPlaces.length;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.signOut();
    setState(() {
      _isLoggedIn = false;
      _userProfile = null;
      _followingCount = 0;
      _followerCount = 0;
      _reviewCount = 0;
      _savedPlacesCount = 0;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4E8AD9)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: const Color(0xFF4E8AD9),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: 설정 페이지로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('설정 기능은 준비 중입니다')),
                );
              },
            ),
        ],
      ),
      body: _isLoggedIn ? _buildLoggedInView() : _buildLoggedOutView(),
    );
  }

  Widget _buildLoggedInView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),

          // 프로필 섹션
          _buildProfileSection(),

          const SizedBox(height: 24),

          // 통계 섹션
          _buildStatsSection(),

          const SizedBox(height: 16),

          // 메뉴 섹션
          _buildMenuSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFD9D9D9),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // 사용자 이름 (TODO: 실제 데이터)
          const Text(
            '사용자',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // 이메일 (TODO: 실제 데이터)
          const Text(
            'user@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8D8D8D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: '팔로잉',
            value: '$_followingCount',
            onTap: () {
              // TODO: 실제 사용자 ID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowListPage(
                    userId: 1,
                    initialTabIndex: 0,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFD9D9D9),
          ),
          _buildStatItem(
            label: '팔로워',
            value: '$_followerCount',
            onTap: () {
              // TODO: 실제 사용자 ID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowListPage(
                    userId: 1,
                    initialTabIndex: 1,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFD9D9D9),
          ),
          _buildStatItem(
            label: '리뷰',
            value: '$_reviewCount',
            onTap: () {
              // TODO: 내 리뷰 페이지로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('내 리뷰 페이지는 준비 중입니다')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E8AD9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8D8D8D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        children: [
          _buildMenuItem(
            icon: Icons.bookmark,
            title: '저장한 장소',
            subtitle: '$_savedPlacesCount개',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPlacesPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.rate_review,
            title: '내가 쓴 리뷰',
            subtitle: '$_reviewCount개',
            onTap: () {
              // TODO: 내 리뷰 페이지로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('내 리뷰 페이지는 준비 중입니다')),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: _handleLogout,
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4E8AD9)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8D8D8D),
              ),
            )
          : null,
      trailing: showArrow
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 80,
            color: Color(0xFFD9D9D9),
          ),
          const SizedBox(height: 24),
          const Text(
            '로그인이 필요합니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Perfacto의 다양한 기능을\n이용하려면 로그인해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8D8D8D),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
              if (result == true) {
                _loadData();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4E8AD9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              '로그인',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
