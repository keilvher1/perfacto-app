import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class LocationVerificationPage extends StatefulWidget {
  final String placeName;
  final String placeId;

  const LocationVerificationPage({
    super.key,
    required this.placeName,
    required this.placeId,
  });

  @override
  State<LocationVerificationPage> createState() =>
      _LocationVerificationPageState();
}

class _LocationVerificationPageState extends State<LocationVerificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isVerifying = true;
  bool _isLocaleInitialized = false;
  String _verificationMessage = 'GPS기반 위치 인증 중';
  bool _verificationSuccess = false;

  // 포항시 대략적인 경계 (위도, 경도)
  static const double _pohangMinLat = 35.9;
  static const double _pohangMaxLat = 36.2;
  static const double _pohangMinLng = 129.2;
  static const double _pohangMaxLng = 129.5;

  @override
  void initState() {
    super.initState();
    _initializeLocale();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 실제 위치 인증 실행
    _verifyLocation();
  }

  // 실제 GPS 기반 위치 인증
  Future<void> _verifyLocation() async {
    try {
      // 위치 권한 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isVerifying = false;
          _verificationSuccess = false;
          _verificationMessage = '위치 서비스가 비활성화되어 있습니다.';
        });
        _returnToReviewPage(false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isVerifying = false;
            _verificationSuccess = false;
            _verificationMessage = '위치 권한이 거부되었습니다.';
          });
          _returnToReviewPage(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isVerifying = false;
          _verificationSuccess = false;
          _verificationMessage = '위치 권한이 영구적으로 거부되었습니다.';
        });
        _returnToReviewPage(false);
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 포항 지역인지 확인
      bool isInPohang = _isInPohang(position.latitude, position.longitude);

      setState(() {
        _isVerifying = false;
        _verificationSuccess = isInPohang;
        _verificationMessage = isInPohang ? '위치 인증 완료!' : '포항 지역이 아닙니다.';
      });

      // 0.5초 후 결과와 함께 이전 페이지로 돌아가기
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context, isInPohang);
        }
      });
    } catch (e) {
      print('위치 인증 오류: $e');
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _verificationMessage = '위치 인증 중 오류가 발생했습니다.';
      });
      _returnToReviewPage(false);
    }
  }

  // 포항 지역 여부 확인
  bool _isInPohang(double latitude, double longitude) {
    return latitude >= _pohangMinLat &&
        latitude <= _pohangMaxLat &&
        longitude >= _pohangMinLng &&
        longitude <= _pohangMaxLng;
  }

  // 인증 실패 시 이전 페이지로 돌아가기
  void _returnToReviewPage(bool success) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, success);
      }
    });
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('ko_KR', null);
    if (mounted) {
      setState(() {
        _isLocaleInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getCurrentDateTime() {
    if (!_isLocaleInitialized) {
      final now = DateTime.now();
      return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}. ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyy.MM.dd. E HH:mm', 'ko_KR');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    '위치 인증하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // 장소명
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.placeName}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(
                    text: '에\n다녀오셨군요!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // 날짜 및 시간
            Text(
              _getCurrentDateTime(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8D8D8D),
              ),
            ),

            const SizedBox(height: 80),

            // GPS 인증 애니메이션
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 외부 회전 원
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * math.pi,
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4E8AD9).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 중간 원
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_animationController.value * 2 * math.pi,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4E8AD9).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 내부 원 (배경)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4E8AD9),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4E8AD9).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),

                  // 펄스 효과
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 160 + (_animationController.value * 40),
                        height: 160 + (_animationController.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF4E8AD9).withOpacity(
                              1 - _animationController.value,
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // 인증 상태 텍스트
            Text(
              _verificationMessage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _isVerifying
                    ? const Color(0xFF414141)
                    : (_verificationSuccess
                        ? const Color(0xFF4E8AD9)
                        : Colors.red),
              ),
            ),

            if (_isVerifying) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF4E8AD9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
