# 패키지명 변경 완료 가이드

## 변경 내용

**이전 패키지명**: `com.example.perfacto`
**새 패키지명**: `com.lvher.perfacto`

---

## ✅ 완료된 작업

### 1. Android 패키지명 변경
- ✅ `android/app/build.gradle.kts`
  - `namespace = "com.lvher.perfacto"`
  - `applicationId = "com.lvher.perfacto"`
- ✅ Kotlin 소스 파일 이동 및 패키지 변경
  - `android/app/src/main/kotlin/com/lvher/perfacto/MainActivity.kt`
- ✅ `AndroidManifest.xml` (변경 불필요 - namespace 자동 사용)

### 2. iOS 번들 ID 변경
- ✅ `ios/Runner.xcodeproj/project.pbxproj`
  - `PRODUCT_BUNDLE_IDENTIFIER = com.lvher.perfacto`
  - `PRODUCT_BUNDLE_IDENTIFIER = com.lvher.perfacto.RunnerTests`

### 3. macOS 번들 ID 변경
- ✅ `macos/Runner.xcodeproj/project.pbxproj`
  - `PRODUCT_BUNDLE_IDENTIFIER = com.lvher.perfacto`

### 4. Firebase 설정 업데이트
- ✅ `lib/firebase_options.dart`
  - iOS: `iosBundleId: 'com.lvher.perfacto'`
  - macOS: `iosBundleId: 'com.lvher.perfacto'`

---

## ⚠️ Firebase Console 재설정 필요

패키지명이 변경되었으므로 Firebase Console에서 앱을 **재등록**해야 합니다.

### 방법 1: FlutterFire CLI 사용 (권장)

```bash
# 프로젝트 루트에서 실행
flutterfire configure
```

이 명령이 자동으로 다음 작업을 수행합니다:
1. Firebase Console에 새 패키지명으로 앱 등록
2. `google-services.json` (Android) 다운로드 및 배치
3. `GoogleService-Info.plist` (iOS/macOS) 다운로드 및 배치
4. `firebase_options.dart` 재생성

### 방법 2: Firebase Console에서 수동 등록

Firebase Console에서 기존 앱을 삭제하고 새로 등록하세요:

#### Android 앱 재등록
1. [Firebase Console](https://console.firebase.google.com/project/perfacto-7aa56) 접속
2. 기존 Android 앱 삭제 (또는 새 앱 추가)
3. **Android 패키지명**: `com.lvher.perfacto` 입력
4. `google-services.json` 다운로드
5. 파일을 `android/app/google-services.json`에 덮어쓰기

#### iOS 앱 재등록
1. Firebase Console에서 기존 iOS 앱 삭제 (또는 새 앱 추가)
2. **iOS 번들 ID**: `com.lvher.perfacto` 입력
3. `GoogleService-Info.plist` 다운로드
4. 파일을 `ios/Runner/GoogleService-Info.plist`에 덮어쓰기

#### macOS 앱 재등록
1. Firebase Console에서 기존 macOS 앱 삭제 (또는 새 앱 추가)
2. **macOS 번들 ID**: `com.lvher.perfacto` 입력
3. `GoogleService-Info.plist` 다운로드
4. 파일을 `macos/Runner/GoogleService-Info.plist`에 덮어쓰기

---

## 🔧 빌드 클린 및 재빌드

패키지명 변경 후 반드시 클린 빌드를 수행하세요:

```bash
# Flutter 클린
flutter clean

# 의존성 재설치
flutter pub get

# Android 빌드 (선택)
cd android
./gradlew clean
cd ..

# 앱 실행
flutter run
```

---

## 📱 Google Play Console 설정 (출시 시)

Google Play Console에서 앱을 출시할 때:

1. **패키지명**: `com.lvher.perfacto` 사용
2. 패키지명은 한 번 등록하면 **변경 불가**하므로 주의
3. 앱 서명 키 설정 필요

---

## 🍎 App Store Connect 설정 (출시 시)

App Store Connect에서 앱을 출시할 때:

1. **번들 ID**: `com.lvher.perfacto` 사용
2. Xcode에서 Provisioning Profile 및 서명 인증서 설정 필요
3. Info.plist에서 앱 정보 확인

---

## ✅ 확인 사항

패키지명 변경 후 다음 사항들을 확인하세요:

- [ ] Firebase Console에서 새 패키지명으로 앱 재등록 완료
- [ ] `google-services.json` 파일 업데이트 완료
- [ ] `GoogleService-Info.plist` 파일 업데이트 완료
- [ ] `flutter clean && flutter pub get` 실행
- [ ] Android 빌드 성공 확인
- [ ] iOS 빌드 성공 확인 (Mac 필요)
- [ ] Firebase Authentication 로그인 테스트
- [ ] Firebase Firestore 읽기/쓰기 테스트
- [ ] 푸시 알림 설정 (필요 시)

---

## 🚨 주의사항

1. **패키지명 변경 후에는 기존 앱과 호환되지 않습니다**
   - 기존 사용자 데이터는 유지되지 않음
   - 새 앱으로 인식됨

2. **Firebase 프로젝트 데이터는 그대로 유지됩니다**
   - Authentication 사용자 데이터
   - Firestore 데이터베이스
   - Storage 파일들

3. **Play Store/App Store 출시 시**
   - 패키지명은 출시 후 변경 불가
   - 신중하게 결정하세요

---

**변경 완료일**: 2026-02-05
**새 패키지명**: `com.lvher.perfacto`
