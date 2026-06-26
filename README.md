# CHAPTER

감성 일기를 기록하고, 시간이 지나 하나의 책으로 완성하는 라이프 아카이브 앱 (Flutter + Firebase MVP).

## MVP 기능

| 기능 | 설명 |
|------|------|
| 온보딩 | 감성 인트로 + 취향 선택 + 샘플 챕터 미리보기 |
| 오늘 (Home) | 오늘 카드, AI 한줄, 책 진행률, 작년 오늘 회상 |
| 기록 (Record) | 사진·무드·음악·한줄(120자) → Firestore 저장 |
| 챕터 | 최근 기록 기반 AI 챕터 자동 생성 (규칙 기반 narrative) |
| 책 | 페이지 넘김 UI, PDF보내기 |
| 실물 제작 | 표지/스타일/주문 UI (결제 연동 제외) |
| 통계/캘린더 | 연간 통계, 감정 분포, 사진 썸네일 캘린더 |

## UI/UX

- MY DIARY 기획 이미지 참고: 베이지 톤, 종이 질감, 책 spine, 페이지 넘김
- 생산성 UI 금지 (streak, 체크리스트 등 없음)

## 사전 요구사항

1. Flutter SDK 3.2+
2. **Xcode 라이선스 동의** (macOS/iOS): `sudo xcodebuild -license`
3. Firebase 프로젝트
4. (권장) [FlutterFire CLI](https://firebase.flutter.dev/docs/overview)

## 빠른 시작

```bash
cd ~/Projects/chapter
chmod +x scripts/setup.sh
./scripts/setup.sh
```

또는 수동:

```bash
flutter create . --org com.chapter --project-name chapter
flutter pub get
flutterfire configure   # lib/firebase_options.dart 생성
flutter run
```

### iOS 26 실기기에서 앱이 바로 죽을 때 (Dart VM 크래시)

**원인:** iOS 26은 실기기 **Debug 모드의 JIT(Just-In-Time) 컴파일**을 막습니다.  
`flutter run` 기본값은 Debug라서, 빌드는 성공해도 실행 직후 `Dart_Initialize` / `Assert::Fail` 로 크래시할 수 있습니다. **앱·알림 버그가 아닙니다.**

| 환경 | 권장 실행 |
|------|-----------|
| **iOS 26 실기기** | `flutter run --release` 또는 `--profile` |
| **시뮬레이터** | `flutter run` (Debug · Hot reload 가능) |
| **일상 개발** | 시뮬레이터 Debug → 실기기는 Release로 최종 확인 |

```bash
# 1) iPhone에서 Chapter 앱 삭제 (예전 Debug 빌드 제거)
# 2) USB 케이블 연결 (무선 디버깅 끄기 — 90분+ 걸리다 실패할 수 있음)
# 3) Release로 설치 (철자: --release, releaswe 아님)
cd ~/Projects/chapter
flutter clean
flutter pub get
flutter run --release -d 00008030-0015295034F9802E   # USB iPhone ID는 flutter devices 로 확인

# flutter run 설치가 PathNotFoundException 으로 실패하면 → Xcode 사용 (권장)
chmod +x scripts/open_ios_xcode_release.sh
./scripts/open_ios_xcode_release.sh
```

**`flutter run`이 `User cancelled` / `devicectl exit code 3` / 90분 후 `PathNotFoundException`**

1. **iPhone 잠금 해제** + 설치 중 **취소 누르지 않기** (`User cancelled` = 중간에 취소됨)
2. **USB 케이블** 연결, 무선 디버깅 끄기
3. **직접 설치 스크립트** (flutter run 우회):

```bash
chmod +x scripts/install_ios_usb.sh
./scripts/install_ios_usb.sh
```

4. 안 되면 **Xcode** (가장 안정적):

```bash
./scripts/open_ios_xcode_release.sh
# Xcode → Release → USB iPhone → ⌘R
```

### Flutter 3.44+ Swift Package Manager 오류 (`already exists in file system`)

Flutter 업그레이드 후 `Adding Swift Package Manager integration` 에서 Firebase/Rive zip 캐시 충돌이 나면, Chapter는 **CocoaPods만** 쓰면 됩니다:

```bash
flutter config --no-enable-swift-package-manager
rm -rf ~/Library/Caches/org.swift.swiftpm/artifacts
rm -rf ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm
flutter clean && flutter pub get && cd ios && pod install && cd ..
```

- **Hot reload**가 필요하면 **iOS 시뮬레이터** 사용  
- **Profile** (성능·일부 프로파일링): `flutter run --profile`  
- (선택) Flutter **3.35+** 로 올리면 실기기 Debug가 다시 될 수 있음: `flutter upgrade`

## Firebase 설정

### 1. Console에서 프로젝트 생성

- Authentication → **익명(Anonymous) 로그인** 활성화 (필수 — 꺼져 있으면 `internal-error` / Firestore `permission-denied`)
- Firestore Database 생성 (테스트 모드 후 rules 배포)
- Storage 활성화

### 2. 앱 등록

- Android: `com.bomi.chapter`
- iOS: `com.bomi.chapter`
- `google-services.json` → `android/app/`
- `GoogleService-Info.plist` → `ios/Runner/`

### 3. FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

`lib/firebase_options.dart`의 `YOUR_*` 플레이스홀더가 실제 값으로 교체됩니다.

### 4. Rules 배포

```bash
firebase deploy --only firestore:rules,storage
```

`firestore.rules`, `storage.rules` 참고.

### 익명 로그인 / Firestore 오류가 날 때

1. [Firebase Console](https://console.firebase.google.com) → **Authentication** → **Sign-in method** → **익명** 사용 설정
2. iOS: `ios/Runner/GoogleService-Info.plist`를 Console에서 **다시 다운로드**해 교체 (파일이 짧으면 설정이 불완전할 수 있음)
3. 앱 **완전 종료 후 재실행** (Hot restart만으로는 Auth 설정이 반영되지 않을 수 있음)
4. (선택) 로컬 에뮬레이터: `flutter run --dart-define=USE_FIREBASE_EMULATORS=true` 후 `firebase emulators:start`

### 소셜 연동 (Apple / Google)

앱은 **익명 로그인 → 나중에 연결** 방식입니다. `linkWithCredential`으로 **uid가 바뀌지 않아** 기존 `users/{uid}/entries`·실물 책 주문과 동일 계정입니다.

**공통 (iOS·Android)**

1. Firebase Console → **Authentication** → **Sign-in method** → **Google** → **사용 설정** → 저장  
2. 상태 점검: `python3 scripts/check_google_config.py`  
3. 앱 **더보기 → 백업 · 다른 기기**에서 **Google로 연결**  
4. 설정 반영 후 **`flutter clean && flutter run`** (Hot restart만으로는 OAuth 반영 안 됨)

---

#### Google — Android

| 단계 | 할 일 |
|------|--------|
| 1 | [Firebase Console](https://console.firebase.google.com) → **chapter-cc187** → **프로젝트 설정** → **Android 앱** (`com.bomi.chapter`) |
| 2 | **SHA 인증서 지문** 추가 — 아래 명령으로 **SHA-1**(필수), **SHA-256**(권장) 복사 후 Console에 붙여넣기 |

```bash
chmod +x scripts/print_android_sha.sh
./scripts/print_android_sha.sh
```

| 3 | **google-services.json** 다시 다운로드 → `android/app/google-services.json` 교체 |
| 4 | 파일 안 `"oauth_client": [ ... ]` 가 **비어 있지 않은지** 확인 (비어 있으면 SHA 미등록 또는 Google 미활성) |
| 5 | `flutter clean && flutter run` |

**디버그 vs 릴리스**

- `flutter run` / USB 설치: 보통 **debug.keystore** SHA-1  
- Play 스토어·릴리스 APK: **업로드 키 / 릴리스 keystore** SHA-1도 Console에 **추가**해야 함 (키마다 따로 등록)

**느리거나 멈출 때**

- `oauth_client: []` → SHA-1 등록 후 json **재다운로드**  
- 실기기에 **Google Play 서비스**·Google 계정 로그인 여부 확인  
- (선택) Web 클라이언트 ID가 필요하면:  
  `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com`  
  (Console → Authentication → Google → **웹 SDK 구성**의 클라이언트 ID)

---

#### Google — iOS

| 단계 | 할 일 |
|------|--------|
| 1 | Authentication → **Google** 사용 설정 (위와 동일) |
| 2 | **GoogleService-Info.plist** 다시 다운로드 → `ios/Runner/` 교체 (`CLIENT_ID`, `REVERSED_CLIENT_ID` 필수) |
| 3 | `python3 scripts/sync_google_ios_config.py` → `Info.plist` URL scheme·`GIDClientId` 반영 |
| 4 | `flutter clean && flutter run` |

**Personal Team**은 Sign in with Apple 불가 → iOS도 **Google 연결**만 쓰면 됨.

**Google 로그인 시 `project-997338084636` (으)로 이동 표시**

- 앱 이름(`Chapter`)이 아니라 **GCP OAuth 동의 화면 앱 이름**이 뜹니다.
- [Google Cloud Console](https://console.cloud.google.com/) → 프로젝트 **chapter-cc187** 선택  
  → **API 및 서비스** → **OAuth 동의 화면** → **앱 이름**을 `CHAPTER`(또는 `Chapter`)로 변경 → 저장  
- (선택) **사용자 유형**이 *외부*이면 **게시 상태**를 *프로덕션*으로 올리거나, 테스트 중이면 **테스트 사용자**에 본인 Gmail 추가  
- Firebase Console → **프로젝트 설정** → **일반** → **공개용 이름**도 `CHAPTER`로 맞추면 일부 화면에 반영됩니다.  
- 변경 후 Google 로그인을 **다시 시도** (캐시 때문에 바로 안 바뀔 수 있음)

---

#### Apple (iOS만, 유료 Apple Developer Program)

1. Firebase Console → **Authentication** → **Sign-in method** → **Apple** → **사용 설정** → 저장  
2. `ios/Runner/Runner.entitlements`에 Sign in with Apple (`com.apple.developer.applesignin`) — 저장소에 반영됨  
3. Xcode → Runner 타깃 → **Signing & Capabilities** → **Sign in with Apple** 추가 (팀: 유료 Developer)  
4. `flutter clean && flutter run` (실기기 권장)

Personal Team만 쓸 때: `flutter run --dart-define=ENABLE_APPLE_SIGN_IN=false`

---

**다른 기기:** 더보기 → 백업 · 다른 기기 → **Google로 불러오기** (연결과 달리 Google에 묶인 uid로 로그인)

이미 다른 CHAPTER 계정에 붙은 Apple/Google ID면 `credential-already-in-use` — 그 계정으로 로그인해야 합니다.

## 데이터 구조

```
users/{uid}/entries/{entryId}
  - date, photoUrl, moodEmoji, musicTitle, note, weather, aiLine, ...

users/{uid}/chapters/{chapterId}
  - title, narrative, startDate, endDate, coverPhotoUrl, ...
```

## AI (MVP)

저장 시 **Google Gemini** (`gemini-2.0-flash`)가 사진(비전) + 과거 일기 말투 + 오늘 메모/무드로 **한두 문장**을 생성합니다.

1. [Google AI Studio](https://aistudio.google.com/apikey)에서 API 키 발급
2. 프로젝트 루트에 `.env` 생성 (한 번만):

```bash
cp .env.example .env
# .env 파일을 열어 GEMINI_API_KEY=발급받은_키 입력
```

`.env`는 `.gitignore`에 포함되어 Git에 올라가지 않습니다.

(선택) CI/일회성 실행만 `--dart-define=GEMINI_API_KEY=...` 도 가능합니다.

키가 없거나 API 오류 시 `lib/core/utils/ai_narrative.dart` 규칙 폴백을 사용합니다.

기록 화면에서 사진을 올리면 Gemini가 **무드 3개**를 추천합니다 (`.env` 필요).

### 날씨 (OpenWeatherMap)

1. [OpenWeatherMap](https://openweathermap.org/api)에서 API 키 발급 (Current Weather API)
2. `.env`에 추가:

```
OPENWEATHER_API_KEY=발급받은_키
```

3. 기록/오늘 탭 진입 시 위치 허용 → 실측 날씨 표시·저장 (키 없거나 거부 시 UI 숨김)

## 프로젝트 구조

```
lib/
  app/           # MaterialApp, 라우팅
  core/          # theme, moods, ai_narrative
  models/
  services/      # Auth, Firestore, Storage
  providers/     # AppState
  screens/       # splash, onboarding, home, record, ...
  widgets/
```

## 알려진 제한 (MVP)

- Spotify/Apple Music API 미연동 (수동 입력)
- 날씨: OpenWeatherMap + 위치(앱 사용 중 1회) — `.env`에 `OPENWEATHER_API_KEY`, 45분 캐시
- AI: `.env`의 `GEMINI_API_KEY` 없으면 규칙 폴백
- 실물 책 주문/결제 미구현
- Xcode 라이선스 미동의 시 `flutter` CLI 사용 불가 → `setup.sh` 전에 라이선스 동의 필요

## 라이선스

Private / 사용자 프로젝트
