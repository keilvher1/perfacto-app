# Perfacto 소셜 로그인 설정 가이드

## 📋 개요

이 가이드는 Perfacto 앱에 Google/Apple 소셜 로그인을 활성화하기 위해 필요한 콘솔 설정을 안내합니다.

### 현재 프로젝트 정보

| 항목 | 값 |
|------|-----|
| **Firebase Project ID** | `perfacto-7aa56` |
| **iOS Bundle ID** | `com.lvher.perfacto` ⚠️ 변경됨! |
| **Services ID (웹용)** | `com.lvher.perfacto.service` |
| **Auth Domain** | `perfacto-7aa56.firebaseapp.com` |

---

## ⚠️ 중요: Bundle ID 변경 작업

Bundle ID가 `com.example.perfacto` → `com.lvher.perfacto`로 변경되었습니다.
아래 작업들을 **반드시 먼저** 진행해주세요:

### Firebase Console에서 iOS 앱 재등록

1. **Firebase Console → 프로젝트 설정 → 일반**
2. **iOS 앱** 섹션에서 기존 `com.example.perfacto` 앱 삭제 (또는 유지)
3. **"앱 추가" → iOS** 클릭
4. **Bundle ID**: `com.lvher.perfacto` 입력
5. **앱 등록** 완료
6. **GoogleService-Info.plist 다운로드** → `ios/Runner/` 폴더에 교체

### Apple Developer에서 App ID 생성

1. **Apple Developer → Identifiers → App IDs**
2. **"+" 클릭** → App IDs 선택
3. **Bundle ID**: `com.lvher.perfacto` 입력
4. **Capabilities**에서 "Sign In with Apple" 체크
5. **Continue → Register**

---

## 🔥 1. Firebase Console 설정

### Firebase Console 링크
https://console.firebase.google.com/u/0/project/perfacto-7aa56/authentication/users

### 1.1 Google 로그인 활성화

1. **Authentication → Sign-in method → Google** 클릭
2. **"사용 설정" 토글 활성화**
3. **프로젝트 공개용 이름** 입력 (예: Perfacto)
4. **프로젝트 지원 이메일** 선택
5. **저장** 클릭

> ✅ Google 로그인은 Firebase Console 설정만으로 Web과 Android에서 바로 작동합니다.

### 1.2 iOS용 Google 로그인 추가 설정

1. **Firebase Console → 프로젝트 설정 → 일반**으로 이동
2. **iOS 앱** 섹션에서 `GoogleService-Info.plist` 다시 다운로드
3. **REVERSED_CLIENT_ID** 값 확인 (형식: `com.googleusercontent.apps.xxxxx`)
4. Xcode에서 **ios/Runner/Info.plist** 열기
5. 아래 코드를 `<dict>` 안에 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>여기에_REVERSED_CLIENT_ID_입력</string>
        </array>
    </dict>
</array>
```

### 1.3 Apple 로그인 활성화

1. **Authentication → Sign-in method → Apple** 클릭
2. **"사용 설정" 토글 활성화**
3. **서비스 ID** 입력: `com.lvher.perfacto.service` (Apple Developer에서 생성)

### 1.4 Apple 로그인 - OAuth 코드 흐름 구성 (⚠️ 웹 필수!)

> 🚨 **중요**: 이 설정이 없으면 웹에서 Apple 로그인 팝업이 즉시 닫힙니다!

"OAuth 코드 흐름 구성(선택사항)" 섹션을 펼치고:

| 필드 | 값 |
|------|-----|
| **Apple 팀 ID** | Apple Developer 계정의 Team ID (10자리) |
| **키 ID** | Sign in with Apple 키의 Key ID (10자리) |
| **비공개 키** | `.p8` 파일 내용 전체 (`-----BEGIN/END PRIVATE KEY-----` 포함) |

---

## 🍎 2. Apple Developer 설정

### Apple Developer 링크
https://developer.apple.com/account/resources/identifiers/list

### 2.1 App ID 설정

1. **Identifiers → App IDs** 에서 `com.example.perfacto` 선택
2. **Capabilities** 섹션에서 **"Sign In with Apple" 체크**
3. **Edit** 버튼 클릭 → **"Enable as a primary App ID"** 선택
4. **Save** 클릭

### 2.2 Services ID 생성 (웹용)

1. **Identifiers → 우측 상단 "+"** 클릭
2. **"Services IDs"** 선택 → Continue
3. **Description**: `Perfacto Service`
4. **Identifier**: `com.lvher.perfacto.service`
5. **Continue → Register**

### 2.3 Services ID - Website URLs 설정 (⚠️ 매우 중요!)

1. 생성된 Services ID 클릭
2. **"Sign In with Apple" 체크박스 활성화**
3. **Configure** 버튼 클릭
4. **Primary App ID**: `com.lvher.perfacto` 선택
5. **Domains and Subdomains**에 추가:
   - `perfacto-7aa56.firebaseapp.com`
   - `perfacto-7aa56.web.app`
6. **Return URLs**에 추가:
   - `https://perfacto-7aa56.firebaseapp.com/__/auth/handler`
7. **Next → Done → Continue → Save**

> 🚨 **핵심 주의**: URL 추가 후 각 URL의 **체크박스를 클릭하여 선택 상태**로 만들어야 합니다!

### 2.4 Sign in with Apple Key 생성

1. **Keys → 우측 상단 "+"** 클릭
2. **Key Name**: `Perfacto Sign In Key`
3. **"Sign in with Apple" 체크** → **Configure** 클릭
4. **Primary App ID** 선택 → **Save**
5. **Continue → Register**
6. **Download 클릭하여 .p8 파일 저장**
7. **Key ID 메모** (10자리 영숫자)

> 🚨 **경고**: .p8 파일은 **단 한 번만 다운로드** 가능합니다!

---

## 📱 3. Xcode 설정 (iOS)

### 3.1 Sign in with Apple Capability 추가

1. Xcode에서 프로젝트 열기
2. **Runner → Signing & Capabilities** 탭
3. **+ Capability** 클릭
4. **"Sign in with Apple"** 검색하여 추가

### 3.2 Entitlements 파일 확인

`ios/Runner/Runner.entitlements` 파일이 아래 내용을 포함하는지 확인:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

---

## 🤖 4. Android 설정

### 4.1 SHA-1 인증서 지문 등록

Google 로그인을 Android에서 사용하려면 Firebase Console에 SHA-1 등록이 필요합니다.

1. 터미널에서 SHA-1 확인:
```bash
# Debug 키
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release 키 (프로덕션용)
keytool -list -v -keystore your-release-key.keystore -alias your-alias
```

2. **Firebase Console → 프로젝트 설정 → Android 앱** 에서 SHA-1 추가

---

## 🌐 5. Web 설정

### 5.1 승인된 도메인 확인

**Firebase Console → Authentication → Settings → 승인된 도메인**에서 다음이 있는지 확인:
- `perfacto-7aa56.firebaseapp.com`
- `perfacto-7aa56.web.app`
- `localhost` (개발용)

---

## ✅ 최종 체크리스트

### 🔴 Bundle ID 변경 (최우선!)
- [ ] Firebase Console에서 iOS 앱 재등록 (`com.lvher.perfacto`)
- [ ] GoogleService-Info.plist 다시 다운로드 및 교체
- [ ] Apple Developer에서 App ID 생성 (`com.lvher.perfacto`)

### Firebase Console
- [ ] Google 제공업체 활성화
- [ ] Apple 제공업체 활성화
- [ ] Apple 서비스 ID 입력 (`com.lvher.perfacto.service`)
- [ ] Apple OAuth 코드 흐름 - 팀 ID 입력
- [ ] Apple OAuth 코드 흐름 - 키 ID 입력
- [ ] Apple OAuth 코드 흐름 - 비공개 키 입력

### Apple Developer
- [ ] App ID (`com.lvher.perfacto`)에 Sign in with Apple 활성화
- [ ] Services ID 생성 (`com.lvher.perfacto.service`)
- [ ] Services ID에 Website URLs 등록 **및 선택**
- [ ] Sign in with Apple Key 생성
- [ ] .p8 파일 안전하게 보관

### Xcode (iOS)
- [ ] Sign in with Apple Capability 추가
- [ ] Entitlements 파일 확인
- [ ] GoogleService-Info.plist 최신 버전
- [ ] Info.plist에 REVERSED_CLIENT_ID URL Scheme 추가

### Android
- [ ] SHA-1 인증서 Firebase에 등록

---

## 🔧 트러블슈팅

### 웹에서 Apple 로그인 팝업이 즉시 닫힘
→ Firebase Console의 OAuth 코드 흐름 설정이 비어있음

### "Invalid client_id" 오류
→ Services ID 설정 확인, Website URLs 선택 여부 확인

### iOS에서 로그인 실패
→ Xcode Capability 추가 확인, App ID 활성화 확인

### Android에서 Google 로그인 실패
→ SHA-1 등록 확인, google-services.json 최신 버전 확인

---

**문서 작성일**: 2026-02-05
