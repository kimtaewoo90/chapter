# 앱 최소 버전 · 점검 모드

Chapter는 **Firebase Remote Config**로 최소 지원 버전과 점검 모드를 관리합니다.  
앱 시작 시 Remote Config를 가져온 뒤, 현재 버전이 최소 버전보다 낮으면 **스토어 업데이트 전면 화면**으로 진입을 막습니다.

## Remote Config 키

| 키 | 타입 | 기본값 (앱 내장) | 설명 |
|----|------|------------------|------|
| `min_supported_version` | String | `1.0.0` | 이 버전 **미만**이면 강제 업데이트 |
| `maintenance_mode` | Boolean | `false` | `true`면 점검 화면 (버전 무관) |
| `force_update_title` | String | 업데이트가 필요해요 | 강제 업데이트 제목 |
| `force_update_message` | String | (안내 문구) | 강제 업데이트 본문 |
| `maintenance_title` | String | 잠시 점검 중이에요 | 점검 제목 |
| `maintenance_message` | String | (안내 문구) | 점검 본문 |
| `ios_store_url` | String | (비어 있음) | iOS App Store URL (비우면 `IOS_STORE_ID` 빌드 상수 사용) |
| `android_store_url` | String | (비어 있음) | Play Store URL (비우면 `com.bomi.chapter` 기본 링크) |

## Firebase Console 설정

1. [Firebase Console](https://console.firebase.google.com) → 프로젝트 → **Remote Config**
2. **매개변수 추가** — 위 표의 키를 모두 등록 (첫 출시 시 `min_supported_version` = `1.0.0` 권장)
3. **게시** — 변경 후 반드시 Publish

### 새 버전 출시 시 운영 절차

1. `pubspec.yaml`의 `version` 올리고 스토어에 빌드 업로드
2. 스토어 심사·배포가 끝난 뒤 Remote Config의 `min_supported_version`을 새 버전으로 올림  
   (예: `1.0.1` 배포 후 `min_supported_version` → `1.0.1`)
3. 이전 버전 사용자는 앱 실행 시 업데이트 화면 표시

> 스토어 배포 **전에** `min_supported_version`을 올리면, 아직 업데이트할 수 없는 사용자가 막힐 수 있습니다.

## 빌드 상수

| 상수 | 용도 |
|------|------|
| `--dart-define=IOS_STORE_ID=123456789` | iOS 스토어 링크 (`https://apps.apple.com/app/id…`) |
| `--dart-define=BYPASS_VERSION_GATE=true` | **디버그 전용** — 게이트 우회 |

예시 (릴리스 iOS):

```bash
flutter build ipa --dart-define=IOS_STORE_ID=YOUR_APP_STORE_ID
```

## 앱 동작

```
앱 시작
  → Remote Config fetch (실패 시 내장 기본값)
  → maintenance_mode == true  → 점검 화면
  → current < min_supported_version → 강제 업데이트 화면
  → 통과 → 기존 스플래시 / 온보딩 / 홈
```

- 강제 업데이트 화면: 뒤로가기 불가, **스토어에서 업데이트** · **업데이트 후 다시 확인**
- 더보기 하단에 `CHAPTER 1.0.0+4` 형식으로 현재 빌드 표시

## 관련 코드

| 파일 | 역할 |
|------|------|
| `lib/services/app_version_service.dart` | Remote Config 조회·판정 |
| `lib/core/utils/app_version_compare.dart` | semver 비교 |
| `lib/screens/update/app_version_block_screen.dart` | 차단 UI |
| `lib/providers/app_state.dart` | `LaunchPhase.forceUpdate` / `maintenance` |

## 테스트

```bash
flutter test test/app_version_compare_test.dart
```
