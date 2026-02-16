import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../services/firestore_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _globalLeaderboard = [];
  List<LeaderboardEntry> _cityLeaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        FirestoreService.getGlobalLeaderboard(),
        FirestoreService.getCityLeaderboard('포항'),
      ]);

      setState(() {
        _globalLeaderboard = results[0];
        _cityLeaderboard = results[1];
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
      appBar: AppBar(
        title: const Text('리더보드'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌍 '),
                  Text('전체'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📍 '),
                  Text('포항'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList(_globalLeaderboard),
                    _buildLeaderboardList(_cityLeaderboard),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '리더보드를 불러올 수 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadLeaderboards,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '아직 순위 정보가 없습니다',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        itemCount: entries.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _LeaderboardTile(entry: entry);
        },
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: _buildRankBadge(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.nickname,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.hasRankChange) _buildRankChange(),
          ],
        ),
        subtitle: Text(
          '리뷰 ${entry.reviewCount}개 · 🔥 ${entry.currentStreak}일',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          '${entry.totalPoints}P',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    Color bgColor;
    Color textColor;

    switch (entry.rank) {
      case 1:
        bgColor = Colors.amber;
        textColor = Colors.white;
        break;
      case 2:
        bgColor = Colors.grey[400]!;
        textColor = Colors.white;
        break;
      case 3:
        bgColor = Colors.brown[300]!;
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.black87;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${entry.rank}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRankChange() {
    final isUp = entry.isRankUp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUp ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: isUp ? Colors.green : Colors.red,
          ),
          Text(
            '${entry.rankChange!.abs()}',
            style: TextStyle(
              fontSize: 11,
              color: isUp ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
