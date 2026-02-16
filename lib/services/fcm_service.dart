import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

/// FCM(Firebase Cloud Messaging) 서비스
/// 푸시 알림 및 메시징 기능 관리
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static String? _fcmToken;

  /// FCM 토큰 getter
  static String? get fcmToken => _fcmToken;

  /// FCM 초기화
  static Future<void> initialize() async {
    try {
      print('🔔 FCM 초기화 시작...');

      // 알림 권한 요청 (iOS)
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ 알림 권한 허용됨');

        // 로컬 알림 초기화
        await _initializeLocalNotifications();

        // FCM 토큰 가져오기
        await _getAndSaveFcmToken();

        // 토큰 갱신 리스너
        _messaging.onTokenRefresh.listen(_saveFcmToken);

        // 포그라운드 메시지 처리
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 백그라운드 메시지 처리
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

        // 앱이 종료된 상태에서 알림을 통해 열린 경우
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessage(initialMessage);
        }

        print('✅ FCM 초기화 완료');
      } else {
        print('⚠️ 알림 권한 거부됨');
      }
    } catch (e) {
      print('❌ FCM 초기화 실패: $e');
    }
  }

  /// 알림 권한 요청
  static Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings;
  }

  /// 로컬 알림 초기화
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'perfacto_notifications', // ID
      'Perfacto 알림', // 이름
      description: 'Perfacto 앱의 알림을 표시합니다',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// FCM 토큰 가져오기 및 저장
  static Future<void> _getAndSaveFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        await _saveFcmToken(token);
      }
    } catch (e) {
      print('❌ FCM 토큰 가져오기 실패: $e');
    }
  }

  /// FCM 토큰을 Firestore에 저장
  static Future<void> _saveFcmToken(String token) async {
    try {
      _fcmToken = token;
      final userId = FirestoreService.currentUserId;

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ FCM 토큰 저장: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ FCM 토큰 저장 실패: $e');
    }
  }

  /// 포그라운드 메시지 처리
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 포그라운드 메시지 수신: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // 로컬 알림 표시
      await _showLocalNotification(
        title: notification.title ?? 'Perfacto',
        body: notification.body ?? '',
        payload: data.toString(),
      );
    }
  }

  /// 백그라운드 메시지 처리 (앱이 백그라운드에서 열린 경우)
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📭 백그라운드 메시지 처리: ${message.messageId}');

    final data = message.data;

    // 메시지 데이터에 따라 특정 화면으로 이동
    // 예: {'type': 'review', 'placeId': '123'} -> 장소 상세 페이지로 이동
    // 구현은 앱의 라우팅 구조에 따라 조정 필요

    print('메시지 데이터: $data');
  }

  /// 로컬 알림 표시
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'perfacto_notifications',
      'Perfacto 알림',
      channelDescription: 'Perfacto 앱의 알림을 표시합니다',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// 알림 탭 시 처리
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 알림 탭됨: ${response.payload}');

    // 알림 탭 시 특정 화면으로 이동
    // 구현은 앱의 라우팅 구조에 따라 조정 필요
  }

  /// 특정 주제 구독
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ 주제 구독: $topic');
    } catch (e) {
      print('❌ 주제 구독 실패: $e');
    }
  }

  /// 특정 주제 구독 해제
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ 주제 구독 해제: $topic');
    } catch (e) {
      print('❌ 주제 구독 해제 실패: $e');
    }
  }

  /// FCM 토큰 삭제
  static Future<void> deleteFcmToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM 토큰 삭제');
    } catch (e) {
      print('❌ FCM 토큰 삭제 실패: $e');
    }
  }
}

/// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📥 백그라운드 메시지 수신: ${message.messageId}');
  // 백그라운드에서 메시지를 처리할 로직
}
