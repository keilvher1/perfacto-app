import 'package:flutter/material.dart';
import 'package:perfacto/services/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    // 입력값 검증
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('이메일을 입력해주세요.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('이름을 입력해주세요.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('비밀번호를 입력해주세요.');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showErrorDialog('비밀번호는 최소 6자 이상이어야 합니다.');
      return;
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      _showErrorDialog('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 백엔드 API로 회원가입
      await AuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nameController.text.trim(),
      );

      if (mounted) {
        // 회원가입 성공 - 로그인 페이지로 돌아가기
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
            backgroundColor: Color(0xFF4E8AD9),
          ),
        );
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
                const SizedBox(height: 30),
                // 회원가입 타이틀
                const Text(
                  '회원가입',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 50),
                // 이름 입력 필드
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '이름을 입력하세요',
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
                      hintText: '비밀번호를 입력하세요 (최소 6자)',
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
                const SizedBox(height: 10),
                // 비밀번호 확인 입력 필드
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
                    controller: _passwordConfirmController,
                    obscureText: _obscurePasswordConfirm,
                    decoration: InputDecoration(
                      hintText: '비밀번호를 다시 입력하세요',
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
                          _obscurePasswordConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF8D8D8D),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePasswordConfirm = !_obscurePasswordConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // 회원가입 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
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
                          '회원가입',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
