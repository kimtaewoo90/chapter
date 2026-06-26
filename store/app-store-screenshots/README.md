# App Store 스크린샷

CHAPTER(챕터) App Store Connect 업로드용 스크린샷입니다.

## 생성된 파일

**iPhone 6.7"** (1290 × 2796 px) — App Store Connect 필수 규격

| 파일 | 내용 |
|------|------|
| `iphone-6.7/01_feed_book.png` | 나의 책 — 페이지 넘기기 피드 |
| `iphone-6.7/02_record.png` | 하루 한 페이지 — 사진·무드·줄노트 기록 |
| `iphone-6.7/03_story_arc.png` | Story Arc · 챕터 완성 |
| `iphone-6.7/04_ai_insight.png` | AI Daily Insight · 월간 리포트 |
| `iphone-6.7/05_my_book.png` | 한 해, 한 권 — 연간 진행률 |
| `iphone-6.7/06_backup_fonts.png` | 클라우드 백업 · 8종 글꼴 |

## App Store Connect에 올리는 방법

1. [App Store Connect](https://appstoreconnect.apple.com) → **나의 앱** → `Chapter - 내인생의 챕터`
2. **App Store** 탭 → 버전(예: 1.0) 선택 또는 **새 버전 준비**
3. **iPhone** 미리보기 / 스크린샷 섹션
4. **6.7" Display** (또는 6.9") 슬롯에 위 PNG 6장 **순서대로** 드래그

### 규격 참고

| 디스플레이 | 세로 (px) |
|-----------|-----------|
| 6.9" | 1320 × 2868 |
| **6.7"** | **1290 × 2796** ← 현재 생성 |
| 6.5" | 1284 × 2778 |
| 6.3" | 1179 × 2556 |
| 6.1" | 1170 × 2532 |

- 최소 **3장**, 최대 **10장**
- PNG 또는 JPEG, RGB, 알파 채널 없음
- 6.7"만 올리면 Apple이 다른 iPhone 크기를 자동 스케일
- 실제 앱 UI 기반 마케팅 합성 (앱 테마·기능 반영)

## 다시 생성하기

디자인·카피 수정 후:

```bash
pip3 install -r store/app-store-screenshots/requirements.txt
python3 store/app-store-screenshots/generate.py
```

`store/app-store-screenshots/generate.py`에서 헤드라인·화면 목업을 수정할 수 있습니다.

## 실제 앱 캡처로 교체하고 싶다면

시뮬레이터 **iPhone 15 Pro Max** (6.7")에서 앱 실행 후:

```bash
# 시뮬레이터 스크린샷 (⌘S) → ~/Desktop
# 또는
xcrun simctl io booted screenshot screenshot.png
```

실기기/시뮬레이터 **풀스크린 캡처**도 Connect에 사용 가능합니다.  
마케팅 문구가 필요하면 현재 생성본처럼 상단 헤드라인 합성본을 쓰는 편이 일반적입니다.

## 프로모션 텍스트 (참고)

App Store 메타데이터 입력 시 참고:

**부제 (Subtitle, 30자 이내)**  
`감성 일기를 한 권의 책으로`

**홍보 텍스트 (Promotional Text)**  
`사진과 무드만 남겨도 AI가 이어 주는 Story Arc. 365일이 모이면 조용히 한 권이 완성됩니다.`

**키워드**  
`일기,다이어리,감성일기,책,챕터,AI일기,Story Arc,일기장,기록,회고`
