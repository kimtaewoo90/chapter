import 'package:flutter/foundation.dart';

/// 디버그/Hot restart마다 스플래시만 다시 보기 (온보딩은 최초 1회만)
const bool kPreviewSplashOnEveryRestart = kDebugMode;

/// true — 재시작마다 온보딩 (TestFlight·개발 테스트용)
/// 출시 전 false 로 — SharedPreferences `onboarding_complete` 기준, 최초 1회만
const bool kPreviewOnboardingOnEveryRestart = false;

/// Apple 로그인 UI·네이티브 연동. 유료 Apple Developer + Runner.entitlements에 Sign in with Apple 필요.
/// Personal Team만 쓸 때: `--dart-define=ENABLE_APPLE_SIGN_IN=false`
const bool kEnableAppleSignIn = bool.fromEnvironment(
  'ENABLE_APPLE_SIGN_IN',
  defaultValue: true,
);

/// 디버그에서 Remote Config 최소 버전 게이트 우회 — `--dart-define=BYPASS_VERSION_GATE=true`
const bool kBypassVersionGate = kDebugMode &&
    bool.fromEnvironment(
      'BYPASS_VERSION_GATE',
      defaultValue: false,
    );

// ── 기록 화면 Phase A~C (집 QA 후 되돌리기 쉽게 플래그로 분리) ──

/// **true** — Phase B·C: 책 페이지 한 장에서 WYSIWYG 편집 (무드·사진·글)
/// **false** — Phase A: 상단 PDF 미리보기 + 하단 「편집」 분리 UI
///
/// 되돌리기: `false` 로 바꾸거나
/// `flutter run --dart-define=RECORD_BOOK_PAGE_COMPOSER=false`
const bool kRecordBookPageComposer = bool.fromEnvironment(
  'RECORD_BOOK_PAGE_COMPOSER',
  defaultValue: true,
);

/// 저장 완료 연출 v2 — 책등·진행률 (Phase C). false 면 v1 페이지 슬라이드만
const bool kRecordSaveAnimationV2 = bool.fromEnvironment(
  'RECORD_SAVE_ANIMATION_V2',
  defaultValue: true,
);

/// 온보딩 2페이지 — 실제 PDF 페이지 프레임 미리보기 (Phase C)
const bool kOnboardingUsesBookPagePreview = bool.fromEnvironment(
  'ONBOARDING_BOOK_PAGE_PREVIEW',
  defaultValue: true,
);
