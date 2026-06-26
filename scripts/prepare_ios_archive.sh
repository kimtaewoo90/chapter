#!/usr/bin/env bash
# Xcode Archive 전 필수 준비 — Pods·Flutter 설정 동기화 후 workspace 열기
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ flutter pub get"
flutter pub get

echo "▶ pod install"
(cd ios && pod install)

echo "▶ iOS Release 사전 빌드 (Pods 프레임워크 생성)"
flutter build ios --release --config-only
flutter build ios --release

echo ""
echo "▶ Xcode workspace 열기…"
open "$ROOT/ios/Runner.xcworkspace"

cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Xcode Archive 체크리스트
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ✅ Runner.xcworkspace 로 열렸는지 확인 (xcodeproj 아님!)
 ✅ 상단 Scheme: Runner
 ✅ Product → Archive

 여전히 Module not found 가 나오면:
   Xcode 완전 종료 → 이 스크립트 다시 실행

 TestFlight 업로드만 필요하면:
   ./scripts/deploy_ios.sh --bump
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
