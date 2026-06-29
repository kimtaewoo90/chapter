# CHAPTER — AI 사용처 & 크레딧 없을 때 폴백

> **목적:** Gemini API가 없거나 크레딧이 소진됐을 때 앱이 어떻게 동작하는지 추적·업데이트하기 위한 문서  
> **마지막 갱신:** 2026-06-29  
> **모델:** `gemini-2.0-flash` (`lib/core/config/ai_config.dart`)  
> **키 설정:** `.env`의 `GEMINI_API_KEY` 또는 `--dart-define=GEMINI_API_KEY=...`

---

## 상태 구분

| 상태 | 조건 | 앱 인식 |
|------|------|---------|
| **A. 키 없음** | `.env` 비어 있음 / 형식 오류 | `AiConfig.isGeminiConfigured == false` |
| **B. 키 있음 + 크레딧/결제 문제** | 429, `RESOURCE_EXHAUSTED`, `prepayment credits` 등 | `isGeminiConfigured == true`, `geminiConnected == false` (ping 실패) |
| **C. 정상 연결** | ping 성공 | `geminiStoryArcEnabled == true` |

연결 확인 UI: **더보기** → Gemini 상태 (`AppState.geminiConnected`, `checkGeminiConnection()`)

크레딧 소진 시 사용자 메시지 (`AiJournalService._humanizeGeminiError`):

> Gemini 크레딧이 소진됐어요. AI Studio → Billing에서 충전해 주세요.

---

## 한눈에 보기

| # | 기능 | 트리거 | Gemini 메서드 | 폴백 (키 없음 / API 실패) | 폴백 파일 |
|---|------|--------|---------------|---------------------------|-----------|
| 1 | AI 한 줄 (사진만 일기) | 일기 저장 | `generateDailyLine` | 규칙 문장 (사진 수·무드·시간대) | `ai_narrative.dart` |
| 2 | 일기 분류 (topics, emotion) | 일기 저장 | `analyzeJournal` | 키워드 분류 | `journal_analysis_fallback.dart` |
| 3 | Story Arc 매칭 | 일기 저장 | `matchStoryArc` | 주제(category) 일치 규칙 | `story_arc_engine.dart` `_fallbackMatch` |
| 4 | 신규 Story Arc 생성 | 첫 매칭 실패 시 | (간접) 분류 결과 | `JournalAnalysisFallback` 제목·카테고리 | `journal_analysis_fallback.dart` |
| 5 | 저장 직후 인사이트 | 일기 저장 | `generateDailyInsight` | 고정 문구 | `story_arc_engine.dart` `_fallbackInsightMessage` |
| 6 | 챕터 자동 완성 (봉인) | 일기 저장 후 | `evaluateOpenChapterSeal` | **고정 규칙만** (아래 §챕터) | `story_arc_engine.dart` `_tryAutoComplete` |
| 7 | 챕터 제목 | 봉인 시 | `generateChapterTitle` | Arc `displayTitle` / `AiNarrative.suggestChapterTitle` | `ai_narrative.dart` |
| 8 | 챕터 본문 (narrative) | 봉인 시 | **미사용** (항상 규칙) | 메모 발췌 + 고정 문장 | `ai_narrative.dart` `chapterNarrative` |
| 9 | 30일 신규 Arc 발견 | 저장 후 (쿨다운 3일) | `discoverNewStoryArcs` | **없음** (스킵) | — |
| 10 | 월간 리포트 | 더보기 → 30일 리포트 | `generateMonthlyReview` | 주제 빈도 + 고정 문장 | `story_arc_engine.dart` `_fallbackMonthlyReview` |
| 11 | 무드 AI 추천 | 기록 화면 사진 추가 | `recommendMoods` | 메모·시간대 키워드 | `ai_journal_service.dart` `_fallbackMoodSuggestions` |
| 12 | 연결 ping | 앱 초기화 / 설정 | `pingGemini` | 실패 표시만 | `AppState.checkGeminiConnection` |

---

## 기능별 상세

### 1. AI 한 줄 (`generateDailyLine`)

- **언제:** 메모 없이 **사진만** 있는 일기 저장 시 (`EntryDiaryAi.shouldGenerateAiDiary`)
- **Gemini:** 과거 말투 + 사진 비전
- **폴백:** `AiNarrative.fallbackDailyLine` — 사진 장수, 무드 이모지, 기록 시각(아침/낮/저녁)
- **호출:** `AppState.saveEntry` → `AiJournalService.generateDailyLine`
- **키 없음:** 즉시 폴백  
- **API 실패:** catch 후 폴백 ✅

---

### 2. 일기 분류 (`analyzeJournal`)

- **언제:** 매 일기 저장 직후 (`StoryArcEngine.processEntrySaved`)
- **출력:** `topics[]`, `emotion`, `importanceScore`
- **폴백:** `JournalAnalysisFallback.analyze` — 메모/무드/aiLine 키워드 매칭  
  - 카테고리 예: `career_change`, `relationship`, `daily_life` …
- **키 없음:** `analyzeJournal` → `null` → 폴백 ✅  
- **API 실패:** `null` → 폴백 ✅

---

### 3. Story Arc 매칭 (`matchStoryArc`)

- **언제:** 분류 직후, 활성 Arc가 1개 이상일 때
- **폴백:** `_fallbackMatch` — `analysis.topics`와 Arc `category` 일치 시 연결, 없으면 신규 Arc 후보
- **키 없음 / Arc 없음:** `matchStoryArc` → `null` → 폴백 ✅

---

### 4. 신규 Story Arc 생성

- **Gemini 경로:** `discoverNewStoryArcs` (30일 윈도우, 별도)
- **일상 경로:** 매칭 실패 + `newCategory` → `JournalAnalysisFallback.suggestDisplayTitle`  
  - 예: `새로운 일상`, `커리어 변화 이야기` (5장 이상 시)

---

### 5. 저장 직후 인사이트 (`generateDailyInsight`)

- **언제:** 일기 저장 후 홈/기록에 잠깐 보이는 한 줄
- **폴백 예시:**
  - Arc 있음: `「{Arc 제목}」 이야기에 오늘 기록이 더해졌어요.`
  - 없음: `{주제 라벨} 주제의 하루가 남았어요.`

---

### 6. 챕터 자동 완성 — ⚠️ 가장 중요

**실제 경로:** `StoryArcEngine._tryAutoComplete` (저장마다 호출)

봉인 조건 **우선순위:**

```
1. Arc.status == shifting  AND  entries >= 4
   → 마지막 1장 빼고 봉인, pivot으로 신규 Arc 시작

2. Arc 기간 >= 21일  AND  entries >= 5
   → 전체 봉인

3. isGeminiConfigured  AND  entries >= 5
   → evaluateOpenChapterSeal (AI 판단)
   → shouldSeal == false 또는 API 실패 → 봉인 안 함 (return null)

4. 그 외 → 봉인 안 함
```

| 상태 | 조기 봉인 (5~20일, shifting 아님) | 21일+5장 봉인 | shifting 봉인 |
|------|-----------------------------------|---------------|---------------|
| A. 키 없음 | ❌ | ✅ | ✅ |
| B. 키 있음 + 크레딧 없음 | ❌ (AI 분기 진입 후 실패) | ✅ | ✅ |
| C. 정상 | ✅ (AI 판단) | ✅ | ✅ |

**최소 기록 수:** `ChapterSegmenter.minEntriesToSeal` = **3장** (봉인 대상 `toSeal` 기준)

#### 미사용 코드 (개선 후보)

`ChapterSealEvaluator` (`lib/core/utils/chapter_seal_evaluator.dart`)는 AI 실패 시 `ChapterSegmenter` 규칙 폴백을 구현해 두었으나, **현재 앱 어디에서도 호출되지 않음**.  
`_tryAutoComplete`가 `ChapterSealEvaluator` 대신 `evaluateOpenChapterSeal`만 직접 호출함.

---

### 7. 챕터 제목 (`generateChapterTitle`)

- **봉인 시:** Gemini 제목 시도 → 실패 시 `arc.displayTitle`
- **키 없음:** `generateChapterTitle` → `null` → Arc 제목 사용
- **규칙 제목 유틸:** `AiNarrative.suggestChapterTitle` (무드 라벨 → 짧은 메모 → 기간)
- **수동 봉인 (deprecated):** `AppState.sealOpenChapterManually` — 동일 폴백

---

### 8. 챕터 본문 (`chapterNarrative`)

- **Gemini 미사용** — 항상 `AiNarrative.chapterNarrative`
- 메모 4자 이상 2개 있으면 「메모」 인용 + `N일의 기록이 「제목」로 묶였어요.`
- 없으면: `N일의 순간이 「제목」라는 이름으로 모였어요.`

---

### 9. 30일 신규 Arc 발견 (`discoverNewStoryArcs`)

- **조건:** 최근 30일 5장+, 7일+ span, 3일 쿨다운
- **키 없음 / 실패:** 후보 `null` → **새 Arc 자동 발견 없음** (일기 분류로만 Arc 생성)

---

### 10. 월간 리포트 (`generateMonthlyReview`)

- **조건 (현행):** 최근 30일 기록 3장+ — **목표 UX는 캘린더 월·말일 공개** → [MONTHLY_REVIEW.md](./MONTHLY_REVIEW.md)
- **폴백:** `_fallbackMonthlyReview` — topic 빈도 상위 3개 라벨, 완성 Arc 제목, 고정 growth 문장
- **키 없음 / API 실패:** 항상 폴백 리포트 생성 ✅

---

### 11. 무드 AI 추천 (`recommendMoods`)

- **언제:** 기록 화면에서 사진 추가 후 (~600ms 디바운스)
- **폴백:** 메모 키워드(피곤/좋/답답) 또는 현재 시각대 기본 무드 3개

---

### 12. 연결 확인 (`pingGemini`)

- **앱 부팅:** 키 있으면 `geminiStatusMessage`만 표시 (자동 ping 아님)
- **수동:** `AppState.checkGeminiConnection()` → 더보기 UI

---

## Story Arc 상태 머신 (규칙, AI 무관)

`StoryArcEngine._refreshArcStats` 기준:

| 상태 | 조건 |
|------|------|
| `seeding` | 기록 < 5 또는 span < 7일 |
| `growing` | 기록 >= 5 **且** span >= 7일 |
| `focused` | 활성 Arc 중 최다 기록 + 기록 >= 3 |
| `shifting` | 최근 3장 topics가 Arc category와 불일치 |
| `completed` | 봉인 완료 |

챕터 whisper 배너 (`ChapterWhisper`): 기록 7장+ **또는** 7일+ & 3장+, 아직 whisper 미표시

---

## 관련 소스 파일

| 역할 | 경로 |
|------|------|
| API 키·모델 | `lib/core/config/ai_config.dart` |
| Gemini 호출 전부 | `lib/services/ai_journal_service.dart` |
| Story/Arc/챕터 오케스트레이션 | `lib/services/story_arc_engine.dart` |
| 규칙 분류 | `lib/core/utils/journal_analysis_fallback.dart` |
| 규칙 문장·제목 | `lib/core/utils/ai_narrative.dart` |
| 챕터 경계 (21일 gap 등) | `lib/core/utils/chapter_segmenter.dart` |
| 봉인 폴백 (미연결) | `lib/core/utils/chapter_seal_evaluator.dart` |
| 앱 상태·저장 파이프라인 | `lib/providers/app_state.dart` |
| 기록 화면 무드 추천 | `lib/screens/record/record_screen.dart` |
| 월간 리포트 UI | `lib/screens/more/monthly_review_screen.dart` |

---

## 알려진 갭 / TODO

- [ ] **B 상태 (키 O, 크레딧 X):** `_tryAutoComplete`가 AI 분기에서 실패하면 `ChapterSegmenter` 규칙 폴백으로 넘어가지 않음 → `ChapterSealEvaluator` 연동 검토
- [ ] `ChapterSealEvaluator` — 구현만 있고 미사용
- [ ] 챕터 **본문**은 Gemini 미연동 — 향후 AI narrative 옵션 여부 결정
- [ ] `discoverNewStoryArcs` 폴백 없음 — 키워드 기반 30일 클러스터링 후보

---

## 문서 업데이트 체크리스트

코드 변경 시 아래를 확인하고 이 문서를 갱신할 것:

1. `AiJournalService`에 새 Gemini 메서드 추가 여부
2. `AiConfig.geminiModel` / 키 로딩 방식 변경
3. `StoryArcEngine._tryAutoComplete` 봉인 조건 변경
4. 폴백 클래스 (`AiNarrative`, `JournalAnalysisFallback`) 동작 변경
5. UI에서 AI 상태 표시 위치 변경
6. **마지막 갱신** 날짜 수정

---

## 참고: README 요약과의 관계

루트 `README.md`의 AI 섹션은 사용자용 빠른 안내.  
이 문서는 **개발·QA용**으로 기능별 폴백·엣지 케이스를 상세히 기록한다.
