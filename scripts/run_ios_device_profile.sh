#!/usr/bin/env bash
# iOS 26 실기기: Profile 모드 (성능 측정·일부 디버깅, Hot reload 제한적)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE="${1:-}"
if [[ -z "$DEVICE" ]]; then
  echo "📱 Profile 모드 — 연결된 iOS 기기:"
  flutter devices
  echo ""
  echo "사용법: ./scripts/run_ios_device_profile.sh <device-id>"
  exit 0
fi

flutter run --profile -d "$DEVICE"
