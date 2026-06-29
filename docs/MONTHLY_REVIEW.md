# CHAPTER — 월간 리포트 UX 스펙

> **목적:** 월간 리포트의 목표 UX·엣지 케이스·구현 단계를 추적하기 위한 문서  
> **마지막 갱신:** 2026-06-29  
> **상태:** 스펙 확정 전 (코드 미반영)  
> **관련:** [STORY_MODEL.md](./STORY_MODEL.md) · [AI_FALLBACK.md](./AI_FALLBACK.md) §10 월간 리포트

---

## 제품 원칙 (챕터와의 관계)

> **월간 리포트 = 정기 락인 · 챕터 = 드문 서프라이즈** — 상세는 [STORY_MODEL.md](./STORY_MODEL.md)

| | 월간 리포트 | 완성 챕터 |
|--|------------|-----------|
| 빈도 | 매달 | 가끔 |
| 공개 | 말일 reveal → **월별 아카이브** | 백그라운드 봉인 → **짜잔** → 챕터 리스트 |
| 진행 중 | 이번 달 내용 **숨김** | whisper만, **리스트 없음** |
| 실물 책 | (간접) 날짜순 일기와 별개 | 앱 전용, 인쇄본에 챕터 틀 없음 |

월간이 **기대의 중심**, 챕터는 **보너스** — 매일 주제가 섞여도 월간이 “이번 달 전체”를 정리한다.

---

## 목표 UX (한 줄)

**이번 달은 말일에만 “짜잔”으로 공개하고, 지나간 달 리포트만 리스트로 본다.**

---

## 현재 구현 (as-is)

| 항목 | 현재 동작 | 관련 코드 |
|------|-----------|-----------|
| 기간 | **최근 30일 롤링** (달력 월 아님) | `StoryArcEngine.generateMonthlyReview` → `_entriesInLastDays(30)` |
| 저장 | **단일 리포트 1개** (`monthly_review` 키) | `LocalStoryArcService._cachedReview` |
| 생성 시점 | `MonthlyReviewScreen` **열 때마다** `refreshMonthlyReview()` | `monthly_review_screen.dart` |
| 더보기 표시 | 리포트 있으면 “최근 30일 Story Arc 요약” | `more_screen.dart` |
| 공개 방식 | 언제든 상세 전체 노출 | — |
| 알림 | 없음 | — |
| AI | Gemini → 실패 시 `_fallbackMonthlyReview` | `ai_journal_service.dart`, `story_arc_engine.dart` |

### 현재 문제

1. **진행 중인 달**처럼 보임 — 매번 최근 30일을 다시 요약해 “이번 달 리포트” 느낌
2. **과거 리포트 없음** — 새로 생성하면 이전 리포트 덮어씀
3. **말일 reveal 없음** — 챕터 완성(`ChapterRevealOverlay`)과 톤 불일치
4. **수동 새로고침** — refresh 버튼으로 즉시 재생성 가능

---

## 목표 UX (to-be)

### 화면 구조

```
더보기 → 월간 리포트
├── [이번 달]  ← 리스트에 안 나옴 (내용 미공개)
│     └── “이번 달 이야기는 말일에 열려요” (진행 중 힌트만, 요약·주제 없음)
├── [지난 리포트 목록]  ← 완성된 달만
│     ├── 2026년 5월
│     ├── 2026년 4월
│     └── …
└── (말일 또는 첫 접속 시) 풀스크린 reveal → 상세
```

### 공개 규칙

| 시점 | 사용자에게 보이는 것 |
|------|---------------------|
| 월 1일 ~ 말일 전 | 이번 달 리포트 **없음**. 진행 힌트만 (선택) |
| **말일** (또는 정책상 “공개일”) | 해당 월 리포트 **생성 + reveal 1회** |
| reveal 이후 | 해당 월이 **아카이브 리스트**에 추가, 탭하면 상세 |

### 기간 정의

- **캘린더 월** 기준: `periodKey = "yyyy-MM"` (예: `2026-06`)
- 집계 범위: 해당 월 1일 00:00 ~ 말일 23:59 (로컬 타임존)
- 최소 기록 수: **3일 이상** (현행과 동일, 미달 시 리포트 미생성 또는 “이번 달은 기록이 적어요” 빈 상태 정책 결정 필요)

### Reveal UX (참고)

- 챕터 완성 `ChapterRevealOverlay`와 동일한 톤: 종이 질감, 짧은 카피, “열어보기”
- `pendingMonthlyReveal` — 앱당 **월별 1회만** reveal (이미 본 달은 리스트에서 바로 상세)

---

## Q1. 말일에 접속을 안 하면?

**앱을 안 열면 그 순간 화면에 “짜잔”을 띄울 수는 없다.**  
대신 아래 정책으로 **늦게 열어도 한 번은 reveal** 한다.

### 권장 정책 (Phase 1)

```
IF 이전 달(periodKey) 리포트가 아직 없음
   AND (오늘 >= 그 달 말일 OR 이미 다음 달)
   AND 해당 월 기록 >= 3일
THEN
   리포트 생성
   pendingMonthlyReveal = 해당 periodKey
   다음 홈/앱 foreground 시 reveal 1회
```

| 시나리오 | 동작 |
|----------|------|
| 6/30 접속 | 6월 리포트 생성 + reveal |
| 6/30 미접속, 7/3 첫 접속 | 6월 리포트 생성 + “6월 이야기가 도착했어요” reveal |
| 6월 기록 0~2일 | 리포트 미생성 (또는 빈 리포트 — **정책 미정**, 아래 §미결정) |
| reveal 후 다시 열기 | 아카이브 리스트에서만 조회, reveal 없음 |

### 로컬 알림 (Phase 2, 선택)

- 말일 **20:00** (시간은 설정 가능): “이번 달 이야기가 정리됐어요”
- **탭 시:** 앱 실행 → 생성(아직 없으면) → reveal
- **탭 안 함:** Q1 정책대로 **다음 접속 시** reveal

알림 구현 후보: 기존 `DailyReminderService` (`flutter_local_notifications`) 패턴 확장 — **매월 말일 1회** `zonedSchedule`, 앱 실행 시 **다음 달 말일** 재스케줄.

---

## Q2. 월말 정해진 시간에 만들고 푸시 — 백엔드 필요?

**목표를 나눠서 본다.**

| 목표 | 백엔드 필요? | 비고 |
|------|-------------|------|
| 말일 **알림만** (앱 안 켜도) | **아니오** | 로컬 예약 알림으로 가능 |
| 말일 정각 **리포트 자동 생성** (앱 미실행) | **예 (권장)** | 백그라운드 Gemini·저장은 iOS/Android 제한 큼 |
| **다음 접속 시** 생성 + reveal | **아니오** | Phase 1 MVP |
| 여러 기기에서 **동일 리포트** | **예 (권장)** | Firestore `monthly_reviews` 컬렉션 |

### 로컬만 (Phase 1~2)

- 생성: **앱이 실행될 때** (말일 당일 또는 그 이후 첫 실행)
- 푸시: 로컬 알림 = “리포트 열렸어요” **리마인더** (생성은 탭/실행 시)
- 한계: 사용자가 한 달 내내 앱을 안 열면 알림도 스케줄 안 될 수 있음 → **다음 실행 시** 보상

### 백엔드 (Phase 3)

```
Cloud Scheduler (예: 매월 1일 00:05 Asia/Seoul)
  → Cloud Functions
      → users/{uid}/entries (해당 월) 조회
      → Gemini API (서버 키, AI_FALLBACK 규칙 폴백)
      → users/{uid}/monthly_reviews/{yyyy-MM} 저장
      → FCM 푸시: "지난달 이야기가 정리됐어요"
  → 앱: Firestore 구독 또는 pull → reveal 플래그
```

**백엔드가 필요한 이유**

- iOS는 백그라운드에서 임의 시각 Dart 실행·네트워크 **매우 제한**
- `Workmanager` 등으로도 Gemini 호출 **신뢰도 낮음**
- “말일 23:00 정각, 앱 안 켜도 생성 완료”는 **서버 스케줄**이 사실상 표준

---

## 데이터 모델 (제안)

### `MonthlyReview` 확장

```dart
// 제안 필드 (구현 시 반영)
periodKey: String      // "2026-06"
periodLabel: String    // "2026년 6월" (표시용)
generatedAt: DateTime
revealedAt: DateTime?  // reveal 본 시각
topTopics, summary, growth, emotionTrend, chapterChanges  // 기존 유지
```

### 저장 위치 (제안)

| 계층 | Phase 1 | Phase 3 |
|------|---------|---------|
| 로컬 | `List<MonthlyReview>` JSON (`monthly_reviews_archive`) | 동일 + 마이그레이션 |
| 클라우드 | `story_arc_meta.monthlyReview` 단일 (현행) | `users/{uid}/monthly_reviews/{periodKey}` |
| AppState | `archivedMonthlyReviews`, `pendingMonthlyReveal` | + Firestore stream |

### 마이그레이션

- 기존 단일 `monthly_review` → `periodKey` 추정(`generatedAt` 기준 월) 후 아카이브 1건으로 이전 또는 폐기 (**정책 미정**)

---

## UI 스펙 (제안)

### 더보기 타일

| 상태 | subtitle |
|------|----------|
| 이번 달 진행 중 | `말일에 이번 달 이야기가 열려요` |
| 지난 리포트 N개 | `지난 리포트 ${N}개` |
| reveal 대기 | (배지/점 — 선택) |

### 월간 리포트 화면

- 상단: 이번 달 카드 (내용 없음, 말일 카운트다운 또는 문구만)
- 하단: `ListView` — `periodLabel` + 한 줄 요약 미리보기
- **refresh 버튼 제거** 또는 “지난 달 다시 만들기”는 **개발자 전용**으로 숨김
- 상세: 기존 `_Section` 레이아웃 재사용

### Reveal 오버레이

- `ChapterRevealOverlay` 패턴 참고
- 카피 예: `6월의 이야기가 한 권으로 모였어요`
- CTA: `펼쳐보기` → `MonthlyReviewDetailScreen(periodKey)`

---

## 생성 로직 (제안)

### 트리거

1. **앱 `initialize()` 완료 후** — `checkPendingMonthlyReview()`
2. **(Phase 2)** 로컬 알림 탭 → deep link `chapter://monthly-review?period=yyyy-MM`
3. **(Phase 3)** FCM data message → 동일

### 생성 조건 (`shouldGenerateForPeriod`)

```
period = 이전 달 또는 (오늘이 말일이면 이번 달)
NOT archivedReviews.contains(periodKey)
entriesInMonth(period) >= 3
```

### AI

- 기존 `StoryArcEngine.generateMonthlyReview`를 **월 단위 window**로 변경
- Gemini / `_fallbackMonthlyReview` — [AI_FALLBACK.md](./AI_FALLBACK.md) §10 동일

---

## 콘텐츠·락인 전략 (제안)

통계 나열이 아니라 **“한 달 뒤에야 알게 되는 나”** — 짧고 하나의 놀라움에 집중.

### 사람이 한 달 뒤 궁금해하는 것

- 이번 달 **무드·패턴** (정체성)
- **언제 분위기가 바뀌었는지** (서사)
- **잊었던 순간** (깜짝)
- 작년 같은 달과 **뭐가 달라졌는지** (성장)

피할 것: streak, 기록 부족 비난, Spotify Wrapped식 과한 그래픽.

### 추천 리포트 구조 (reveal 후 1스크롤)

1. **이번 달 제목** (대형) — 무드·Arc·말/사진 비율 기반
2. **전환점 하루** — emotion/topics 급변일 + 그날 한 줄·사진
3. **말 vs 장면** — “사진만 남긴 날 N · 글 쓴 날 M”
4. **이번 달 이야기 1개** — 지배 Story Arc (주제 5개 나열 ❌)
5. **잊었던 한 장** — 월 중반·메모 없는 사진 1장
6. **(있으면)** 작년 같은 달 vs 올해 한 줄
7. **다음 달 예고** — 진행 중 Arc whisper 1줄

### 완성 챕터와의 연동

- `chapterChanges`: 그 달 **완성된 챕터 제목**만 언급 (챕터 본문 중복 ❌)
- 챕터가 0개인 달도 많음 → 월간만으로도 완결

### 기록 3일 미만

*「조용한 한 달이었어요」* — 비난 없이 톤 유지 ([§미결정](#미결정-사항-결정-필요) 참고).

---

## 구현 단계

### Phase 1 — 앱만 (MVP)

- [ ] `periodKey` + 아카이브 리스트
- [ ] 말일/이후 첫 실행 시 생성
- [ ] `pendingMonthlyReveal` + reveal 오버레이
- [ ] 화면: 과거 리스트만 + 이번 달 힌트
- [ ] `refreshMonthlyReview` 즉시 재생성 제거
- [ ] 단일 `monthlyReview` → 아카이브 마이그레이션

### Phase 2 — 로컬 알림

- [ ] 말일 예약 알림 (`DailyReminderService` 확장 또는 `MonthlyReviewReminderService`)
- [ ] 앱 실행 시 다음 말일 재스케줄
- [ ] 알림 탭 → reveal 플로우

### Phase 3 — 백엔드

- [ ] Firestore `monthly_reviews` 컬렉션 + rules
- [ ] Cloud Functions 스케줄 + Gemini
- [ ] FCM
- [ ] 앱: 서버 생성 리포트 우선, 로컬은 캐시

---

## 미결정 사항 (결정 필요)

| # | 질문 | 후보 |
|---|------|------|
| 1 | 기록 3일 미만인 달 | 리포트 없음 / “조용한 한 달” 빈 리포트 |
| 2 | 말일 정의 | 달력 말일 0:00~23:59 / 말일 20:00 이후만 공개 |
| 3 | 이번 달 진행 힌트 | 문구만 / 기록 일수만 / 아무것도 안 보임 |
| 4 | 기존 단일 `monthly_review` 데이터 | 마이그레이션 / 삭제 |
| 5 | 타임존 | 기기 로컬 / Asia/Seoul 고정 |
| 6 | reveal 스킵 | 리스트에서 바로 열기 허용 여부 |

---

## 관련 소스 (현행)

| 역할 | 경로 |
|------|------|
| 모델 | `lib/models/monthly_review.dart` |
| 생성 | `lib/services/story_arc_engine.dart` `generateMonthlyReview` |
| Gemini | `lib/services/ai_journal_service.dart` `generateMonthlyReview` |
| 로컬 저장 | `lib/services/local_story_arc_service.dart` `saveMonthlyReview` |
| AppState | `lib/providers/app_state.dart` `refreshMonthlyReview` |
| UI | `lib/screens/more/monthly_review_screen.dart` |
| 더보기 진입 | `lib/screens/more/more_screen.dart` |
| Reveal 참고 | `lib/widgets/chapter_reveal_overlay.dart` |
| 로컬 알림 참고 | `lib/services/daily_reminder_service.dart` |

---

## 문서 업데이트 체크리스트

구현·정책 변경 시:

1. §미결정 사항 결정 반영
2. Phase 체크리스트 갱신
3. [STORY_MODEL.md](./STORY_MODEL.md) 제품 원칙·챕터 관계 동기화
4. [AI_FALLBACK.md](./AI_FALLBACK.md) §10 트리거/기간 설명 동기화
5. **마지막 갱신** 날짜 수정
