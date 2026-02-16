import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pages/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/performance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firestore 오프라인 캐시 활성화
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Firebase Performance Monitoring 초기화
  await PerformanceService.initialize();

  // FCM 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM 초기화
  await FcmService.initialize();

  // Riverpod ProviderScope로 앱 감싸기
  runApp(
    const ProviderScope(
      child: PerfactoApp(),
    ),
  );
}

class PerfactoApp extends StatelessWidget {
  const PerfactoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perfacto',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
