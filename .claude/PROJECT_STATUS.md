# Perfacto 프로젝트 진행 상황

**마지막 업데이트**: 2025-01-13
**프로젝트 상태**: 종료 예정 (AWS 리소스 정리 중)

---

## 📋 프로젝트 개요

**Perfacto (퍼팩토)** - 여행지 리뷰 SNS 플랫폼

### 기술 스택
```yaml
Frontend:
  - Flutter (Dart)
  - Firebase (Authentication, Firestore - 일부 기능)
  - REST API 연동

Backend:
  - Spring Boot (Java)
  - PostgreSQL (AWS RDS)
  - JWT 인증
  - AWS EC2 호스팅

Infrastructure:
  - AWS EC2: 3.38.160.198 (perfacto-server)
  - AWS RDS: PostgreSQL (삭제됨)
  - Firebase: 인증 및 일부 저장 기능
```

### 저장소
- Frontend: https://github.com/keilvher1/perfacto-app.git
- Backend: https://github.com/keilvher1/perfacto-server.git

---

## 🔥 최근 작업 내역 (2025-01-13)

### 1. 리뷰 등록 시스템 구현 ✅

**문제**: 리뷰 등록이 작동하지 않음
- review_write_page.dart가 전체 주석 처리됨 (663줄의 Firebase 코드)

**해결**:
1. **프론트엔드** (review_write_page.dart 완전 재작성):
   - 3단계 리뷰 시스템 구현 (502줄)
   - Step 1: 전체 평가 (GOOD/NEUTRAL/BAD)
   - Step 2: 이유 선택 (다중 선택 가능)
   - Step 3: 비교 평가 (선택사항)
   - 진행 표시기 및 단계별 검증
   - REST API 연동

2. **백엔드** (DTO import 수정):
   - PerfactoReviewController.java: 잘못된 DTO import 수정
   - PerfactoReviewService.java: 3단계 리뷰 필드 사용
   - 올바른 DTO: `org.example.scrd.dto.ReviewCreateRequest`
   - 잘못된 DTO: `org.example.scrd.dto.request.ReviewCreateRequest` (구버전)

**커밋**:
- Frontend: `cdcb7e6` - "chore: macOS 설정 및 모델 업데이트"
- Backend: 이전에 커밋됨 - "fix: 3단계 리뷰 시스템을 위한 DTO import 수정"

### 2. 기능 명세서 분석 완료 ✅

**파일**: `/Users/mac/Downloads/퍼팩토_기능명세서_최종.xlsx`

**분석 결과**:
- 총 12개 시트, 1,500+ 행
- **현재 구현률: 약 25-30%**

**주요 갭**:
```yaml
구현 완료 (70-100%):
  - 인증/로그인: 70%
  - 장소 검색/지도: 80%
  - 비교 랭킹: 75%

구현 중 (30-50%):
  - 온보딩: 30%
  - 마이페이지: 60%

미구현 (0-10%):
  - 피드 시스템: 0%
  - 소셜 기능: 0% (팔로우, 좋아요, 댓글)
  - 추천 시스템: 0%
  - 알림 시스템: 10%
  - 콘텐츠 안전: 20%
  - 개인정보보호: 30%
```

### 3. AWS 리소스 정리 (진행 중) 🔄

**목적**: 프로젝트 종료로 인한 완전한 비용 제거

**진행 상황**:
```yaml
삭제 완료:
  ✅ RDS 인스턴스: 삭제됨

삭제 필요:
  ⏳ RDS 스냅샷: 삭제 예정 (콘솔에서 수동 삭제 필요)
  ⏳ EC2 인스턴스: perfacto-server 종료 필요
  ⏳ EBS 볼륨: vol-047894c36471baaf7 (EC2 종료 시 자동 삭제)
  ⏳ Elastic IP: 확인 필요
  ⏳ S3 버킷: 확인 필요
```

**예상 비용 (정리 전)**:
- EC2 (t2.small): ~$18/월
- RDS (db.t3.micro): ~$15/월
- EBS: ~$3/월
- **총 약 $36/월**

---

## 🏗️ 아키텍처 정보

### 데이터베이스 구조

**이중 데이터베이스 사용** (아키텍처 이슈):
```yaml
PostgreSQL (AWS RDS):
  - 사용자 (User)
  - 장소 (Place)
  - 리뷰 (PerfactoReview)
  - 비교 매치 (ComparisonMatch)
  - ELO 랭킹

Firestore:
  - 저장된 장소 (saved_places)
  - 일부 레거시 데이터
```

### 리뷰 시스템

**3단계 리뷰 구조**:
```java
// Step 1: Overall Rating
enum ReviewRating {
    GOOD,    // 좋아요
    NEUTRAL, // 괜찮아요
    BAD      // 별로예요
}

// Step 2: Reasons (다중 선택)
enum ReviewReason {
    // GOOD 이유
    CLEAN, FRIENDLY, DELICIOUS, ATMOSPHERE, REASONABLE, LOCATION,

    // NEUTRAL 이유
    ORDINARY, ACCEPTABLE, PRICE_MATCH,

    // BAD 이유
    DIRTY, UNFRIENDLY, NOT_DELICIOUS, NOISY, EXPENSIVE, INCONVENIENT
}

// Step 3: Comparison (선택사항)
enum ComparisonResult {
    BETTER,  // 이 장소가 더 좋음
    SIMILAR, // 비슷함
    WORSE    // 비교 대상이 더 좋음
}
```

### API 엔드포인트

**베이스 URL**: `http://3.38.160.198:8080`

**주요 엔드포인트**:
```
POST   /perfacto/api/reviews              # 리뷰 작성
GET    /perfacto/api/reviews/place/{id}   # 장소별 리뷰 조회
GET    /perfacto/api/reviews/my           # 내 리뷰 조회
PUT    /perfacto/api/reviews/{id}         # 리뷰 수정
DELETE /perfacto/api/reviews/{id}         # 리뷰 삭제
POST   /perfacto/api/reviews/{id}/helpful # 도움이 됨 증가

GET    /perfacto/every/places/ranking     # ELO 랭킹 조회
POST   /perfacto/api/places/save          # 장소 저장
```

---

## 🐛 해결된 이슈

### Issue #1: 400 Bad Request - 리뷰 등록 실패

**증상**:
```
Response Status Code: 400
Response Body: {"timestamp":"2025-12-31T05:56:12.141+00:00","status":400,"error":"Bad Request"}
```

**원인**:
1. Controller가 잘못된 DTO import 사용
2. 프론트엔드는 3단계 리뷰 형식 전송
3. 백엔드는 구버전 DTO 기대 (rating, content 필드)
4. Validation 실패

**해결**:
```java
// BEFORE
import org.example.scrd.dto.request.ReviewCreateRequest;

// AFTER
import org.example.scrd.dto.ReviewCreateRequest;
```

### Issue #2: Compilation Error - Type Mismatch

**증상**:
```
error: incompatible types: bad type in conditional expression
    Place cannot be converted to Long
```

**원인**:
- PerfactoReview.create() 메서드가 `Long comparedPlaceId` 기대
- 코드에서 Place 객체 전달 시도

**해결**:
```java
// BEFORE (에러)
request.getComparedPlaceId() != null ?
    placeRepository.findById(request.getComparedPlaceId()).orElse(null) : null

// AFTER (수정)
request.getComparedPlaceId()  // Long을 직접 전달
```

### Issue #3: SSH 접근 실패

**증상**:
- EC2 인스턴스 SSH 접근 불가
- 여러 키 시도 (vockey.pem, lab-key.pem, labsuser.pem) 모두 실패

**현재 상태**:
- 배포 불가 상태
- 코드는 GitHub에 커밋됨
- 프로젝트 종료로 해결 불필요

---

## 📊 프로젝트 현황

### 구현 상태 요약

| 카테고리 | 구현률 | 상태 |
|---------|-------|------|
| 인증/로그인 | 70% | 🟡 |
| 온보딩 | 30% | 🔴 |
| 비교/랭킹 | 75% | 🟢 |
| 검색/지도 | 80% | 🟢 |
| 피드 시스템 | 0% | 🔴 |
| 소셜 기능 | 0% | 🔴 |
| 마이페이지 | 60% | 🟡 |
| 추천 시스템 | 0% | 🔴 |
| 알림 시스템 | 10% | 🔴 |
| 콘텐츠 안전 | 20% | 🔴 |

### 주요 미구현 기능

**피드 시스템** (0%):
- 팔로잉 피드
- 인기 피드
- 개인화 피드
- 무한 스크롤

**소셜 기능** (0%):
- 팔로우/언팔로우
- 좋아요/댓글
- 공유 기능
- 사용자 프로필

**추천 시스템** (0%):
- 협업 필터링
- 컨텐츠 기반 추천
- 위치 기반 추천
- 인기도 기반 추천

---

## 🔧 기술적 이슈

### 아키텍처 문제

1. **이중 데이터베이스**:
   - PostgreSQL + Firestore 혼용
   - 데이터 일관성 문제 가능성
   - 마이그레이션 전략 필요

2. **레거시 코드**:
   - Firebase 코드 대량 주석 처리
   - 미사용 모델/서비스 다수 존재

3. **테스트 부재**:
   - 단위 테스트 없음
   - 통합 테스트 없음
   - E2E 테스트 없음

### 보안 이슈

1. **JWT 시크릿 관리**:
   - 환경변수로 관리 (양호)
   - 하드코딩 없음

2. **API 인증**:
   - Bearer 토큰 사용
   - 토큰 갱신 로직 확인 필요

3. **민감 정보**:
   - Firebase 설정 파일 노출
   - .gitignore 점검 필요

---

## 📝 다음 단계 (프로젝트 재개 시)

### 우선순위 1: 핵심 기능 완성

1. **소셜 기능 구현**:
   - User 관계 테이블 설계 (Follower/Following)
   - 팔로우/언팔로우 API
   - 좋아요/댓글 시스템

2. **피드 시스템 구현**:
   - 피드 조회 API (팔로잉, 인기, 개인화)
   - 무한 스크롤
   - 실시간 업데이트

3. **알림 시스템**:
   - Firebase Cloud Messaging 연동
   - 알림 타입별 템플릿
   - 읽음/안읽음 상태 관리

### 우선순위 2: 품질 개선

1. **테스트 작성**:
   - 단위 테스트 (JUnit, Flutter test)
   - 통합 테스트
   - E2E 테스트

2. **코드 정리**:
   - 주석 처리된 코드 제거
   - 미사용 파일 삭제
   - 코드 리팩토링

3. **아키텍처 개선**:
   - Firestore 완전 제거 또는 명확한 역할 분리
   - 데이터베이스 마이그레이션 계획
   - API 문서화 (Swagger/OpenAPI)

### 우선순위 3: 인프라 개선

1. **CI/CD 구축**:
   - GitHub Actions
   - 자동 테스트
   - 자동 배포

2. **모니터링**:
   - 로그 수집 (CloudWatch)
   - 성능 모니터링
   - 에러 추적 (Sentry)

3. **확장성**:
   - 로드 밸런서
   - Auto Scaling
   - CDN 적용

---

## 📚 참고 문서

### 설계 문서
- 기능 명세서: `/Users/mac/Downloads/퍼팩토_기능명세서_최종.xlsx`

### AWS 관련
- EC2 인스턴스: 3.38.160.198
- RDS: 삭제됨
- 리전: ap-northeast-2 (서울)

### 스크립트
- AWS 정리 스크립트: `/tmp/aws_cleanup.sh`
- RDS 스냅샷 삭제: `/tmp/delete_rds_snapshot.sh`

---

## 💬 비고

### 프로젝트 종료 사유
- 사용자 요청: "아예 프로젝트가 종료될것같아."
- AWS 비용 절감 목적
- 모든 리소스 완전 삭제 진행 중

### 향후 재개 시 체크리스트
```yaml
코드:
  ✅ GitHub에 모든 변경사항 푸시됨
  ✅ 최신 커밋: cdcb7e6 (Frontend), 이전 커밋 (Backend)

데이터:
  ⚠️  데이터베이스 백업 없음 (RDS 삭제됨, 스냅샷도 삭제 예정)
  ⚠️  Firebase 데이터는 유지됨

인프라:
  ❌ EC2 인스턴스 종료 예정
  ❌ RDS 삭제됨
  ⚠️  Firebase 프로젝트는 유지
```

### 긴급 연락처
- 없음 (개인 프로젝트)

---

**작성자**: Claude Code
**작성일**: 2025-01-13
