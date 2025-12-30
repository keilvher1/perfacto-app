import 'package:flutter/material.dart';
import 'package:perfacto/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationEnabled = true;
  bool _locationEnabled = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFF4E8AD9),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 알림 설정
          _buildSectionHeader('알림 설정'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: '푸시 알림',
            subtitle: '새로운 리뷰, 팔로우 등의 알림을 받습니다',
            value: _notificationEnabled,
            onChanged: (value) {
              setState(() {
                _notificationEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? '알림이 활성화되었습니다' : '알림이 비활성화되었습니다',
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // 위치 설정
          _buildSectionHeader('위치 설정'),
          _buildSwitchTile(
            icon: Icons.location_on,
            title: '위치 서비스',
            subtitle: '내 위치 기반 장소 추천을 받습니다',
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? '위치 서비스가 활성화되었습니다' : '위치 서비스가 비활성화되었습니다',
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1),

          // 계정 설정
          _buildSectionHeader('계정 설정'),
          _buildMenuTile(
            icon: Icons.person,
            title: '프로필 관리',
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('프로필 관리는 마이페이지에서 가능합니다')),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.lock,
            title: '비밀번호 변경',
            onTap: () {
              _showPasswordChangeDialog();
            },
          ),
          _buildMenuTile(
            icon: Icons.delete_forever,
            title: '계정 삭제',
            titleColor: Colors.red,
            onTap: () {
              _showDeleteAccountDialog();
            },
          ),

          const Divider(height: 1),

          // 앱 정보
          _buildSectionHeader('앱 정보'),
          _buildMenuTile(
            icon: Icons.info,
            title: '버전 정보',
            trailing: Text(
              _appVersion,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8D8D8D),
              ),
            ),
          ),
          _buildMenuTile(
            icon: Icons.description,
            title: '이용약관',
            onTap: () {
              _showTermsDialog();
            },
          ),
          _buildMenuTile(
            icon: Icons.privacy_tip,
            title: '개인정보 처리방침',
            onTap: () {
              _showPrivacyDialog();
            },
          ),
          _buildMenuTile(
            icon: Icons.help,
            title: '도움말',
            onTap: () {
              _showHelpDialog();
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8D8D8D),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF4E8AD9)),
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
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4E8AD9),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? const Color(0xFF4E8AD9)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: const Text(
          '소셜 로그인 사용자는 비밀번호 변경이 불가능합니다.\n\n'
          '카카오, 구글, 애플 계정 설정에서 비밀번호를 변경해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text(
          '정말로 계정을 삭제하시겠습니까?\n\n'
          '모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: 계정 삭제 API 호출
              await AuthService.signOut();
              if (mounted) {
                Navigator.pop(context, true); // 설정 페이지 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('계정이 삭제되었습니다')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이용약관'),
        content: const SingleChildScrollView(
          child: Text(
            '제1조 (목적)\n'
            '본 약관은 Perfacto(이하 "회사")가 제공하는 서비스의 이용조건 및 절차에 관한 사항을 규정함을 목적으로 합니다.\n\n'
            '제2조 (용어의 정의)\n'
            '1. "서비스"란 회사가 제공하는 장소 기반 리뷰 플랫폼을 의미합니다.\n'
            '2. "회원"이란 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.\n\n'
            '제3조 (약관의 효력 및 변경)\n'
            '본 약관은 서비스를 이용하고자 하는 모든 회원에 대하여 그 효력을 발생합니다.\n\n'
            '제4조 (서비스의 제공)\n'
            '회사는 다음과 같은 서비스를 제공합니다:\n'
            '- 장소 정보 제공\n'
            '- 리뷰 작성 및 공유\n'
            '- 사용자 간 소셜 기능\n\n'
            '(이하 생략)',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            'Perfacto 개인정보 처리방침\n\n'
            '1. 수집하는 개인정보 항목\n'
            '- 필수: 이메일, 닉네임\n'
            '- 선택: 프로필 사진, 위치 정보\n\n'
            '2. 개인정보의 수집 및 이용 목적\n'
            '- 회원 관리 및 서비스 제공\n'
            '- 맞춤형 콘텐츠 제공\n'
            '- 서비스 개선 및 통계 분석\n\n'
            '3. 개인정보의 보유 및 이용 기간\n'
            '- 회원 탈퇴 시까지\n'
            '- 관계 법령에 따라 보존 필요 시 해당 기간\n\n'
            '4. 개인정보의 제3자 제공\n'
            '- 원칙적으로 제공하지 않음\n'
            '- 법령에 의한 경우 예외\n\n'
            '5. 이용자의 권리\n'
            '- 개인정보 열람, 수정, 삭제 요청 가능\n\n'
            '(이하 생략)',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Q. 리뷰는 어떻게 작성하나요?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('A. 장소 상세 페이지에서 "리뷰 작성" 버튼을 눌러 작성할 수 있습니다.'),
              SizedBox(height: 16),
              Text(
                'Q. 장소를 저장하려면?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('A. 장소 상세 페이지에서 북마크 아이콘을 탭하면 저장됩니다.'),
              SizedBox(height: 16),
              Text(
                'Q. 다른 사용자를 팔로우하려면?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('A. 리뷰 작성자의 프로필을 클릭하여 팔로우할 수 있습니다.'),
              SizedBox(height: 16),
              Text(
                'Q. 문의사항이 있어요',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('A. support@perfacto.com으로 문의해주세요.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
