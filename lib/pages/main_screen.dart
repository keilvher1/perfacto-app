import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_page.dart';
import 'friends_page.dart';
import 'ranking_page.dart';
import 'my_page.dart';

class MainScreen extends StatefulWidget {
  final bool showLocationDialog;

  const MainScreen({super.key, this.showLocationDialog = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const FriendsPage(),
    const RankingPage(),
    const MyPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 로그인 후 팝업 표시
    if (widget.showLocationDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLocationDialog();
      });
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xB21B1B1B),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFF8F6F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: 380,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '지금 포항을 어떻게 즐기고 계신가요?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '간단한 Local 위치인증을 하면 \n한 달 동안 ',
                        style: TextStyle(
                          color: Color(0xFF1B1B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.46,
                        ),
                      ),
                      TextSpan(
                        text: '리뷰 포인트가 2배',
                        style: TextStyle(
                          color: Color(0xFF4E8AD9),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.46,
                        ),
                      ),
                      TextSpan(
                        text: '로 적립돼요',
                        style: TextStyle(
                          color: Color(0xFF1B1B1B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.46,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Local 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          // Local 선택 완료
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4D8F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '포항에서 생활 중\nLocal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1B1B1B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.41,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Travel 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          // Travel 선택 완료
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC4D8F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '포항에서 여행 중\nTravel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1B1B1B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.41,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4E8AD9),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/home.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 0 ? const Color(0xFF4E8AD9) : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/hot.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 1 ? const Color(0xFF4E8AD9) : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              label: 'HOT',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/coin.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  _currentIndex == 2 ? const Color(0xFF4E8AD9) : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              label: 'POINT',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/fish.svg',
                width: 24,
                height: 24,
                color: _currentIndex == 3
                    ? const Color(0xFF4E8AD9)
                    : Colors.grey,
              ),
              label: 'MY',
            ),
          ],
        ),
      ),
    );
  }
}
