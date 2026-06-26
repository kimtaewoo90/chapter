#!/usr/bin/env bash
# iOS 26 실기기 설치 — USB 권장, Release 모드
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# USB로 연결된 기기 우선 (이름에 wireless 없는 iPhone)
pick_usb_ios_device() {
  python3 - <<'PY'
import json, subprocess
out = subprocess.check_output(["flutter", "devices", "--machine"], text=True)
devices = json.loads(out)
ios = [d for d in devices if d.get("targetPlatform") == "ios" and not d.get("emulator")]
# flutter devices 사람용 출력에서 wireless 표시 — machine JSON엔 없어서
# 기기 2대면 USB 쪽(보통 iPhone (5) 등 괄호 이름)을 사용자가 지정하는 게 안전
for d in ios:
    print(d["id"])
    break
PY
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Chapter · iOS 26 실기기 (Release)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " ⚠️  iOS 26 실기기는 Debug(flutter run) 불가 → --release 필수"
echo " ⚠️  무선 디버깅은 느리고 실패하기 쉬움 → USB 케이블 연결 권장"
echo "     (iPhone 설정 → 개발자 → 무선 디버깅 끄기)"
echo ""

DEVICE_ID="${1:-}"
if [[ -z "$DEVICE_ID" ]]; then
  echo "연결된 기기:"
  flutter devices 2>&1 | sed -n '/Found.*connected/,/Found.*wireless/p' | head -20
  echo ""
  DEVICE_ID="$(pick_usb_ios_device || true)"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "USB로 iPhone 연결 후 다시 실행하세요:"
  echo "  ./scripts/run_ios_device_release.sh <device-id>"
  echo ""
  echo "또는 Xcode로 설치 (가장 안정적):"
  echo "  ./scripts/open_ios_xcode_release.sh"
  exit 1
fi

echo "→ 기기 ID: $DEVICE_ID"
echo "→ flutter run --release (설치 실패 시 Xcode 스크립트 사용)"
echo ""

if ! flutter run --release -d "$DEVICE_ID" --device-timeout 120; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " flutter run 설치 실패 (iOS 26 / devicectl 버그 가능)"
  echo ""
  echo " 1) iPhone에서 Chapter 앱이 이미 설치됐는지 확인 (있으면 아이콘으로 실행)"
  echo " 2) 아래 Xcode 방법 시도:"
  echo "      ./scripts/open_ios_xcode_release.sh"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
