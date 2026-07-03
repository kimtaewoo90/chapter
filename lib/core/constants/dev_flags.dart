import 'package:flutter/foundation.dart';

/// 디버그/Hot restart마다 스플래시만 다시 보기 (온보딩은 최초 1회만)
const bool kPreviewSplashOnEveryRestart = kDebugMode;

/// false — SharedPreferences `onboarding_complete` 기준, 앱 최초 설치 시에만 온보딩
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
