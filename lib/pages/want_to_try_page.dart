import 'package:flutter/material.dart';
import 'package:perfacto/services/firestore_service.dart';
import 'package:perfacto/services/sns_integration_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Want to Try (가보고 싶은 곳) 페이지
class WantToTryPage extends StatefulWidget {
  const WantToTryPage({super.key});

  @override
  State<WantToTryPage> createState() => _WantToTryPageState();
}

class _WantToTryPageState extends State<WantToTryPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await FirestoreService.getWantToTryList();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddWantToTryDialog(),
    );

    if (result != null) {
      try {
        await SnsIntegrationService.addToWantToTry(
          placeName: result['placeName']!,
          address: result['address'],
          sourceUrl: result['sourceUrl']!,
          sourcePlatform: result['sourcePlatform']!,
          notes: result['notes'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가보고 싶은 곳에 추가했습니다'),
              backgroundColor: Color(0xFF4E8AD9),
            ),
          );
          _loadItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('추가 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeItem(String itemId, String placeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: Text('$placeName을(를) 삭제하시겠습니까?'),
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
        await FirestoreService.removeFromWantToTry(itemId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제되었습니다')),
          );
          _loadItems();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsVisited(String itemId, String placeName) async {
    try {
      await FirestoreService.markAsVisited(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$placeName 방문 완료!')),
        );
        _loadItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('업데이트 실패: $e'),
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
          '가보고 싶은 곳',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showAddDialog,
          ),
        ],
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
                        onPressed: _loadItems,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.explore_outlined,
                            size: 64,
                            color: Color(0xFFD9D9D9),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '가보고 싶은 곳이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'SNS에서 발견한 장소를 추가해보세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8D8D8D),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('추가하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4E8AD9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadItems,
                      color: const Color(0xFF4E8AD9),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return _buildItemCard(_items[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isVisited = item['isVisited'] as bool? ?? false;
    final placeName = item['placeName'] as String;
    final address = item['address'] as String?;
    final sourceUrl = item['sourceUrl'] as String;
    final sourcePlatform = item['sourcePlatform'] as String;
    final notes = item['notes'] as String?;
    final itemId = item['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVisited ? const Color(0xFFF0F0F0) : Colors.white,
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
          // 헤더
          Row(
            children: [
              // 플랫폼 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sourcePlatform == 'instagram'
                      ? Colors.pink.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  sourcePlatform == 'instagram'
                      ? Icons.camera_alt
                      : Icons.music_note,
                  size: 20,
                  color: sourcePlatform == 'instagram'
                      ? Colors.pink
                      : Colors.black,
                ),
              ),
              const SizedBox(width: 12),

              // 장소 이름
              Expanded(
                child: Text(
                  placeName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    decoration: isVisited ? TextDecoration.lineThrough : null,
                    color: isVisited ? const Color(0xFF8D8D8D) : Colors.black,
                  ),
                ),
              ),

              // 방문 완료 체크
              if (isVisited)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4E8AD9),
                  size: 24,
                ),
            ],
          ),

          if (address != null) ...[
            const SizedBox(height: 8),
            Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ],

          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                notes,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8D8D8D),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 액션 버튼들
          Row(
            children: [
              // SNS 링크
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(sourceUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('원본 보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4E8AD9),
                    side: const BorderSide(color: Color(0xFF4E8AD9)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 방문 완료/취소
              if (!isVisited)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsVisited(itemId, placeName),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('방문 완료'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E8AD9),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // 삭제
              IconButton(
                onPressed: () => _removeItem(itemId, placeName),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 추가 다이얼로그
class _AddWantToTryDialog extends StatefulWidget {
  const _AddWantToTryDialog();

  @override
  State<_AddWantToTryDialog> createState() => _AddWantToTryDialogState();
}

class _AddWantToTryDialogState extends State<_AddWantToTryDialog> {
  final _placeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  String? _detectedPlatform;

  @override
  void dispose() {
    _placeNameController.dispose();
    _addressController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _detectPlatform() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      final platform = SnsIntegrationService.detectPlatform(url);
      setState(() {
        _detectedPlatform = platform;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('가보고 싶은 곳 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL 입력
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'SNS URL *',
                hintText: 'Instagram 또는 TikTok 링크',
                border: const OutlineInputBorder(),
                suffixIcon: _detectedPlatform != null
                    ? Icon(
                        _detectedPlatform == 'instagram'
                            ? Icons.camera_alt
                            : Icons.music_note,
                        color: _detectedPlatform == 'instagram'
                            ? Colors.pink
                            : Colors.black,
                      )
                    : null,
              ),
              onChanged: (value) => _detectPlatform(),
            ),
            const SizedBox(height: 16),

            // 장소 이름
            TextField(
              controller: _placeNameController,
              decoration: const InputDecoration(
                labelText: '장소 이름 *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 주소
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '주소 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 메모
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                hintText: '메뉴 추천, 방문 시간 등',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final url = _urlController.text.trim();
            final placeName = _placeNameController.text.trim();

            if (url.isEmpty || placeName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL과 장소 이름은 필수입니다'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (_detectedPlatform == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('지원하지 않는 SNS 플랫폼입니다'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'placeName': placeName,
              'address': _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
              'sourceUrl': url,
              'sourcePlatform': _detectedPlatform!,
              'notes': _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4E8AD9),
            foregroundColor: Colors.white,
          ),
          child: const Text('추가'),
        ),
      ],
    );
  }
}
