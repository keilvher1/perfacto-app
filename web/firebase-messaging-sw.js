importScripts("https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js");

// Firebase 설정 (firebase_options.dart의 웹 설정과 동일해야 함)
firebase.initializeApp({
  apiKey: "AIzaSyBAanV6MxGlXWU26eSHHzMtSNC02K6w2wA",
  authDomain: "perfacto-7aa56.firebaseapp.com",
  projectId: "perfacto-7aa56",
  storageBucket: "perfacto-7aa56.firebasestorage.app",
  messagingSenderId: "773206486092",
  appId: "1:773206486092:web:15fce2f13d881d044ebeac",
  measurementId: "G-M2C2JE5H8H"
});

const messaging = firebase.messaging();

// 백그라운드 메시지 처리
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message received', payload);

  const notificationTitle = payload.notification?.title || 'Perfacto';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 처리
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked', event);

  event.notification.close();

  // 앱 열기
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // 이미 열려있는 창이 있으면 포커스
      for (const client of clientList) {
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      // 없으면 새 창 열기
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
