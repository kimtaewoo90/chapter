#!/usr/bin/env bash
# CHAPTER 배포 진입점
#
#   ./scripts/deploy.sh              iOS TestFlight (빌드 + 업로드 UI)
#   ./scripts/deploy.sh ios          위와 동일
#   ./scripts/deploy.sh ios --bump   빌드 번호 +1 후 배포
#   ./scripts/deploy.sh ios --api-upload   API 키 자동 업로드
#   ./scripts/deploy.sh ios --help

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TARGET="${1:-ios}"
shift || true

case "$TARGET" in
  ios|testflight)
    exec "$ROOT/scripts/deploy_ios.sh" "$@"
    ;;
  -h|--help|help)
    cat <<'EOF'
CHAPTER 배포

  ./scripts/deploy.sh [ios] [옵션]

옵션 (deploy_ios.sh 와 동일):
  --bump          pubspec build number +1 후 빌드
  --build-only    IPA만 빌드
  --upload-only   기존 IPA만 업로드
  --api-upload    App Store Connect API 자동 업로드
  --clean         flutter clean 후 빌드
  -h, --help

예시:
  ./scripts/deploy.sh --bump
  ./scripts/deploy.sh ios --build-only
EOF
    ;;
  android)
    echo "Android Play Store 배포는 아직 스크립트가 없어요."
    echo "  cd android && ./gradlew bundleRelease"
    exit 1
    ;;
  *)
    echo "알 수 없는 타깃: $TARGET"
    echo "사용: ./scripts/deploy.sh ios [--bump]"
    exit 1
    ;;
esac
