// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class PointRewardPage extends StatefulWidget {
//   final bool hasGpsVerification;
//   final int photoCount;
//   final bool hasReview;
//
//   const PointRewardPage({
//     super.key,
//     required this.hasGpsVerification,
//     required this.photoCount,
//     required this.hasReview,
//   });
//
//   @override
//   State<PointRewardPage> createState() => _PointRewardPageState();
// }
//
// class _PointRewardPageState extends State<PointRewardPage>
//     with TickerProviderStateMixin {
//   late AnimationController _coinRotationController;
//   late AnimationController _fadeController;
//
//   List<PointItem> _pointItems = [];
//   int _currentItemIndex = -1;
//   int _totalPoints = 0;
//   bool _showTotal = false;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // 코인 회전 애니메이션
//     _coinRotationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();
//
//     // 페이드 애니메이션
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//
//     // 포인트 항목 계산
//     _calculatePoints();
//
//     // 순차적으로 포인트 표시
//     _showPointsSequentially();
//   }
//
//   void _calculatePoints() {
//     _pointItems = [];
//
//     // GPS 인증
//     if (widget.hasGpsVerification) {
//       _pointItems.add(PointItem(
//         label: 'GPS 인증!',
//         points: 50,
//         icon: Icons.location_on,
//       ));
//     }
//
//     // 리뷰 작성
//     if (widget.hasReview) {
//       _pointItems.add(PointItem(
//         label: '리뷰 작성!',
//         points: 30,
//         icon: Icons.rate_review,
//       ));
//     }
//
//     // 사진 업로드 (사진 1장당 10점)
//     if (widget.photoCount > 0) {
//       _pointItems.add(PointItem(
//         label: '사진 업로드!',
//         points: widget.photoCount * 10,
//         icon: Icons.photo_camera,
//       ));
//     }
//
//     // 총 포인트 계산
//     _totalPoints = _pointItems.fold(0, (sum, item) => sum + item.points);
//   }
//
//   Future<void> _showPointsSequentially() async {
//     // 초기 대기
//     await Future.delayed(const Duration(milliseconds: 1000));
//
//     // 각 항목 순차적으로 표시
//     for (int i = 0; i < _pointItems.length; i++) {
//       setState(() {
//         _currentItemIndex = i;
//       });
//
//       _fadeController.forward(from: 0);
//       await Future.delayed(const Duration(milliseconds: 1500));
//     }
//
//     // 총 포인트 표시
//     await Future.delayed(const Duration(milliseconds: 500));
//     setState(() {
//       _showTotal = true;
//     });
//
//     // Firestore에 포인트 저장
//     await _savePointsToFirestore();
//   }
//
//   Future<void> _savePointsToFirestore() async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;
//
//       final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
//
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         final snapshot = await transaction.get(userRef);
//
//         int currentPoints = 0;
//         if (snapshot.exists) {
//           currentPoints = snapshot.data()?['points'] ?? 0;
//         }
//
//         transaction.set(
//           userRef,
//           {
//             'points': currentPoints + _totalPoints,
//             'lastUpdated': FieldValue.serverTimestamp(),
//           },
//           SetOptions(merge: true),
//         );
//       });
//     } catch (e) {
//       print('포인트 저장 오류: $e');
//     }
//   }
//
//   void _showGuidelineDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: const Text(
//           '포인트 획득 가이드',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildGuidelineItem('GPS 인증', '50P'),
//             const SizedBox(height: 12),
//             _buildGuidelineItem('리뷰 작성', '30P'),
//             const SizedBox(height: 12),
//             _buildGuidelineItem('사진 1장당', '10P'),
//             const SizedBox(height: 16),
//             const Text(
//               '포항 청결도 개선에 기여해주셔서 감사합니다!',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF8D8D8D),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               '확인',
//               style: TextStyle(
//                 color: Color(0xFF4E8AD9),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGuidelineItem(String label, String points) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(
//             fontSize: 14,
//             color: Color(0xFF414141),
//           ),
//         ),
//         Text(
//           points,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF4E8AD9),
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   void dispose() {
//     _coinRotationController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F6F0),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             // 메인 콘텐츠
//             Column(
//               children: [
//                 const SizedBox(height: 60),
//
//                 // 물음표 아이콘
//                 Align(
//                   alignment: Alignment.topRight,
//                   child: Padding(
//                     padding: const EdgeInsets.only(right: 24),
//                     child: IconButton(
//                       icon: const Icon(
//                         Icons.help_outline,
//                         size: 28,
//                         color: Color(0xFF8D8D8D),
//                       ),
//                       onPressed: _showGuidelineDialog,
//                     ),
//                   ),
//                 ),
//
//                 const Spacer(),
//
//                 // 코인 애니메이션
//                 RotationTransition(
//                   turns: _coinRotationController,
//                   child: SvgPicture.asset(
//                     'assets/icons/coin.svg',
//                     width: 120,
//                     height: 120,
//                   ),
//                 ),
//
//                 const SizedBox(height: 40),
//
//                 // 현재 항목 표시
//                 if (_currentItemIndex >= 0 && _currentItemIndex < _pointItems.length)
//                   FadeTransition(
//                     opacity: _fadeController,
//                     child: Column(
//                       children: [
//                         Icon(
//                           _pointItems[_currentItemIndex].icon,
//                           size: 48,
//                           color: const Color(0xFF4E8AD9),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           _pointItems[_currentItemIndex].label,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF414141),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           '+${_pointItems[_currentItemIndex].points}P!',
//                           style: const TextStyle(
//                             fontSize: 32,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF4E8AD9),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 // 총 포인트 표시
//                 if (_showTotal)
//                   Column(
//                     children: [
//                       const SizedBox(height: 40),
//                       const Text(
//                         '총 획득 포인트',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w500,
//                           color: Color(0xFF8D8D8D),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         '+$_totalPoints P',
//                         style: const TextStyle(
//                           fontSize: 48,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF4E8AD9),
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       const Text(
//                         '포항 청결도에 기여해주셔서 감사합니다!',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: Color(0xFF414141),
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//
//                 const Spacer(),
//                 const SizedBox(height: 60),
//               ],
//             ),
//
//             // X 버튼
//             Positioned(
//               top: 16,
//               left: 16,
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.close,
//                   size: 32,
//                   color: Color(0xFF414141),
//                 ),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class PointItem {
//   final String label;
//   final int points;
//   final IconData icon;
//
//   PointItem({
//     required this.label,
//     required this.points,
//     required this.icon,
//   });
// }
