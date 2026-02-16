# Firebase 마이그레이션 가이드

## 개요

Perfacto 앱을 Spring Boot REST API 백엔드에서 Firebase 백엔드로 마이그레이션했습니다.

**마이그레이션 범위**:
- ✅ 인증: Firebase Authentication (이메일/비밀번호)
- ✅ 데이터베이스: Cloud Firestore
- ✅ 서비스 레이어: `FirestoreService`, `FirebaseAuthService` 생성
- ✅ 앱 초기화: `main.dart`에 Firebase 초기화 추가

---

## 1. Firebase 프로젝트 설정

### 1.1 Firebase Console에서 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름: `perfacto` (또는 원하는 이름)
4. Google Analytics 설정 (선택사항)

### 1.2 Android 앱 등록

1. Firebase 프로젝트 > "앱 추가" > Android 선택
2. **Android 패키지 이름**: `com.example.perfacto` (또는 실제 패키지명)
3. `google-services.json` 다운로드
4. 파일을 `android/app/` 경로에 배치

**`android/build.gradle` 수정**:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**`android/app/build.gradle` 수정**:
```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"  // 이 줄 추가
}
```

### 1.3 iOS 앱 등록

1. Firebase 프로젝트 > "앱 추가" > iOS 선택
2. **iOS 번들 ID**: `com.example.perfacto` (또는 실제 번들 ID)
3. `GoogleService-Info.plist` 다운로드
4. Xcode에서 `ios/Runner/` 경로에 파일 추가

### 1.4 firebase_options.dart 생성

프로젝트 루트에서 FlutterFire CLI 실행:

```bash
# FlutterFire CLI 설치 (한 번만 실행)
dart pub global activate flutterfire_cli

# Firebase 설정 파일 생성
flutterfire configure
```

이 명령은 자동으로 `lib/firebase_options.dart` 파일을 생성합니다.

---

## 2. Firebase Authentication 설정

### 2.1 Firebase Console에서 인증 활성화

1. Firebase Console > Authentication > "시작하기"
2. "Sign-in method" 탭
3. "이메일/비밀번호" 활성화

### 2.2 사용 가능한 인증 메서드

**현재 구현된 인증**:
- ✅ 이메일/비밀번호 회원가입
- ✅ 이메일/비밀번호 로그인
- ✅ 로그아웃
- ✅ 비밀번호 재설정 이메일

**향후 추가 가능한 인증** (TODO 주석으로 표시됨):
- Google 로그인
- Apple 로그인
- Kakao 로그인

---

## 3. Cloud Firestore 데이터 모델

### 3.1 컬렉션 구조

```
firestore
├── users/                          # 사용자 정보
│   ├── {userId}/
│   │   ├── email: string
│   │   ├── nickname: string
│   │   ├── displayName: string
│   │   ├── photoURL: string?
│   │   ├── reviewCount: number
│   │   ├── totalPoints: number
│   │   ├── city: string
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│
├── places/                         # 장소 정보
│   ├── {placeId}/
│   │   ├── name: string
│   │   ├── categoryCode: string
│   │   ├── address: string
│   │   ├── description: string?
│   │   ├── latitude: number
│   │   ├── longitude: number
│   │   ├── city: string
│   │   ├── district: string
│   │   ├── phone: string?
│   │   ├── instagramUrl: string?
│   │   ├── tiktokUrl: string?
│   │   ├── reviewCount: number
│   │   ├── averageRating: number
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │
│   └── reviews/                    # 리뷰 (서브컬렉션)
│       ├── {reviewId}/
│       │   ├── userId: string
│       │   ├── placeId: string
│       │   ├── overallRating: string (GOOD/NEUTRAL/BAD)
│       │   ├── reasons: string[]
│       │   ├── tags: string[]
│       │   ├── comparedPlaceId: string?
│       │   ├── comparisonResult: string?
│       │   ├── likeCount: number
│       │   ├── createdAt: timestamp
│       │   └── updatedAt: timestamp
│
├── categories/                     # 카테고리 정보
│   ├── {categoryId}/
│   │   ├── code: string
│   │   ├── label: string
│   │   ├── emoji: string
│   │   └── order: number
│
├── savedPlaces/                    # 저장된 장소
│   ├── {userId}_{placeId}/
│   │   ├── userId: string
│   │   ├── placeId: string
│   │   └── savedAt: timestamp
│
├── follows/                        # 팔로우 관계
│   ├── {followerId}_{followingId}/
│   │   ├── followerId: string
│   │   ├── followingId: string
│   │   └── createdAt: timestamp
│
├── matchScores/                    # 매치 스코어 (캐시)
│   ├── {userId1}_{userId2}/
│   │   ├── userId1: string
│   │   ├── userId2: string
│   │   ├── matchScore: number
│   │   ├── commonReviewCount: number
│   │   ├── totalReviewCount: number
│   │   ├── calculatedAt: timestamp
│   │   └── expiresAt: timestamp
│
├── streaks/                        # 연속 리뷰 기록
│   ├── {userId}/
│   │   ├── userId: string
│   │   ├── currentStreak: number
│   │   ├── longestStreak: number
│   │   ├── lastReviewDate: timestamp
│   │   └── updatedAt: timestamp
│
└── leaderboards/                   # 리더보드
    ├── global_{userId}/
    │   ├── userId: string
    │   ├── type: "global"
    │   ├── nickname: string
    │   ├── city: string
    │   ├── totalPoints: number
    │   ├── reviewCount: number
    │   ├── rank: number
    │   └── updatedAt: timestamp
    │
    └── city_{city}_{userId}/
        ├── userId: string
        ├── type: "city"
        ├── city: string
        ├── nickname: string
        ├── totalPoints: number
        ├── reviewCount: number
        ├── rank: number
        └── updatedAt: timestamp
```

### 3.2 인덱스 생성 필요

Firebase Console > Firestore > "색인" 탭에서 다음 복합 인덱스를 생성해야 합니다:

**1. places 컬렉션 인덱스**:
```
컬렉션: places
필드: categoryCode (ASC) + averageRating (DESC)
필드: city (ASC) + categoryCode (ASC) + averageRating (DESC)
필드: district (ASC) + categoryCode (ASC) + averageRating (DESC)
```

**2. leaderboards 컬렉션 인덱스**:
```
컬렉션: leaderboards
필드: type (ASC) + totalPoints (DESC)
필드: type (ASC) + city (ASC) + totalPoints (DESC)
```

**3. reviews 서브컬렉션 인덱스** (Collection Group Query):
```
컬렉션 그룹: reviews
필드: userId (ASC) + createdAt (DESC)
```

**인덱스 자동 생성 방법**:
- 앱을 실행하고 해당 쿼리를 사용하면 Firebase가 인덱스 생성 링크를 제공합니다
- 링크를 클릭하면 자동으로 필요한 인덱스가 생성됩니다

---

## 4. Firestore 보안 규칙

Firebase Console > Firestore > "규칙" 탭에서 다음 보안 규칙을 설정하세요:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 헬퍼 함수
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // users 컬렉션
    match /users/{userId} {
      // 자신의 프로필은 읽기/쓰기 가능, 다른 사람 프로필은 읽기만 가능
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update, delete: if isOwner(userId);
    }

    // places 컬렉션
    match /places/{placeId} {
      // 모든 인증된 사용자가 읽기 가능
      allow read: if isAuthenticated();
      // 관리자만 생성/수정/삭제 가능 (향후 관리자 역할 추가 필요)
      allow write: if isAuthenticated();

      // reviews 서브컬렉션
      match /reviews/{reviewId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated();
        allow update, delete: if isAuthenticated() &&
                                 resource.data.userId == request.auth.uid;
      }
    }

    // categories 컬렉션
    match /categories/{categoryId} {
      allow read: if true; // 모든 사용자가 읽기 가능
      allow write: if false; // 관리자만 수정 가능 (Firebase Console에서 직접 관리)
    }

    // savedPlaces 컬렉션
    match /savedPlaces/{docId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow delete: if isAuthenticated() &&
                       resource.data.userId == request.auth.uid;
    }

    // follows 컬렉션
    match /follows/{docId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow delete: if isAuthenticated() &&
                       resource.data.followerId == request.auth.uid;
    }

    // matchScores 컬렉션
    match /matchScores/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated(); // 캐시 데이터
    }

    // streaks 컬렉션
    match /streaks/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    // leaderboards 컬렉션
    match /leaderboards/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated(); // 자동 업데이트용
    }
  }
}
```

---

## 5. 주요 서비스 클래스

### 5.1 FirebaseAuthService

**위치**: `lib/services/firebase_auth_service.dart`

**주요 기능**:
- 이메일/비밀번호 회원가입/로그인
- 사용자 프로필 관리 (Firestore 연동)
- 비밀번호 재설정
- 회원 탈퇴
- 사용자 검색

**사용 예시**:
```dart
// 회원가입
try {
  await FirebaseAuthService.signUp(
    email: 'user@example.com',
    password: 'password123',
    nickname: '홍길동',
  );
} catch (e) {
  print('회원가입 실패: $e');
}

// 로그인
try {
  await FirebaseAuthService.signIn(
    email: 'user@example.com',
    password: 'password123',
  );
} catch (e) {
  print('로그인 실패: $e');
}

// 현재 사용자 확인
bool isLoggedIn = FirebaseAuthService.isLoggedIn;
String? userId = FirebaseAuthService.currentUserId;

// 로그아웃
await FirebaseAuthService.signOut();
```

### 5.2 FirestoreService

**위치**: `lib/services/firestore_service.dart`

**주요 기능**:
- 장소 CRUD (카테고리별 조회, 검색, 랭킹)
- 리뷰 CRUD (생성, 조회, 삭제)
- 저장된 장소 관리
- 팔로우/언팔로우
- 매치 스코어 계산 (캐싱)
- 연속 기록 (Streak) 관리
- 리더보드 조회

**사용 예시**:
```dart
// 카테고리별 장소 조회
final places = await FirestoreService.getPlacesByCategory('restaurant');

// 리뷰 작성
final reviewId = await FirestoreService.createReview(
  placeId: 'place123',
  overallRating: 'GOOD',
  reasons: ['CLEAN', 'FRIENDLY'],
  tags: ['cozy', 'romantic'],
);

// 매치 스코어 조회
final matchScore = await FirestoreService.getMatchScore('otherUserId');

// 리더보드 조회
final globalLeaderboard = await FirestoreService.getGlobalLeaderboard(limit: 100);
final cityLeaderboard = await FirestoreService.getCityLeaderboard('포항', limit: 100);
```

---

## 6. 초기 데이터 설정

### 6.1 카테고리 데이터 추가

Firebase Console > Firestore > "categories" 컬렉션에서 다음 문서를 생성하세요:

```javascript
// 문서 ID: restaurant
{
  "code": "restaurant",
  "label": "음식점",
  "emoji": "🍽️",
  "order": 1
}

// 문서 ID: bar
{
  "code": "bar",
  "label": "바",
  "emoji": "🍺",
  "order": 2
}

// 문서 ID: bakery
{
  "code": "bakery",
  "label": "베이커리",
  "emoji": "🥐",
  "order": 3
}

// 문서 ID: coffee_tea
{
  "code": "coffee_tea",
  "label": "카페",
  "emoji": "☕",
  "order": 4
}

// 문서 ID: dessert
{
  "code": "dessert",
  "label": "디저트",
  "emoji": "🍦",
  "order": 5
}
```

### 6.2 테스트 장소 데이터 추가 (선택사항)

Firebase Console > Firestore > "places" 컬렉션에서 테스트용 장소를 추가하세요.

---

## 7. 다음 단계 (TODO)

### 7.1 기존 페이지 업데이트

기존 페이지에서 `ApiService`를 사용하는 부분을 `FirestoreService`로 변경해야 합니다:

**업데이트 필요한 파일**:
- `lib/pages/home_page.dart` - 장소 목록 조회
- `lib/pages/place_detail_page.dart` - 장소 상세 조회
- `lib/pages/review_write_page.dart` - 리뷰 작성
- `lib/pages/my_page.dart` - 사용자 정보 조회
- `lib/pages/login_page.dart` - 로그인 (FirebaseAuthService 사용)
- `lib/pages/signup_page.dart` - 회원가입 (FirebaseAuthService 사용)

**변경 예시**:
```dart
// 기존
final places = await ApiService.getPlacesByCategory(categoryCode);

// 변경 후
final places = await FirestoreService.getPlacesByCategory(categoryCode);
```

### 7.2 인증 상태 관리

로그인 상태를 전역적으로 관리하려면 Provider 또는 Riverpod 사용을 권장합니다:

```dart
// FirebaseAuthService.authStateChanges를 사용한 실시간 인증 상태 감지
FirebaseAuthService.authStateChanges.listen((user) {
  if (user == null) {
    // 로그아웃 상태
    print('User is signed out');
  } else {
    // 로그인 상태
    print('User is signed in: ${user.uid}');
  }
});
```

### 7.3 에러 처리 개선

Firebase 관련 에러를 사용자 친화적으로 표시하는 글로벌 에러 핸들러를 추가하세요.

### 7.4 오프라인 지원

Firestore는 기본적으로 오프라인 캐싱을 지원합니다. 추가 설정은 필요하지 않습니다.

### 7.5 Cloud Functions (선택사항)

복잡한 비즈니스 로직은 Cloud Functions로 이동할 수 있습니다:
- 매치 스코어 재계산
- 리더보드 업데이트
- 푸시 알림 발송

---

## 8. 테스트

### 8.1 Firebase 연결 테스트

```bash
flutter run
```

앱이 정상적으로 실행되고 Firebase 초기화 로그가 출력되는지 확인하세요.

### 8.2 인증 테스트

1. 회원가입 페이지에서 새 계정 생성
2. Firebase Console > Authentication에서 사용자가 추가되었는지 확인
3. Firestore > users 컬렉션에 사용자 프로필이 생성되었는지 확인

### 8.3 데이터 테스트

1. 앱에서 리뷰 작성
2. Firestore > places > reviews 서브컬렉션에서 리뷰 확인
3. users 컬렉션에서 reviewCount가 증가했는지 확인

---

## 9. 문제 해결

### 9.1 Firebase 초기화 실패

**증상**: `Firebase has not been initialized` 에러

**해결 방법**:
1. `flutterfire configure` 명령을 실행했는지 확인
2. `firebase_options.dart` 파일이 생성되었는지 확인
3. `main.dart`에서 `Firebase.initializeApp()` 호출 확인

### 9.2 google-services.json 누락

**증상**: Android 빌드 실패

**해결 방법**:
1. Firebase Console에서 `google-services.json` 다운로드
2. `android/app/` 경로에 파일 배치
3. `flutter clean` 후 재빌드

### 9.3 인덱스 누락 에러

**증상**: `The query requires an index` 에러

**해결 방법**:
1. 에러 메시지의 링크를 클릭
2. Firebase Console에서 인덱스 자동 생성
3. 인덱스 생성 완료 후 쿼리 재실행

### 9.4 권한 거부 에러

**증상**: `Missing or insufficient permissions` 에러

**해결 방법**:
1. Firestore 보안 규칙 확인
2. 사용자가 로그인되어 있는지 확인
3. 보안 규칙에서 해당 작업이 허용되는지 확인

---

## 10. 참고 자료

- [FlutterFire 공식 문서](https://firebase.flutter.dev/)
- [Firebase Authentication 문서](https://firebase.google.com/docs/auth)
- [Cloud Firestore 문서](https://firebase.google.com/docs/firestore)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase 인덱스 관리](https://firebase.google.com/docs/firestore/query-data/indexing)

---

## 11. 마이그레이션 체크리스트

### Firebase 설정
- [ ] Firebase 프로젝트 생성
- [ ] Android 앱 등록 및 `google-services.json` 추가
- [ ] iOS 앱 등록 및 `GoogleService-Info.plist` 추가
- [ ] `flutterfire configure` 실행
- [ ] Firebase Authentication 활성화 (이메일/비밀번호)

### Firestore 설정
- [ ] Firestore 데이터베이스 생성
- [ ] 보안 규칙 설정
- [ ] 필요한 인덱스 생성
- [ ] 카테고리 초기 데이터 추가

### 코드 업데이트
- [x] `pubspec.yaml`에 Firebase 패키지 추가
- [x] `main.dart`에 Firebase 초기화 추가
- [x] `FirebaseAuthService` 생성
- [x] `FirestoreService` 생성
- [ ] 기존 페이지에서 `ApiService` → `FirestoreService` 변경
- [ ] 기존 인증 로직 → `FirebaseAuthService` 변경

### 테스트
- [ ] Firebase 연결 테스트
- [ ] 회원가입/로그인 테스트
- [ ] 장소 조회 테스트
- [ ] 리뷰 작성 테스트
- [ ] 저장/팔로우 기능 테스트
- [ ] 매치 스코어 계산 테스트
- [ ] 리더보드 조회 테스트

### 배포 준비
- [ ] 프로덕션 보안 규칙 검토
- [ ] Firebase 프로젝트 요금제 확인
- [ ] 백업 정책 수립
- [ ] 모니터링 설정

---

**마이그레이션 완료일**: 2026-02-05
**작성자**: Claude (Anthropic)
