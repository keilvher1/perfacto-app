# Firebase 웹 연동 완료 가이드

## ✅ 완료된 작업

### 1. Firebase SDK 추가
- `web/index.html`에 Firebase JavaScript SDK 추가
  - firebase-app-compat.js
  - firebase-auth-compat.js
  - firebase-firestore-compat.js
  - firebase-storage-compat.js

### 2. Firebase 초기화 코드 추가
- Firebase 설정 (firebase_options.dart의 web 설정과 동일)
- 자동 초기화 스크립트 추가

### 3. 웹 재빌드 및 재배포
- ✅ `flutter build web --release` 완료
- ✅ `firebase deploy --only hosting` 완료

---

## 🔥 Firebase Console 설정 필요 (중요!)

웹 앱이 정상 작동하려면 Firebase Console에서 다음을 설정해야 합니다.

### 1. Authentication 활성화

**URL**: https://console.firebase.google.com/project/perfacto-7aa56/authentication/providers

**작업**:
1. Firebase Console > Authentication 메뉴 클릭
2. "시작하기" 버튼 클릭 (처음인 경우)
3. "Sign-in method" 탭 클릭
4. "이메일/비밀번호" 클릭
5. "사용 설정" 토글을 ON으로 변경
6. "저장" 클릭

**확인**:
- "이메일/비밀번호" 상태가 "사용 설정됨"으로 표시되어야 함

---

### 2. Cloud Firestore 데이터베이스 생성

**URL**: https://console.firebase.google.com/project/perfacto-7aa56/firestore

**작업**:
1. Firebase Console > Firestore Database 메뉴 클릭
2. "데이터베이스 만들기" 버튼 클릭
3. **위치 선택**: `asia-northeast3 (서울)` 권장
4. **보안 규칙**: "테스트 모드에서 시작" 선택
   - 30일 동안 모든 읽기/쓰기 허용
   - 이후 보안 규칙 적용 필요
5. "다음" → "사용 설정" 클릭

**확인**:
- Firestore Database가 생성되고 빈 컬렉션 화면이 표시됨

---

### 3. Firestore 보안 규칙 설정 (테스트 후 적용)

**URL**: https://console.firebase.google.com/project/perfacto-7aa56/firestore/rules

테스트 모드로 시작했다면 30일 후 다음 규칙을 적용하세요:

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
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update, delete: if isOwner(userId);
    }

    // places 컬렉션
    match /places/{placeId} {
      allow read: if isAuthenticated();
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
      allow read: if true;
      allow write: if false; // 관리자만 수정 (Console에서 직접 관리)
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

    // matchScores, streaks, leaderboards 컬렉션
    match /matchScores/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    match /streaks/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    match /leaderboards/{docId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
  }
}
```

---

### 4. 초기 데이터 추가 (카테고리)

**URL**: https://console.firebase.google.com/project/perfacto-7aa56/firestore/data

Firestore에 `categories` 컬렉션을 생성하고 다음 5개 문서를 추가하세요:

#### 문서 1: restaurant
```json
{
  "code": "restaurant",
  "label": "음식점",
  "emoji": "🍽️",
  "order": 1
}
```

#### 문서 2: bar
```json
{
  "code": "bar",
  "label": "바",
  "emoji": "🍺",
  "order": 2
}
```

#### 문서 3: bakery
```json
{
  "code": "bakery",
  "label": "베이커리",
  "emoji": "🥐",
  "order": 3
}
```

#### 문서 4: coffee_tea
```json
{
  "code": "coffee_tea",
  "label": "카페",
  "emoji": "☕",
  "order": 4
}
```

#### 문서 5: dessert
```json
{
  "code": "dessert",
  "label": "디저트",
  "emoji": "🍦",
  "order": 5
}
```

**추가 방법**:
1. Firestore > "컬렉션 시작" 클릭
2. 컬렉션 ID: `categories` 입력
3. 첫 번째 문서 ID: `restaurant` 입력
4. 필드 추가: `code` (string), `label` (string), `emoji` (string), `order` (number)
5. "저장" 클릭
6. 나머지 4개 문서도 동일하게 추가

---

## 📱 웹 앱 테스트

### 1. 웹 앱 접속
**URL**: https://perfacto-7aa56.web.app

### 2. 개발자 도구로 Firebase 연동 확인

브라우저 개발자 도구(F12) > Console 탭에서 다음을 확인:

```javascript
// Firebase 초기화 확인
firebase.apps.length > 0  // true여야 함

// Firebase Auth 확인
firebase.auth().currentUser  // null (로그인 전)

// Firestore 확인
firebase.firestore().collection('categories').get()
  .then(snapshot => console.log('Categories:', snapshot.size))
```

### 3. 기능 테스트 순서

1. **지도 로딩**: 포항 지도가 정상 표시되는지 확인
2. **회원가입**: 이메일/비밀번호로 새 계정 생성
3. **로그인**: 생성한 계정으로 로그인
4. **장소 조회**: 카테고리별 장소 목록 확인
5. **리뷰 작성**: 장소에 리뷰 작성
6. **저장/팔로우**: 장소 저장 및 사용자 팔로우

---

## 🚨 문제 해결

### Firebase 초기화 실패
**증상**: Console에 "Firebase is not defined" 에러

**해결**:
1. 브라우저 캐시 삭제 후 새로고침 (Ctrl+Shift+R)
2. `web/index.html`에 Firebase SDK 스크립트가 있는지 확인
3. 재배포: `flutter build web --release && firebase deploy --only hosting`

### Authentication 에러
**증상**: 로그인/회원가입 시 에러 발생

**해결**:
1. Firebase Console > Authentication에서 이메일/비밀번호가 활성화되어 있는지 확인
2. 웹 도메인이 승인된 도메인 목록에 있는지 확인
   - Authentication > Settings > Authorized domains
   - `perfacto-7aa56.web.app`와 `perfacto-7aa56.firebaseapp.com` 추가

### Firestore 권한 거부 에러
**증상**: "Missing or insufficient permissions" 에러

**해결**:
1. Firestore Database가 생성되어 있는지 확인
2. 보안 규칙이 너무 제한적이지 않은지 확인
3. 테스트 모드: 모든 읽기/쓰기 허용 (30일)
4. 사용자가 로그인되어 있는지 확인

### CORS 에러
**증상**: "Access-Control-Allow-Origin" 에러

**해결**:
1. Firebase Hosting을 사용하면 자동으로 CORS 설정됨
2. 로컬 테스트 시: `firebase serve --only hosting` 사용
3. 직접 `index.html`을 열면 CORS 에러 발생 가능

---

## 📊 Firebase Console 주요 메뉴

| 메뉴 | URL | 용도 |
|------|-----|------|
| 프로젝트 개요 | https://console.firebase.google.com/project/perfacto-7aa56/overview | 프로젝트 전체 현황 |
| Authentication | https://console.firebase.google.com/project/perfacto-7aa56/authentication | 사용자 인증 관리 |
| Firestore Database | https://console.firebase.google.com/project/perfacto-7aa56/firestore | 데이터베이스 관리 |
| Hosting | https://console.firebase.google.com/project/perfacto-7aa56/hosting | 웹 호스팅 관리 |
| Storage | https://console.firebase.google.com/project/perfacto-7aa56/storage | 파일 저장소 관리 |

---

## 🔐 보안 권장사항

### 1. API 키 보호
- Firebase 웹 API 키는 공개되어도 안전함 (Firebase 보안 규칙으로 보호)
- 하지만 Google Maps API 키는 제한 설정 권장:
  - Google Cloud Console에서 HTTP 리퍼러 제한 설정
  - `perfacto-7aa56.web.app/*` 허용

### 2. Firestore 보안 규칙
- 테스트 모드는 30일 후 자동으로 모든 요청 거부
- 프로덕션 배포 전 보안 규칙 적용 필수

### 3. Authentication 설정
- 비밀번호 정책 설정 (최소 길이, 복잡도)
- 이메일 인증 활성화 권장
- 계정 보호 기능 활성화

---

## 📝 체크리스트

웹 앱 배포 후 다음 항목을 확인하세요:

- [ ] Firebase SDK가 web/index.html에 포함되어 있음
- [ ] Firebase Console에서 Authentication 활성화됨
- [ ] Firebase Console에서 Firestore Database 생성됨
- [ ] Firestore에 categories 컬렉션 및 5개 문서 추가됨
- [ ] 웹 앱에서 회원가입 테스트 성공
- [ ] 웹 앱에서 로그인 테스트 성공
- [ ] 웹 앱에서 Firestore 읽기/쓰기 테스트 성공
- [ ] 브라우저 Console에 Firebase 에러 없음
- [ ] 모바일 반응형 디자인 확인

---

**웹 앱 URL**: https://perfacto-7aa56.web.app
**Firebase Console**: https://console.firebase.google.com/project/perfacto-7aa56/overview
**완료일**: 2026-02-05
