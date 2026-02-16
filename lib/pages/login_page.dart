import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'signup_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _keepLoggedIn = false;
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // 입력값 검증
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('이메일을 입력해주세요.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Riverpod Provider로 로그인
      await ref.read(authNotifierProvider.notifier).signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // 로그인 성공 - 이전 화면으로 돌아가기
        Navigator.pop(context, true); // true를 전달하여 로그인 성공 알림
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  bool _isApplePlatform() {
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await ref.read(authNotifierProvider.notifier).signInWithApple();
      if (user != null && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSocialLoginButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(
            color: borderColor ?? backgroundColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 50),
                // Login 타이틀
                const Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 80),
                // 이메일 입력 필드
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F0),
                    border: Border.all(
                      color: const Color(0xFF8D8D8D),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: '이메일을 입력하세요',
                      hintStyle: TextStyle(
                        color: Color(0xFF8D8D8D),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 23,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 비밀번호 입력 필드
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F0),
                    border: Border.all(
                      color: const Color(0xFF8D8D8D),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 입력하세요',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8D8D8D),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 23,
                        vertical: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF8D8D8D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // 로그인 유지 & 비밀번호 찾기
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _keepLoggedIn = !_keepLoggedIn;
                            });
                          },
                          child: Container(
                            width: 23,
                            height: 23,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF8D8D8D),
                                width: 0.5,
                              ),
                              color: _keepLoggedIn
                                  ? const Color(0xFF4E8AD9)
                                  : Colors.transparent,
                            ),
                            child: _keepLoggedIn
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '로그인 유지',
                          style: TextStyle(
                            color: Color(0xFF1B1B1B),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: 비밀번호 찾기 기능 구현
                        _showErrorDialog('비밀번호 찾기 기능은 준비 중입니다.');
                      },
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(
                          color: Color(0xFF4E8AD9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 로그인 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E8AD9),
                    foregroundColor: const Color(0xFFF8F6F0),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF8D8D8D),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                // 구분선
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF8D8D8D).withOpacity(0.5),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or',
                        style: TextStyle(
                          color: Color(0xFF8D8D8D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: const Color(0xFF8D8D8D).withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // 소셜 로그인 버튼들
                _buildSocialLoginButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Icons.g_mobiledata,
                  label: 'Google로 계속하기',
                  backgroundColor: Colors.white,
                  textColor: Colors.black87,
                  borderColor: const Color(0xFF8D8D8D),
                ),
                const SizedBox(height: 12),
                // Apple 로그인 (iOS와 Web에서만 표시)
                if (kIsWeb || _isApplePlatform())
                  _buildSocialLoginButton(
                    onPressed: _isLoading ? null : _signInWithApple,
                    icon: Icons.apple,
                    label: 'Apple로 계속하기',
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                  ),
                const SizedBox(height: 30),
                // 회원가입 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계정이 없으신가요?  ',
                      style: TextStyle(
                        color: Color(0xFF8D8D8D),
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          color: Color(0xFF4E8AD9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
