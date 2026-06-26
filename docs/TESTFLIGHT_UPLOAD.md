# TestFlight / App Store 업로드 가이드

CHAPTER(iOS) 앱을 TestFlight에 올리고, 이후 App Store에 출시하는 방법을 정리한 문서입니다.

## 앱 정보

| 항목 | 값 |
|------|-----|
| App Store 이름 | `Chapter - 내인생의 챕터` |
| 홈 화면 이름 (아이콘 아래) | `챕터` |
| Bundle ID | `com.bomi.chapter` |
| Firebase 프로젝트 | `chapter-cc187` |
| Xcode Team ID | `46XSWSL47B` |

> **App Store 이름**은 App Store 전체에서 유일해야 합니다. `Chapter`, `챕터 — 나의 일기책` 등은 이미 사용 중일 수 있어 위 이름으로 등록합니다.  
> 홈 화면 이름은 `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`에서 별도로 설정합니다.

---

## 사전 준비 (최초 1회)

### 1. Apple Developer / Xcode

- [Apple Developer Program](https://developer.apple.com) 등록 완료
- Mac에 **Xcode**, **Flutter**, **CocoaPods** 설치
- Xcode → Settings → Accounts에 Apple ID 로그인
- 프로젝트 Signing Team: `46XSWSL47B`

### 2. App Store Connect 앱 등록

1. [App Store Connect](https://appstoreconnect.apple.com) → **나의 앱** → **+**
2. **새로운 앱** 선택
3. 입력값:
   - **이름**: `Chapter - 내인생의 챕터`
   - **기본 언어**: 한국어 (또는 원하는 언어)
   - **Bundle ID**: `com.bomi.chapter`
   - **SKU**: 임의 값 (예: `chapter-ios`)
4. 이름 중복 오류가 나면 브랜드를 붙여 시도 (예: `Bomi Chapter - 내인생의 챕터`). Bundle ID는 그대로 사용 가능합니다.

### 3. Firebase / Google 설정

```bash
# Firebase 설정이 없다면
flutterfire configure
```

필수 파일:

- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

### 4. Transporter (권장)

Mac App Store에서 [Transporter](https://apps.apple.com/app/transporter/id1450874784) 설치. IPA 업로드에 사용합니다.

---

## 권장 방법: 스크립트로 빌드 + 업로드

**Xcode에서 Archive할 필요 없습니다.** 아래 한 줄이면 IPA 빌드까지 끝납니다.

```bash
./scripts/deploy.sh --bump
```

### 이 명령이 하는 일

1. `pubspec.yaml`의 **빌드 번호**를 +1 (예: `1.0.0+3` → `1.0.0+4`)
2. `flutter pub get` → `pod install`
3. Google iOS URL scheme 동기화
4. `flutter build ipa --release` 실행
5. **Transporter** 또는 **Xcode Organizer** 자동 실행

### 생성되는 파일

| 경로 | 설명 |
|------|------|
| `build/ios/ipa/chapter.ipa` | 업로드용 IPA |
| `build/ios/archive/Runner.xcarchive` | Archive (Organizer 업로드용) |

### Transporter에서 업로드

1. 스크립트 실행 후 열린 Transporter에 IPA가 로드됨
2. **Deliver** 클릭
3. Apple ID 로그인 후 업로드 완료 대기

### Xcode Organizer에서 업로드 (Transporter 대신)

1. 스크립트가 Archive를 열어 주거나, Finder에서 `build/ios/archive/Runner.xcarchive` 더블클릭
2. **Distribute App** → **App Store Connect** → **Upload**
3. 안내에 따라 진행

---

## 스크립트 옵션

```bash
./scripts/deploy.sh              # 빌드 + 업로드 UI (빌드 번호 유지)
./scripts/deploy.sh --bump       # 빌드 번호 +1 후 빌드 + 업로드 UI (권장)
./scripts/deploy.sh --build-only # IPA만 빌드, 업로드 UI 안 열기
./scripts/deploy.sh --upload-only # 이미 만든 IPA만 업로드 UI 열기
./scripts/deploy.sh --clean      # flutter clean 후 빌드
./scripts/deploy.sh --help       # 도움말
```

동일한 스크립트를 직접 호출해도 됩니다:

```bash
./scripts/deploy_ios.sh --bump
```

---

## API 키로 자동 업로드 (선택)

Transporter 없이 터미널에서 업로드할 때:

1. App Store Connect → Users and Access → **Keys** → API 키 생성
2. `.p8` 파일 저장

```bash
export APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
export APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export APP_STORE_CONNECT_API_KEY_PATH=~/Keys/AuthKey_XXXXXXXXXX.p8

./scripts/deploy.sh --bump --api-upload
```

---

## Xcode에서 Archive하는 방법 (선택)

CLI 배포 대신 Xcode로 Archive하려면 **아래 스크립트만** 사용하세요.  
`--bump`와 **같이 쓰지 마세요** (이중 빌드).

```bash
./scripts/prepare_ios_archive.sh
```

### 체크리스트

- [ ] Xcode 창 제목이 **`Runner.xcworkspace`** 인지 확인 (`Runner.xcodeproj` 아님)
- [ ] Scheme: **Runner**
- [ ] Product → **Archive**
- [ ] Organizer → **Distribute App** → Upload

### USB 기기 Release 실행 (Archive 아님)

```bash
./scripts/open_ios_xcode_release.sh
```

---

## 업로드 후 (TestFlight)

1. [App Store Connect](https://appstoreconnect.apple.com) → 해당 앱 → **TestFlight**
2. 빌드 상태가 **Processing** → **Ready to Submit** 될 때까지 대기 (보통 10~30분)
3. **Internal Testing** 그룹에 테스터 추가
4. iPhone에 **TestFlight** 앱 설치 후 초대 수락

### 버전 / 빌드 번호

`pubspec.yaml` 형식:

```yaml
version: 1.0.0+3
#        │     └─ 빌드 번호 (TestFlight마다 증가, --bump가 자동 +1)
#        └─ 마케팅 버전 (스토어에 보이는 1.0.0)
```

TestFlight에 **같은 빌드 번호**를 다시 올릴 수 없습니다. 재업로드 시 `--bump`를 사용하세요.

---

## App Store 정식 출시 (TestFlight 이후)

1. App Store Connect → 앱 → **App Store** 탭
2. **새 버전 준비** (스크린샷, 설명, 키워드, 개인정보 처리방침 URL 등)
3. **스크린샷**: `store/app-store-screenshots/iphone-6.7/` PNG 6장 업로드 (자세한 방법 → `store/app-store-screenshots/README.md`)
4. TestFlight에서 검증한 빌드 선택
5. **심사에 제출**

---

## 자주 나는 오류

### `Module 'cloud_firestore' not found` / Pod 관련 오류

**원인**: `Runner.xcodeproj`로 열었거나, `pod install` 없이 Archive함.

**해결**:

```bash
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace   # workspace로 열기
```

또는 권장 방법으로 `./scripts/deploy.sh --bump` 사용 (Xcode Archive 불필요).

### `The App Name you entered is already being used`

**원인**: App Store 이름이 전 세계적으로 이미 사용 중.

**해결**: App Store Connect에서 **다른 이름**으로 앱 레코드 생성. Bundle ID(`com.bomi.chapter`)와 홈 화면 이름(`챕터`)은 그대로 둬도 됩니다.

### `GoogleService-Info.plist 없음`

```bash
flutterfire configure
```

### 업로드 후 TestFlight에 빌드가 안 보임

- Processing 완료까지 10~30분 대기
- Bundle ID가 Connect 앱과 일치하는지 확인 (`com.bomi.chapter`)
- 빌드 번호가 이전과 중복되지 않았는지 확인 (`--bump`)

---

## 관련 스크립트

| 스크립트 | 용도 |
|----------|------|
| `scripts/deploy.sh` | 배포 진입점 (기본: iOS TestFlight) |
| `scripts/deploy_ios.sh` | IPA 빌드 + 업로드 UI |
| `scripts/prepare_ios_archive.sh` | Xcode Archive 전 준비 |
| `scripts/open_ios_xcode_release.sh` | Xcode Release 실행용 |
| `scripts/upload_testflight.sh` | `deploy_ios.sh`로 위임 (하위 호환) |
| `scripts/sync_google_ios_config.py` | Google Sign-In iOS URL scheme 동기화 |

---

## 빠른 참조

```bash
# TestFlight 업로드 (가장 많이 쓰는 명령)
./scripts/deploy.sh --bump
# → Transporter에서 Deliver

# IPA만 만들기
./scripts/deploy.sh --build-only --bump

# Xcode Archive (필요할 때만)
./scripts/prepare_ios_archive.sh
```
