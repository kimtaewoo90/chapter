#!/usr/bin/env bash
# flutter run 우회: devicectl로 USB iPhone에 직접 설치·실행
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE_ID="${1:-00008030-0015295034F9802E}"
BUNDLE_ID="com.bomi.chapter"
APP_PATH="build/ios/iphoneos/Runner.app"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Chapter · USB 직접 설치 (flutter run 우회)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " iPhone (5) USB: $DEVICE_ID"
echo ""
echo " ⚠️  설치 중 iPhone 화면 잠금 해제 · 「신뢰」「설치」 누르기"
echo "     Mac/iPhone 어디에도 「취소」 누르지 마세요 (User cancelled 원인)"
echo ""

if [[ ! -d "$APP_PATH" ]]; then
  echo "→ Release 빌드 중..."
  flutter build ios --release
fi

echo "→ 기기 연결 확인..."
xcrun devicectl list devices 2>&1 | head -20 || true
echo ""

echo "→ 앱 설치 중 (1~3분, 취소하지 마세요)..."
if ! xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"; then
  echo ""
  echo "❌ devicectl 설치 실패"
  echo ""
  echo "체크리스트:"
  echo "  · iPhone USB 연결 · 이 Mac 신뢰"
  echo "  · 설정 → 개인정보 및 보안 → 개발자 모드 켜기"
  echo "  · 설정 → 일반 → VPN 및 기기 관리 → 개발자 앱 신뢰"
  echo "  · Xcode → Window → Devices and Simulators → 기기 연결됨 확인"
  echo ""
  echo "그래도 안 되면:"
  echo "  ./scripts/open_ios_xcode_release.sh  → Xcode에서 ⌘R"
  exit 1
fi

echo ""
echo "→ 앱 실행 중..."
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || \
  echo "(자동 실행 실패 — 홈 화면에서 Chapter 아이콘을 눌러 실행하세요)"

echo ""
echo "✅ 설치 완료. 홈 화면에 Chapter 아이콘이 보이면 성공입니다."
