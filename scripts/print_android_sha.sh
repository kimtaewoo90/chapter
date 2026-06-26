#!/usr/bin/env bash
# Firebase Console → 프로젝트 설정 → Android 앱 → SHA 인증서 지문 에 붙여넣기
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Debug keystore (flutter run 기본) ==="
KEYSTORE="${HOME}/.android/debug.keystore"
if [[ -f "$KEYSTORE" ]]; then
  keytool -list -v -keystore "$KEYSTORE" -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null | grep -E 'SHA1:|SHA256:'
else
  echo "debug.keystore 없음: Android Studio에서 한 번 빌드하거나 에뮬레이터 실행"
fi

echo ""
echo "=== Gradle signingReport (앱 모듈 전체) ==="
cd "$ROOT/android"
if [[ -x "./gradlew" ]]; then
  ./gradlew :app:signingReport 2>/dev/null | grep -E 'Variant:|SHA1:|SHA-256:' || true
else
  echo "gradlew 없음 — flutter build apk 한 번 실행 후 재시도"
fi

echo ""
echo "Firebase: 프로젝트 설정 → Android(com.bomi.chapter) → 지문 추가 → google-services.json 재다운로드"
