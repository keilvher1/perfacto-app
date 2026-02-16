# Perfacto 앱 개선 매뉴얼
## Beli 앱 벤치마킹 기반 구현 가이드

> **목적**: 이 문서는 Claude Code가 Perfacto 앱을 Beli 스타일로 개선하기 위한 상세 구현 가이드입니다.
>
> **대상 프로젝트**: `pohang_map` (Flutter/Dart)
>
> **백엔드**: Spring Boot (EC2: http://3.38.160.198:8080)

---

## 목차

1. [현재 프로젝트 구조](#1-현재-프로젝트-구조)
2. [개선 항목 개요](#2-개선-항목-개요)
3. [Phase 1: Match Score 시스템](#3-phase-1-match-score-시스템)
4. [Phase 2: 예측 점수 시스템](#4-phase-2-예측-점수-시스템)
5. [Phase 3: 카테고리 세분화](#5-phase-3-카테고리-세분화)
6. [Phase 4: 태그 시스템](#6-phase-4-태그-시스템)
7. [Phase 5: 게이미피케이션](#7-phase-5-게이미피케이션)
8. [Phase 6: SNS 연동](#8-phase-6-sns-연동)
9. [API 엔드포인트 명세](#9-api-엔드포인트-명세)
10. [데이터베이스 스키마](#10-데이터베이스-스키마)

---

## 1. 현재 프로젝트 구조

### 1.1 디렉토리 구조

```
lib/
├── main.dart                    # 앱 진입점
├── firebase_options.dart        # Firebase 설정
├── models/
│   ├── place.dart              # 장소 기본 모델
│   ├── place_model.dart        # 장소 상세 모델
│   └── review_model.dart       # 리뷰 모델
├── pages/
│   ├── splash_screen.dart      # 스플래시
│   ├── main_screen.dart        # 메인 네비게이션
│   ├── home_page.dart          # 홈 (지도)
│   ├── login_page.dart         # 로그인
│   ├── signup_page.dart        # 회원가입
│   ├── my_page.dart            # 마이페이지
│   ├── settings_page.dart      # 설정
│   ├── place_detail_page.dart  # 장소 상세
│   ├── review_write_page.dart  # 리뷰 작성 (기존)
│   ├── review_write_new_page.dart  # 리뷰 작성 (신규)
│   ├── ranking_page.dart       # ELO 랭킹
│   ├── hot_page.dart           # 인기 장소
│   ├── saved_places_page.dart  # 저장된 장소
│   ├── my_reviews_page.dart    # 내 리뷰
│   ├── friends_page.dart       # 친구
│   ├── follow_list_page.dart   # 팔로우 목록
│   ├── user_places_page.dart   # 사용자 장소
│   ├── point_page.dart         # 포인트
│   ├── point_reward_page.dart  # 포인트 보상
│   └── location_verification_page.dart  # 위치 인증
└── services/
    ├── api_service.dart        # REST API 통신
    ├── auth_service.dart       # 인증 서비스
    ├── places_cache_service.dart   # 장소 캐시
    └── saved_places_service.dart   # 저장 장소 서비스
```

### 1.2 현재 리뷰 시스템

```dart
// 현재 ApiService.createReview 메서드
static Future<Map<String, dynamic>> createReview({
  required int placeId,
  required String overallRating,    // 'GOOD', 'NEUTRAL', 'BAD'
  required List<String> reasons,     // ReviewReason enum values
  int? comparedPlaceId,
  String? comparisonResult,          // 'BETTER', 'SIMILAR', 'WORSE'
}) async { ... }
```

### 1.3 현재 API 엔드포인트

| Method | Endpoint | 설명 |
|--------|----------|------|
| GET | `/perfacto/every/categories` | 카테고리 목록 |
| GET | `/perfacto/every/places/category/{id}` | 카테고리별 장소 |
| GET | `/perfacto/every/places/{id}` | 장소 상세 |
| GET | `/perfacto/every/places/ranking` | ELO 랭킹 |
| POST | `/perfacto/api/reviews` | 리뷰 작성 |
| GET | `/perfacto/every/follows/{id}/following` | 팔로잉 목록 |
| GET | `/perfacto/every/follows/{id}/followers` | 팔로워 목록 |

---

## 2. 개선 항목 개요

### 2.1 우선순위별 개선 항목

| Phase | 기능 | 난이도 | 예상 소요 | 의존성 |
|-------|------|--------|----------|--------|
| 1 | Match Score (취향 궁합) | ⭐⭐⭐ | 3-4일 | 백엔드 필요 |
| 2 | 예측 점수 | ⭐⭐⭐⭐ | 4-5일 | Phase 1 |
| 3 | 카테고리 세분화 | ⭐⭐ | 2일 | 백엔드 필요 |
| 4 | 태그 시스템 | ⭐⭐ | 2-3일 | Phase 3 |
| 5 | 게이미피케이션 | ⭐⭐⭐ | 3-4일 | 백엔드 필요 |
| 6 | SNS 연동 | ⭐⭐⭐⭐ | 5일 | 외부 API |

### 2.2 Beli vs Perfacto 기능 비교

```
┌─────────────────────┬─────────────┬─────────────┐
│ 기능                │ Beli        │ Perfacto    │
├─────────────────────┼─────────────┼─────────────┤
│ ELO 랭킹            │ ✅          │ ✅          │
│ 3단계 리뷰          │ ✅          │ ✅          │
│ 상대 비교           │ ✅ (3-4회)  │ ✅ (1회)    │
│ Match Score         │ ✅          │ ❌ → 구현   │
│ 예측 점수           │ ✅          │ ❌ → 구현   │
│ 5개 카테고리        │ ✅          │ ❌ → 구현   │
│ 태그 시스템         │ ✅          │ ❌ → 구현   │
│ 리더보드            │ ✅          │ ❌ → 구현   │
│ Streak              │ ✅          │ ❌ → 구현   │
│ Want to Try         │ ✅          │ ✅ (저장)   │
│ SNS 연동            │ ✅          │ ❌ → 구현   │
└─────────────────────┴─────────────┴─────────────┘
```

---

## 3. Phase 1: Match Score 시스템

### 3.1 개념

Match Score는 두 사용자 간의 **음식 취향 유사도**를 백분율로 표시하는 기능입니다.

```
┌─────────────────────────────────────────────────────────┐
│  친구 프로필                                            │
│  ┌──────┐                                               │
│  │ 👤   │  김철수                                       │
│  └──────┘  @chulsoo                                     │
│                                                         │
│  ┌─────────────────────────────────────┐               │
│  │  🎯 취향 궁합: 87%                   │  ← Match Score │
│  │  ████████████████████░░░            │               │
│  └─────────────────────────────────────┘               │
│                                                         │
│  "비슷한 취향을 가지고 있어요!"                         │
└─────────────────────────────────────────────────────────┘
```

### 3.2 알고리즘

```dart
/// Match Score 계산 알고리즘
///
/// 1. 공통 방문 장소 추출
/// 2. 각 장소에 대한 평가 비교 (GOOD/NEUTRAL/BAD)
/// 3. 유사도 점수 계산
///
/// Formula:
/// matchScore = (동일 평가 수 * 1.0 + 유사 평가 수 * 0.5) / 전체 공통 장소 수 * 100

class MatchScoreCalculator {
  static double calculate(List<Review> userAReviews, List<Review> userBReviews) {
    // 공통 방문 장소 찾기
    final commonPlaceIds = userAReviews
        .map((r) => r.placeId)
        .toSet()
        .intersection(userBReviews.map((r) => r.placeId).toSet());

    if (commonPlaceIds.isEmpty) return 0.0;

    double score = 0.0;

    for (final placeId in commonPlaceIds) {
      final ratingA = userAReviews.firstWhere((r) => r.placeId == placeId).rating;
      final ratingB = userBReviews.firstWhere((r) => r.placeId == placeId).rating;

      if (ratingA == ratingB) {
        score += 1.0;  // 완전 일치
      } else if ((ratingA == 'GOOD' && ratingB == 'NEUTRAL') ||
                 (ratingA == 'NEUTRAL' && ratingB == 'GOOD') ||
                 (ratingA == 'NEUTRAL' && ratingB == 'BAD') ||
                 (ratingA == 'BAD' && ratingB == 'NEUTRAL')) {
        score += 0.5;  // 부분 일치
      }
      // GOOD vs BAD = 0점
    }

    return (score / commonPlaceIds.length) * 100;
  }
}
```

### 3.3 프론트엔드 구현

#### 3.3.1 새 파일 생성: `lib/models/match_score_model.dart`

```dart
class MatchScore {
  final int userId;
  final int targetUserId;
  final double score;
  final int commonPlacesCount;
  final String compatibility; // 'VERY_SIMILAR', 'SIMILAR', 'NEUTRAL', 'DIFFERENT'
  final DateTime calculatedAt;

  MatchScore({
    required this.userId,
    required this.targetUserId,
    required this.score,
    required this.commonPlacesCount,
    required this.compatibility,
    required this.calculatedAt,
  });

  factory MatchScore.fromJson(Map<String, dynamic> json) {
    return MatchScore(
      userId: json['userId'],
      targetUserId: json['targetUserId'],
      score: json['score'].toDouble(),
      commonPlacesCount: json['commonPlacesCount'],
      compatibility: json['compatibility'],
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }

  String get compatibilityText {
    switch (compatibility) {
      case 'VERY_SIMILAR':
        return '취향이 매우 비슷해요!';
      case 'SIMILAR':
        return '비슷한 취향을 가지고 있어요';
      case 'NEUTRAL':
        return '보통이에요';
      case 'DIFFERENT':
        return '다른 취향을 가지고 있어요';
      default:
        return '';
    }
  }

  Color get scoreColor {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.grey;
  }
}
```

#### 3.3.2 새 위젯 생성: `lib/widgets/match_score_widget.dart`

```dart
import 'package:flutter/material.dart';
import '../models/match_score_model.dart';

class MatchScoreWidget extends StatelessWidget {
  final MatchScore matchScore;
  final bool showDetails;

  const MatchScoreWidget({
    super.key,
    required this.matchScore,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: matchScore.scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: matchScore.scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: matchScore.scoreColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '취향 궁합',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '${matchScore.score.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: matchScore.scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: matchScore.score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(matchScore.scoreColor),
              minHeight: 8,
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 12),
            Text(
              matchScore.compatibilityText,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '공통 방문 장소: ${matchScore.commonPlacesCount}곳',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

#### 3.3.3 API 서비스 추가: `lib/services/api_service.dart`

```dart
// === Match Score API 추가 ===

/// 특정 사용자와의 Match Score 조회
static Future<MatchScore> getMatchScore(int targetUserId) async {
  final response = await getAuth('/perfacto/api/match-score/$targetUserId');
  return MatchScore.fromJson(response['data']);
}

/// 내 팔로잉 중 Match Score Top 10
static Future<List<Map<String, dynamic>>> getTopMatchScores() async {
  final response = await getAuth('/perfacto/api/match-score/top');
  return List<Map<String, dynamic>>.from(response['data']);
}

/// 전체 사용자 중 Match Score 높은 순 (추천 친구)
static Future<List<Map<String, dynamic>>> getRecommendedFriends({
  int page = 0,
  int size = 20,
}) async {
  final response = await getAuth(
    '/perfacto/api/match-score/recommendations?page=$page&size=$size'
  );
  return List<Map<String, dynamic>>.from(response['data']['content']);
}
```

### 3.4 백엔드 요구사항

#### 3.4.1 새 엔드포인트

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| GET | `/perfacto/api/match-score/{userId}` | - | `MatchScoreResponse` |
| GET | `/perfacto/api/match-score/top` | - | `List<MatchScoreResponse>` |
| GET | `/perfacto/api/match-score/recommendations` | `page, size` | `Page<UserWithMatchScore>` |

#### 3.4.2 Response DTO

```java
// MatchScoreResponse.java
public class MatchScoreResponse {
    private Long userId;
    private Long targetUserId;
    private Double score;
    private Integer commonPlacesCount;
    private String compatibility;  // VERY_SIMILAR, SIMILAR, NEUTRAL, DIFFERENT
    private LocalDateTime calculatedAt;
}

// UserWithMatchScore.java
public class UserWithMatchScore {
    private Long userId;
    private String nickname;
    private String profileImageUrl;
    private Double matchScore;
    private Integer commonPlacesCount;
    private Boolean isFollowing;
}
```

#### 3.4.3 DB 테이블 (캐싱용)

```sql
CREATE TABLE match_scores (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    target_user_id BIGINT NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    common_places_count INT NOT NULL,
    compatibility VARCHAR(20) NOT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_pair (user_id, target_user_id),
    INDEX idx_user_score (user_id, score DESC)
);
```

---

## 4. Phase 2: 예측 점수 시스템

### 4.1 개념

사용자가 **방문하지 않은 장소**에 대해 취향 기반으로 예측 점수를 제공합니다.

```
┌─────────────────────────────────────────────────────────┐
│  장소 상세 페이지                                       │
│                                                         │
│  🏪 맛있는 식당                                         │
│                                                         │
│  ┌─────────────────────────────────────┐               │
│  │  🔮 예측 점수: 8.2점                │               │
│  │  "당신의 취향에 맞을 것 같아요!"    │               │
│  └─────────────────────────────────────┘               │
│                                                         │
│  👥 친구들의 평균: 7.8점 (3명)                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 4.2 알고리즘 (협업 필터링)

```dart
/// 예측 점수 계산 알고리즘
///
/// User-Based Collaborative Filtering:
/// 1. 유사한 취향의 사용자들 찾기 (Match Score 활용)
/// 2. 해당 사용자들의 이 장소 평가 가중 평균 계산
///
/// Formula:
/// predictedScore = Σ(matchScore[i] * rating[i]) / Σ(matchScore[i])

class PredictedScoreCalculator {
  static double calculate({
    required int placeId,
    required List<SimilarUser> similarUsers,
  }) {
    double weightedSum = 0.0;
    double weightSum = 0.0;

    for (final user in similarUsers) {
      final rating = user.getRatingForPlace(placeId);
      if (rating != null) {
        final weight = user.matchScore / 100;  // 0~1 범위로 정규화
        weightedSum += weight * ratingToScore(rating);
        weightSum += weight;
      }
    }

    if (weightSum == 0) return 0.0;
    return weightedSum / weightSum;
  }

  static double ratingToScore(String rating) {
    switch (rating) {
      case 'GOOD': return 8.5;
      case 'NEUTRAL': return 5.5;
      case 'BAD': return 2.5;
      default: return 5.0;
    }
  }
}
```

### 4.3 프론트엔드 구현

#### 4.3.1 새 모델: `lib/models/predicted_score_model.dart`

```dart
class PredictedScore {
  final int placeId;
  final double score;
  final double confidence;  // 신뢰도 (0~1)
  final int basedOnUsers;   // 계산에 사용된 유사 사용자 수
  final String recommendation;

  PredictedScore({
    required this.placeId,
    required this.score,
    required this.confidence,
    required this.basedOnUsers,
    required this.recommendation,
  });

  factory PredictedScore.fromJson(Map<String, dynamic> json) {
    return PredictedScore(
      placeId: json['placeId'],
      score: json['score'].toDouble(),
      confidence: json['confidence'].toDouble(),
      basedOnUsers: json['basedOnUsers'],
      recommendation: json['recommendation'],
    );
  }

  String get scoreText => score.toStringAsFixed(1);

  String get confidenceText {
    if (confidence >= 0.8) return '매우 정확';
    if (confidence >= 0.6) return '정확';
    if (confidence >= 0.4) return '보통';
    return '참고용';
  }

  Color get scoreColor {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.lightGreen;
    if (score >= 4.0) return Colors.orange;
    return Colors.red;
  }
}
```

#### 4.3.2 새 위젯: `lib/widgets/predicted_score_widget.dart`

```dart
class PredictedScoreWidget extends StatelessWidget {
  final PredictedScore predictedScore;

  const PredictedScoreWidget({super.key, required this.predictedScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 점수 표시
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: predictedScore.scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                predictedScore.scoreText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
                    const SizedBox(width: 4),
                    const Text(
                      '예측 점수',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        predictedScore.confidenceText,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  predictedScore.recommendation,
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  '${predictedScore.basedOnUsers}명의 유사 취향 기반',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 4.3.3 API 서비스 추가

```dart
/// 장소의 예측 점수 조회
static Future<PredictedScore?> getPredictedScore(int placeId) async {
  try {
    final response = await getAuth('/perfacto/api/predicted-score/$placeId');
    return PredictedScore.fromJson(response['data']);
  } catch (e) {
    // 로그인 안 했거나 데이터 부족 시 null 반환
    return null;
  }
}

/// 여러 장소의 예측 점수 일괄 조회
static Future<Map<int, PredictedScore>> getPredictedScoresBatch(
  List<int> placeIds
) async {
  final response = await postAuth('/perfacto/api/predicted-score/batch', {
    'placeIds': placeIds,
  });

  final Map<int, PredictedScore> result = {};
  for (final item in response['data']) {
    result[item['placeId']] = PredictedScore.fromJson(item);
  }
  return result;
}
```

### 4.4 백엔드 요구사항

| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| GET | `/perfacto/api/predicted-score/{placeId}` | - | `PredictedScoreResponse` |
| POST | `/perfacto/api/predicted-score/batch` | `{placeIds: []}` | `List<PredictedScoreResponse>` |

---

## 5. Phase 3: 카테고리 세분화

### 5.1 Beli 스타일 5대 카테고리

```dart
enum PlaceCategory {
  RESTAURANT('restaurant', '음식점', '🍽️', Colors.orange),
  BAR('bar', '바', '🍺', Colors.amber),
  BAKERY('bakery', '베이커리', '🥐', Colors.brown),
  COFFEE_TEA('coffee_tea', '카페', '☕', Colors.brown),
  DESSERT('dessert', '디저트', '🍦', Colors.pink);

  final String code;
  final String label;
  final String emoji;
  final Color color;

  const PlaceCategory(this.code, this.label, this.emoji, this.color);

  static PlaceCategory fromCode(String code) {
    return PlaceCategory.values.firstWhere(
      (c) => c.code == code,
      orElse: () => PlaceCategory.RESTAURANT,
    );
  }
}
```

### 5.2 UI 변경사항

#### 5.2.1 홈 화면 카테고리 탭

```dart
// home_page.dart 수정

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: PlaceCategory.values.length,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 카테고리 탭 바
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: PlaceCategory.values.map((category) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji),
                    const SizedBox(width: 4),
                    Text(category.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        // 탭 내용
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: PlaceCategory.values.map((category) {
              return PlaceListView(category: category);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
```

### 5.3 데이터 마이그레이션

```sql
-- 기존 카테고리를 새 5대 카테고리로 매핑
UPDATE places SET category_code = CASE
    WHEN category_name IN ('한식', '중식', '일식', '양식', '분식') THEN 'restaurant'
    WHEN category_name IN ('술집', '호프', '바') THEN 'bar'
    WHEN category_name IN ('베이커리', '빵집') THEN 'bakery'
    WHEN category_name IN ('카페', '커피숍') THEN 'coffee_tea'
    WHEN category_name IN ('디저트', '아이스크림', '케이크') THEN 'dessert'
    ELSE 'restaurant'
END;
```

---

## 6. Phase 4: 태그 시스템

### 6.1 태그 종류

```dart
enum PlaceTag {
  // 분위기
  DATE_NIGHT('date_night', '데이트', '💕'),
  BUSINESS('business', '비즈니스', '💼'),
  CASUAL('casual', '캐주얼', '👕'),
  COZY('cozy', '아늑한', '🛋️'),
  TRENDY('trendy', '트렌디', '✨'),

  // 상황
  BRUNCH('brunch', '브런치', '🍳'),
  LATE_NIGHT('late_night', '야식', '🌙'),
  SOLO('solo', '혼밥', '🙋'),
  GROUP('group', '단체', '👥'),
  FAMILY('family', '가족', '👨‍👩‍👧'),

  // 특징
  VIEW('view', '뷰맛집', '🏞️'),
  PET_FRIENDLY('pet_friendly', '반려동물', '🐕'),
  PARKING('parking', '주차가능', '🅿️'),
  RESERVATION('reservation', '예약필수', '📅'),
  WAITING('waiting', '웨이팅', '⏰');

  final String code;
  final String label;
  final String emoji;

  const PlaceTag(this.code, this.label, this.emoji);
}
```

### 6.2 태그 선택 UI

```dart
class TagSelector extends StatefulWidget {
  final List<PlaceTag> selectedTags;
  final Function(List<PlaceTag>) onChanged;
  final int maxSelection;

  const TagSelector({
    super.key,
    required this.selectedTags,
    required this.onChanged,
    this.maxSelection = 5,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PlaceTag.values.map((tag) {
        final isSelected = widget.selectedTags.contains(tag);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tag.emoji),
              const SizedBox(width: 4),
              Text(tag.label),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected && widget.selectedTags.length >= widget.maxSelection) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('최대 ${widget.maxSelection}개까지 선택 가능합니다')),
              );
              return;
            }

            final newTags = List<PlaceTag>.from(widget.selectedTags);
            if (selected) {
              newTags.add(tag);
            } else {
              newTags.remove(tag);
            }
            widget.onChanged(newTags);
          },
        );
      }).toList(),
    );
  }
}
```

### 6.3 리뷰 작성 시 태그 추가

```dart
// review_write_page.dart에 태그 선택 섹션 추가

List<PlaceTag> _selectedTags = [];

// UI에 추가
const Text(
  '이 장소의 특징을 선택해주세요 (선택)',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
),
const SizedBox(height: 12),
TagSelector(
  selectedTags: _selectedTags,
  onChanged: (tags) {
    setState(() {
      _selectedTags = tags;
    });
  },
),
```

### 6.4 API 변경

```dart
// createReview에 tags 파라미터 추가
static Future<Map<String, dynamic>> createReview({
  required int placeId,
  required String overallRating,
  required List<String> reasons,
  List<String>? tags,  // 추가
  int? comparedPlaceId,
  String? comparisonResult,
}) async {
  final Map<String, dynamic> body = {
    'placeId': placeId,
    'overallRating': overallRating,
    'reasons': reasons,
    if (tags != null && tags.isNotEmpty) 'tags': tags,
    if (comparedPlaceId != null) 'comparedPlaceId': comparedPlaceId,
    if (comparisonResult != null) 'comparisonResult': comparisonResult,
  };

  final response = await postAuth('/perfacto/api/reviews', body);
  return response['data'];
}
```

---

## 7. Phase 5: 게이미피케이션

### 7.1 리더보드 시스템

#### 7.1.1 새 모델: `lib/models/leaderboard_model.dart`

```dart
class LeaderboardEntry {
  final int rank;
  final int userId;
  final String nickname;
  final String? profileImageUrl;
  final int reviewCount;
  final int totalPoints;
  final int currentStreak;
  final int? rankChange;  // +2, -1, null(변동없음)

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.reviewCount,
    required this.totalPoints,
    required this.currentStreak,
    this.rankChange,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      userId: json['userId'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      reviewCount: json['reviewCount'],
      totalPoints: json['totalPoints'],
      currentStreak: json['currentStreak'],
      rankChange: json['rankChange'],
    );
  }
}
```

#### 7.1.2 새 페이지: `lib/pages/leaderboard_page.dart`

```dart
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _globalLeaderboard = [];
  List<LeaderboardEntry> _cityLeaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getGlobalLeaderboard(),
        ApiService.getCityLeaderboard('포항'),
      ]);
      setState(() {
        _globalLeaderboard = results[0];
        _cityLeaderboard = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리더보드'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '🌍 전체'),
            Tab(text: '📍 포항'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(_globalLeaderboard),
                _buildLeaderboardList(_cityLeaderboard),
              ],
            ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LeaderboardTile(entry: entry);
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildRankBadge(),
      title: Text(entry.nickname),
      subtitle: Text('리뷰 ${entry.reviewCount}개 · 🔥 ${entry.currentStreak}일'),
      trailing: _buildRankChange(),
    );
  }

  Widget _buildRankBadge() {
    Color bgColor;
    switch (entry.rank) {
      case 1:
        bgColor = Colors.amber;
        break;
      case 2:
        bgColor = Colors.grey[400]!;
        break;
      case 3:
        bgColor = Colors.brown[300]!;
        break;
      default:
        bgColor = Colors.grey[200]!;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${entry.rank}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: entry.rank <= 3 ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget? _buildRankChange() {
    if (entry.rankChange == null || entry.rankChange == 0) return null;

    final isUp = entry.rankChange! > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: isUp ? Colors.green : Colors.red,
        ),
        Text(
          '${entry.rankChange!.abs()}',
          style: TextStyle(
            color: isUp ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

### 7.2 Streak 시스템

#### 7.2.1 새 모델: `lib/models/streak_model.dart`

```dart
class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReviewDate;
  final bool reviewedToday;
  final int hoursUntilStreakBreak;

  UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastReviewDate,
    required this.reviewedToday,
    required this.hoursUntilStreakBreak,
  });

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      lastReviewDate: json['lastReviewDate'] != null
          ? DateTime.parse(json['lastReviewDate'])
          : null,
      reviewedToday: json['reviewedToday'],
      hoursUntilStreakBreak: json['hoursUntilStreakBreak'],
    );
  }

  String get streakEmoji {
    if (currentStreak >= 30) return '🔥🔥🔥';
    if (currentStreak >= 14) return '🔥🔥';
    if (currentStreak >= 7) return '🔥';
    return '✨';
  }

  String get motivationMessage {
    if (reviewedToday) {
      return '오늘 리뷰 완료! 내일도 이어가세요!';
    }
    if (hoursUntilStreakBreak <= 6) {
      return '⚠️ Streak이 ${hoursUntilStreakBreak}시간 후 끊겨요!';
    }
    return '오늘 리뷰를 작성해서 Streak을 이어가세요!';
  }
}
```

#### 7.2.2 Streak 위젯

```dart
class StreakWidget extends StatelessWidget {
  final UserStreak streak;
  final VoidCallback onWriteReview;

  const StreakWidget({
    super.key,
    required this.streak,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = !streak.reviewedToday && streak.hoursUntilStreakBreak <= 6;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [Colors.orange.shade100, Colors.red.shade100]
              : [Colors.orange.shade50, Colors.yellow.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red.shade300 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                streak.streakEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 8),
              Text(
                '${streak.currentStreak}일',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            streak.motivationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUrgent ? Colors.red : Colors.grey[700],
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (!streak.reviewedToday) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onWriteReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('리뷰 작성하기'),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '최장 기록: ${streak.longestStreak}일',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 7.3 잠금 해제 시스템

```dart
enum UnlockableFeature {
  SCORES('scores', '점수 보기', 10, '리뷰 10개 작성'),
  MATCH_SCORE('match_score', '취향 궁합', 15, '리뷰 15개 작성'),
  PREDICTED_SCORE('predicted_score', '예측 점수', 20, '리뷰 20개 작성'),
  LEADERBOARD('leaderboard', '리더보드', 25, '리뷰 25개 작성'),
  ADVANCED_STATS('advanced_stats', '상세 통계', 50, '리뷰 50개 작성');

  final String code;
  final String label;
  final int requiredReviews;
  final String description;

  const UnlockableFeature(this.code, this.label, this.requiredReviews, this.description);
}

class FeatureUnlockService {
  static bool isUnlocked(UnlockableFeature feature, int userReviewCount) {
    return userReviewCount >= feature.requiredReviews;
  }

  static int getProgress(UnlockableFeature feature, int userReviewCount) {
    return ((userReviewCount / feature.requiredReviews) * 100).clamp(0, 100).toInt();
  }
}
```

### 7.4 API 엔드포인트

```dart
// API Service 추가

/// 글로벌 리더보드 조회
static Future<List<LeaderboardEntry>> getGlobalLeaderboard({
  int page = 0,
  int size = 50,
}) async {
  final response = await get('/perfacto/every/leaderboard/global?page=$page&size=$size');
  return (response['data']['content'] as List)
      .map((e) => LeaderboardEntry.fromJson(e))
      .toList();
}

/// 도시별 리더보드 조회
static Future<List<LeaderboardEntry>> getCityLeaderboard(
  String city, {
  int page = 0,
  int size = 50,
}) async {
  final response = await get('/perfacto/every/leaderboard/city/$city?page=$page&size=$size');
  return (response['data']['content'] as List)
      .map((e) => LeaderboardEntry.fromJson(e))
      .toList();
}

/// 내 Streak 정보 조회
static Future<UserStreak> getMyStreak() async {
  final response = await getAuth('/perfacto/api/streak');
  return UserStreak.fromJson(response['data']);
}

/// 내 잠금 해제 상태 조회
static Future<Map<String, bool>> getUnlockedFeatures() async {
  final response = await getAuth('/perfacto/api/features/unlocked');
  return Map<String, bool>.from(response['data']);
}
```

---

## 8. Phase 6: SNS 연동

### 8.1 Instagram/TikTok 장소 추가

```dart
// 딥링크 처리를 통한 SNS 장소 추가
// Instagram/TikTok에서 공유 시 Perfacto 앱으로 연결

class SnsIntegrationService {
  /// 공유된 URL에서 장소 정보 추출
  static Future<Map<String, dynamic>?> extractPlaceFromUrl(String url) async {
    try {
      final response = await ApiService.post('/perfacto/api/sns/extract', {
        'url': url,
      });
      return response['data'];
    } catch (e) {
      return null;
    }
  }

  /// Want to Try 리스트에 추가
  static Future<void> addToWantToTry({
    required String placeName,
    required String? address,
    required String sourceUrl,
    required String sourcePlatform, // 'instagram', 'tiktok'
  }) async {
    await ApiService.postAuth('/perfacto/api/want-to-try/from-sns', {
      'placeName': placeName,
      'address': address,
      'sourceUrl': sourceUrl,
      'sourcePlatform': sourcePlatform,
    });
  }
}
```

### 8.2 카카오 공유

```dart
// 기존 share_plus 대신 카카오 SDK 활용
// pubspec.yaml에 추가: kakao_flutter_sdk_share: ^1.9.0

import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

class KakaoShareService {
  static Future<void> sharePlace({
    required String placeName,
    required double score,
    required String? imageUrl,
    required String deepLink,
  }) async {
    final template = FeedTemplate(
      content: Content(
        title: placeName,
        description: '내 점수: ${score.toStringAsFixed(1)}점',
        imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
        link: Link(
          webUrl: Uri.parse(deepLink),
          mobileWebUrl: Uri.parse(deepLink),
        ),
      ),
      buttons: [
        Button(
          title: 'Perfacto에서 보기',
          link: Link(
            webUrl: Uri.parse(deepLink),
            mobileWebUrl: Uri.parse(deepLink),
          ),
        ),
      ],
    );

    if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
      await ShareClient.instance.shareDefault(template: template);
    }
  }
}
```

---

## 9. API 엔드포인트 명세

### 9.1 신규 엔드포인트 전체 목록

| Phase | Method | Endpoint | 설명 |
|-------|--------|----------|------|
| 1 | GET | `/api/match-score/{userId}` | 특정 사용자와 Match Score |
| 1 | GET | `/api/match-score/top` | 팔로잉 중 Top 10 |
| 1 | GET | `/api/match-score/recommendations` | 추천 친구 |
| 2 | GET | `/api/predicted-score/{placeId}` | 장소 예측 점수 |
| 2 | POST | `/api/predicted-score/batch` | 일괄 예측 점수 |
| 5 | GET | `/every/leaderboard/global` | 글로벌 리더보드 |
| 5 | GET | `/every/leaderboard/city/{city}` | 도시별 리더보드 |
| 5 | GET | `/api/streak` | 내 Streak 정보 |
| 5 | GET | `/api/features/unlocked` | 해금된 기능 목록 |
| 6 | POST | `/api/sns/extract` | SNS URL에서 장소 추출 |
| 6 | POST | `/api/want-to-try/from-sns` | SNS에서 위시리스트 추가 |

### 9.2 기존 엔드포인트 수정

| Method | Endpoint | 변경사항 |
|--------|----------|----------|
| POST | `/api/reviews` | `tags` 필드 추가 |
| GET | `/every/places/category/{id}` | 5대 카테고리 코드 지원 |
| GET | `/every/places/{id}` | `tags`, `predictedScore` 필드 추가 |

---

## 10. 데이터베이스 스키마

### 10.1 신규 테이블

```sql
-- Match Score 캐시
CREATE TABLE match_scores (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    target_user_id BIGINT NOT NULL,
    score DECIMAL(5,2) NOT NULL,
    common_places_count INT NOT NULL,
    compatibility VARCHAR(20) NOT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_pair (user_id, target_user_id),
    INDEX idx_user_score (user_id, score DESC),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)
);

-- 사용자 Streak
CREATE TABLE user_streaks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_review_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 리더보드 (주간 스냅샷)
CREATE TABLE leaderboard_snapshots (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    city VARCHAR(50),
    rank_global INT,
    rank_city INT,
    review_count INT NOT NULL,
    total_points INT NOT NULL,
    snapshot_date DATE NOT NULL,
    INDEX idx_date_global (snapshot_date, rank_global),
    INDEX idx_date_city (snapshot_date, city, rank_city),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 장소 태그
CREATE TABLE place_tags (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    place_id BIGINT NOT NULL,
    tag_code VARCHAR(30) NOT NULL,
    count INT DEFAULT 1,
    UNIQUE KEY unique_place_tag (place_id, tag_code),
    INDEX idx_place (place_id),
    FOREIGN KEY (place_id) REFERENCES places(id)
);

-- 리뷰-태그 연결
CREATE TABLE review_tags (
    review_id BIGINT NOT NULL,
    tag_code VARCHAR(30) NOT NULL,
    PRIMARY KEY (review_id, tag_code),
    FOREIGN KEY (review_id) REFERENCES reviews(id)
);

-- SNS 위시리스트
CREATE TABLE want_to_try_sns (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    place_name VARCHAR(200) NOT NULL,
    address VARCHAR(500),
    source_url VARCHAR(1000),
    source_platform VARCHAR(20),
    matched_place_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (matched_place_id) REFERENCES places(id)
);
```

### 10.2 기존 테이블 수정

```sql
-- places 테이블에 카테고리 코드 추가
ALTER TABLE places ADD COLUMN category_code VARCHAR(20) DEFAULT 'restaurant';
ALTER TABLE places ADD INDEX idx_category_code (category_code);

-- users 테이블에 총 포인트 추가
ALTER TABLE users ADD COLUMN total_points INT DEFAULT 0;
ALTER TABLE users ADD COLUMN review_count INT DEFAULT 0;
```

---

## 구현 체크리스트

### Phase 1: Match Score
- [ ] `lib/models/match_score_model.dart` 생성
- [ ] `lib/widgets/match_score_widget.dart` 생성
- [ ] `lib/services/api_service.dart`에 Match Score API 추가
- [ ] `lib/pages/friends_page.dart` 수정 (Match Score 표시)
- [ ] `lib/pages/user_profile_page.dart` 생성/수정
- [ ] 백엔드: Match Score 계산 로직 구현
- [ ] 백엔드: match_scores 테이블 생성
- [ ] 백엔드: API 엔드포인트 구현

### Phase 2: 예측 점수
- [ ] `lib/models/predicted_score_model.dart` 생성
- [ ] `lib/widgets/predicted_score_widget.dart` 생성
- [ ] `lib/services/api_service.dart`에 예측 점수 API 추가
- [ ] `lib/pages/place_detail_page.dart` 수정
- [ ] 백엔드: 협업 필터링 알고리즘 구현
- [ ] 백엔드: API 엔드포인트 구현

### Phase 3: 카테고리 세분화
- [ ] `lib/models/category_model.dart` 생성/수정
- [ ] `lib/pages/home_page.dart` 수정 (카테고리 탭)
- [ ] 백엔드: 카테고리 데이터 마이그레이션
- [ ] 백엔드: API 응답 수정

### Phase 4: 태그 시스템
- [ ] `lib/models/tag_model.dart` 생성
- [ ] `lib/widgets/tag_selector.dart` 생성
- [ ] `lib/pages/review_write_page.dart` 수정
- [ ] `lib/pages/place_detail_page.dart` 수정 (태그 표시)
- [ ] 백엔드: 태그 테이블 생성
- [ ] 백엔드: 리뷰 API 수정

### Phase 5: 게이미피케이션
- [ ] `lib/models/leaderboard_model.dart` 생성
- [ ] `lib/models/streak_model.dart` 생성
- [ ] `lib/pages/leaderboard_page.dart` 생성
- [ ] `lib/widgets/streak_widget.dart` 생성
- [ ] `lib/services/feature_unlock_service.dart` 생성
- [ ] `lib/pages/my_page.dart` 수정 (Streak 표시)
- [ ] 백엔드: Streak 계산 로직 (스케줄러)
- [ ] 백엔드: 리더보드 스냅샷 로직 (스케줄러)
- [ ] 백엔드: API 엔드포인트 구현

### Phase 6: SNS 연동
- [ ] `lib/services/sns_integration_service.dart` 생성
- [ ] `lib/services/kakao_share_service.dart` 생성
- [ ] 딥링크 설정 (Android/iOS)
- [ ] pubspec.yaml에 kakao SDK 추가
- [ ] 백엔드: SNS URL 파싱 로직
- [ ] 백엔드: API 엔드포인트 구현

---

## 참고 자료

- [Beli App - App Store](https://apps.apple.com/us/app/beli/id1478375386)
- [Design Critique: Beli App](https://ixd.prattsi.org/2024/09/design-critique-beli-app/)
- [ELO Rating System](https://en.wikipedia.org/wiki/Elo_rating_system)
- [Collaborative Filtering](https://en.wikipedia.org/wiki/Collaborative_filtering)

---

**문서 버전**: 1.0
**최종 수정일**: 2026-02-05
**작성자**: Claude (Anthropic)
