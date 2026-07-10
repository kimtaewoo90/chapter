# CHAPTER 개발 일지

매일 **생각난 아이디어 → 개발 → 체크**를 쌓는 로그.  
집 QA는 [`HOME_VERIFY_CHECKLIST.md`](./HOME_VERIFY_CHECKLIST.md), 제품·기술 맥락은 README·코드와 함께 본다.

---

## 오늘 세션

| 항목 | 값 |
|------|-----|
| 날짜 | |
| 브랜치 / 커밋 | |
| 오늘 목표 (한 줄) | |
| 집 QA Layer | (해당 시 `HOME_VERIFY_CHECKLIST` Layer N) |

```bash
cd chapter && flutter pub get && flutter run
```

---

## 진행 중 로드맵 — 기록 UI = 책 한 페이지

> **목표:** 일기 작성 화면이 PDF 책 미리보기(`BookPdfPreview`)와 **같은 배치·UI**를 쓰고, 저장 시 **책에 한 장(하루)이 추가**되는 연출.

### Phase A — PoC (읽기 + 저장 연출 스케치)

**목표:** `RecordScreen`에서 오늘(또는 선택한 날) 일기를 **책 페이지 레이아웃으로 읽기 전용** 표시. 저장 애니는 기존 오버레이 확장 수준.

| # | 작업 | 상태 |
|---|------|------|
| A-1 | `BookPreviewEntryMapper.fromDraft` + `BookPdfPreviewPlanner.planSingleEntry` | [x] |
| A-2 | `BookDiaryPagePreview` + `book_diary_page_renderer` 분리 | [x] |
| A-3 | `RecordScreen` 상단 책 페이지 미리보기 + 하단 편집 유지 | [x] |
| A-4 | 사진 0·1·2·3장, 글 짧음/김 — `book_pdf_page_planner_test` 추가 | [x] |
| A-5 | `RecordSaveOverlay` — 「한 장 더 쌓였어요」+ 페이지 슬라이드 인 애니 | [x] |
| A-6 | 집 QA Layer 4 추가 | [x] |

**완료 기준**

- [x] 기록 화면에서 **PDF와 같은 비율·배치**로 오늘 일기가 보인다 (읽기 전용 OK)
- [ ] 저장 후 기존처럼 피드·캘린더에 반영된다 *(집 QA)*
- [ ] 회귀 없음: 사진 추가·삭제·일기 삭제·클라우드 저장 *(집 QA)*

**관련 코드**

- `lib/widgets/book_diary_page_preview.dart` *(신규)*
- `lib/widgets/book_diary_page_renderer.dart` *(신규)*
- `lib/core/book_layout/book_layout_engine.dart`
- `lib/core/book_layout/book_preview_entry_mapper.dart`
- `lib/screens/record/record_screen.dart`
- `lib/widgets/record_save_overlay.dart`

---

### Phase B — 편집 (WYSIWYG 작성)

**목표:** 책 페이지 레이아웃 **위에서** 사진·무드·글을 직접 편집.

| # | 작업 | 상태 |
|---|------|------|
| B-1 | `BookDiaryPageComposer` + `kRecordBookPageComposer` 플래그 | [x] |
| B-2 | 헤더 무드 탭 → 시트 | [x] |
| B-3 | 사진 탭/칩 → 갤러리·삭제·순서 (`showRecordPhotoGallerySheet`) | [x] |
| B-4 | `BookPdfEditableNotebookBox` — 책 본문 직접 입력 | [x] |
| B-5 | 페이지 스크롤 + 비율 고정 (`SingleChildScrollView`) | [x] |
| B-6 | 과거 날짜 저장 카피 「페이지를 고쳤어요」 | [x] |
| B-7 | AI 무드 — Composer 무드 시트에서 유지 | [x] |

**되돌리기:** `lib/core/constants/dev_flags.dart` → `kRecordBookPageComposer = false`  
또는 `flutter run --dart-define=RECORD_BOOK_PAGE_COMPOSER=false` → `RecordScreenPhaseABody` (Phase A)

---

### Phase C — Polish (한 장 추가 · 제품 연결)

| # | 작업 | 상태 |
|---|------|------|
| C-1 | `RecordSaveOverlay` v2 — 책등 스택 + 페이지 슬라이드 (`kRecordSaveAnimationV2`) | [x] |
| C-2 | 스낵바·오버레이 — 진행률 N% | [x] |
| C-3 | 피드 전환 연동 | [ ] *(저장 후 기존 `onSavedSuccessfully` 유지 — 집 QA)* |
| C-4 | 온보딩 `OnboardingRecordPreview` PDF 비율 (`kOnboardingUsesBookPagePreview`) | [x] |
| C-5 | 미리보기·Composer 레이아웃 디바운스 200~280ms | [x] |
| C-6 | 스토어 캡처 | [ ] *(집에서)* |

**되돌리기:** `kRecordSaveAnimationV2 = false`, `kOnboardingUsesBookPagePreview = false`

---

## 되돌리기 치트시트 (집 QA용)

| 되돌릴 것 | 파일 / 명령 |
|-----------|-------------|
| WYSIWYG → Phase A 분리 UI | `dev_flags.dart` `kRecordBookPageComposer = false` |
| 저장 연출 v2 → v1 | `kRecordSaveAnimationV2 = false` |
| 온보딩 PDF 비율 | `kOnboardingUsesBookPagePreview = false` |
| 한 번에 전부 끄기 | `flutter run --dart-define=RECORD_BOOK_PAGE_COMPOSER=false --dart-define=RECORD_SAVE_ANIMATION_V2=false` |

---

## 일일 로그 (맨 위가 최신)

> 매일 **맨 위에** `### YYYY-MM-DD` 블록 추가.

---

### 2026-07-10 — Phase A~C 책 페이지 WYSIWYG + 플래그

**한 일**

- [x] Phase A (이전) + **B** `BookDiaryPageComposer`, `BookPdfEditableNotebookBox`
- [x] **C** 저장 v2 연출, 진행률 스낵바, 온보딩 PDF 비율
- [x] `dev_flags.dart` — `kRecordBookPageComposer` 등 3개 플래그

**QA**

- [ ] Layer 5 (`HOME_VERIFY_CHECKLIST`)

---

### YYYY-MM-DD — 한 줄 요약

**오늘 목표**

- [ ]

**아이디어 메모**

- 

**한 일**

- [ ]

**막힌 것 / 내일**

- 

**QA** (집에서 확인 시 `HOME_VERIFY_CHECKLIST` Layer 번호)

- [ ]

---

## 아이디어 백로그 (미착수)

| 날짜 | 아이디어 | Phase | 메모 |
|------|----------|-------|------|
| 2026-07-10 | 기록 UI = PDF 책 페이지 동일 배치 | A→C | 본 로드맵 |
| 2026-07-10 | 저장 시 책에 한 장 추가 애니 | A/C | `RecordSaveOverlay` 확장 |
| | | | |

---

## 완료 스택 (위 → 아래, 위가 최근)

> 기능이 끝나면 Phase 체크를 옮기고, 한 줄 요약만 남긴다.

### `2026-07-07` — 챕터 제거 · 온보딩 3단계 · 사진·일기 삭제

- 챕터/Story Arc UI·엔진 제거, 월간 리포트 중심
- 온보딩: 소개 → 사진·일기 → 실물 책
- 사진 수정 버그, 일기 전체 삭제

---

## 일일 블록 복사용 템플릿

```markdown
### YYYY-MM-DD — 한 줄 요약

**오늘 목표**

- [ ]

**아이디어 메모**

- 

**한 일**

- [ ]

**막힌 것 / 내일**

- 

**QA**

- [ ]
```

---

## Phase 체크 한눈에

| Phase | 한 줄 | 상태 |
|-------|--------|------|
| A | 책 페이지 읽기 PoC + 저장 연출 1차 | [x] |
| B | WYSIWYG Composer (`kRecordBookPageComposer`) | [x] 코드 · 집 QA |
| C | 저장 v2 + 온보딩 PDF 비율 | [x] 코드 · 집 QA |

---

## 관련 문서

| 문서 | 용도 |
|------|------|
| [`HOME_VERIFY_CHECKLIST.md`](./HOME_VERIFY_CHECKLIST.md) | 집에서 회귀 QA |
| [`MONTHLY_REVIEW.md`](./MONTHLY_REVIEW.md) | 월간 리포트 스펙 |
| [`APP_VERSION.md`](./APP_VERSION.md) | 강제 업데이트·Remote Config |
