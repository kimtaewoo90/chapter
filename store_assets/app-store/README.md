# App Store 스크린샷

## 규격

| 기기 | 픽셀 (세로) | 폴더 |
|------|-------------|------|
| iPhone 6.7" (필수) | **1290 × 2796** | `ios/6.7-inch/` |
| iPhone 6.5" (권장) | **1284 × 2778** | `ios/6.5-inch/` |

- PNG, RGB, 투명 배경 없음
- 장당 3~10장 (현재 6장)
- 스크린샷 안의 마케팅 문구는 한국어 App Store용

## 생성 방법

```bash
./scripts/generate_store_screenshots.sh
```

## App Store Connect 업로드

1. [App Store Connect](https://appstoreconnect.apple.com) → **Chapter - 내인생의 챕터**
2. **App Store** 탭 → 버전 (예: 1.0.0) 선택
3. **미리보기 및 스크린샷** → **iPhone** → **6.7" Display**
4. `ios/6.7-inch/` 폴더의 PNG 6장을 순서대로 드래그
5. 가능하면 **6.5" Display**에도 `ios/6.5-inch/` 업로드

### 파일 순서

| 파일 | 내용 |
|------|------|
| `01_hero.png` | 브랜드 — 삶을 한 권의 책으로 |
| `02_record.png` | 오늘 기록 (사진·무드) |
| `03_journal.png` | 나의 책 — 페이지 넘김 |
| `04_chapter.png` | 챕터 완성 |
| `05_book.png` | 올해의 책 · PDF · 실물 |
| `06_calendar.png` | 캘린더 |

## 수정

카피·레이아웃 변경: `test/store_screenshots/scenes.dart`  
프레임·상단 헤드라인: `test/store_screenshots/shell.dart`
