#!/usr/bin/env bash
# iOS 배포 — TestFlight / App Store Connect 업로드
#
# 사용법:
#   ./scripts/deploy_ios.sh                 빌드 + 업로드 UI 열기 (기본)
#   ./scripts/deploy_ios.sh --bump          빌드 번호 +1 후 빌드 + 업로드 UI
#   ./scripts/deploy_ios.sh --build-only    IPA만 빌드
#   ./scripts/deploy_ios.sh --upload-only   기존 IPA만 업로드 시도
#   ./scripts/deploy_ios.sh --api-upload    API 키로 자동 업로드 (환경변수 필요)
#
# API 자동 업로드 (선택):
#   export APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
#   export APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   export APP_STORE_CONNECT_API_KEY_PATH=~/Keys/AuthKey_XXXXXXXXXX.p8
#   ./scripts/deploy_ios.sh --api-upload
#
# App Store Connect 앱:
#   App Store Name: Chapter - 내인생의 챕터
#   홈 화면 이름: 챕터
#   Bundle ID: com.bomi.chapter

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IPA="$ROOT/build/ios/ipa/chapter.ipa"
ARCHIVE="$ROOT/build/ios/archive/Runner.xcarchive"
PUBSPEC="$ROOT/pubspec.yaml"

BUMP=false
BUILD_ONLY=false
UPLOAD_ONLY=false
API_UPLOAD=false
CLEAN=false

usage() {
  sed -n '3,18p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --bump) BUMP=true; shift ;;
    --build-only) BUILD_ONLY=true; shift ;;
    --upload-only) UPLOAD_ONLY=true; shift ;;
    --api-upload) API_UPLOAD=true; shift ;;
    --clean) CLEAN=true; shift ;;
    *) echo "알 수 없는 옵션: $1"; usage 1 ;;
  esac
done

if $BUILD_ONLY && $UPLOAD_ONLY; then
  echo "❌ --build-only 와 --upload-only 는 같이 쓸 수 없어요."
  exit 1
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ 필요한 명령: $1"
    exit 1
  fi
}

read_version() {
  local line
  line="$(grep -E '^version:' "$PUBSPEC" | head -1)"
  VERSION_NAME="${line#version: }"
  VERSION_NAME="${VERSION_NAME%%+*}"
  BUILD_NUMBER="${line#*+}"
  BUILD_NUMBER="${BUILD_NUMBER%% *}"
}

bump_build_number() {
  read_version
  local next=$((BUILD_NUMBER + 1))
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${next}/" "$PUBSPEC"
  else
    sed -i "s/^version: .*/version: ${VERSION_NAME}+${next}/" "$PUBSPEC"
  fi
  echo "✓ 버전: ${VERSION_NAME}+${next} (build ${BUILD_NUMBER} → ${next})"
  BUILD_NUMBER=$next
}

preflight() {
  require_cmd flutter
  require_cmd python3

  if [[ ! -f "$ROOT/ios/Runner/GoogleService-Info.plist" ]]; then
    echo "❌ GoogleService-Info.plist 없음 — flutterfire configure 먼저 실행하세요."
    exit 1
  fi

  if [[ ! -f "$ROOT/.env" ]]; then
    echo "⚠ .env 없음 — Gemini 등 일부 기능은 동작하지 않을 수 있어요."
  fi

  echo "▶ Google iOS URL scheme 동기화…"
  python3 "$ROOT/scripts/sync_google_ios_config.py"
}

build_ipa() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " iOS Release IPA 빌드"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  read_version
  echo "  App Store: Chapter - 내인생의 챕터"
  echo "  홈 화면: 챕터"
  echo "  Bundle ID: com.bomi.chapter"
  echo "  버전: ${VERSION_NAME} (${BUILD_NUMBER})"
  echo ""

  flutter pub get
  echo "▶ pod install…"
  (cd "$ROOT/ios" && pod install)

  if $CLEAN; then
    echo "▶ flutter clean…"
    flutter clean
    flutter pub get
    (cd "$ROOT/ios" && pod install)
  fi

  echo "▶ flutter build ipa --release…"
  flutter build ipa --release

  if [[ ! -f "$IPA" ]]; then
    echo "❌ IPA 없음: $IPA"
    exit 1
  fi

  echo ""
  echo "✓ IPA: $IPA ($(du -h "$IPA" | cut -f1))"
  echo "✓ Archive: $ARCHIVE"
}

upload_via_api() {
  require_cmd xcrun

  local key_id="${APP_STORE_CONNECT_API_KEY_ID:-}"
  local issuer_id="${APP_STORE_CONNECT_API_ISSUER_ID:-}"
  local key_path="${APP_STORE_CONNECT_API_KEY_PATH:-}"

  if [[ -z "$key_id" || -z "$issuer_id" ]]; then
    echo "❌ API 업로드에 환경변수가 필요해요:"
    echo "   APP_STORE_CONNECT_API_KEY_ID"
    echo "   APP_STORE_CONNECT_API_ISSUER_ID"
    echo "   APP_STORE_CONNECT_API_KEY_PATH (AuthKey_XXX.p8)"
    return 1
  fi

  if [[ -n "$key_path" && -f "$key_path" ]]; then
    local key_dir key_file
    key_dir="$(dirname "$key_path")"
    key_file="$(basename "$key_path")"
    export API_PRIVATE_KEYS_DIR="$key_dir"
    # altool expects AuthKey_<KEY_ID>.p8 in API_PRIVATE_KEYS_DIR
    if [[ "$key_file" != "AuthKey_${key_id}.p8" ]]; then
      mkdir -p "$key_dir"
      if [[ ! -f "$key_dir/AuthKey_${key_id}.p8" ]]; then
        cp "$key_path" "$key_dir/AuthKey_${key_id}.p8"
      fi
    fi
  fi

  echo ""
  echo "▶ App Store Connect API 업로드…"
  xcrun altool --upload-app \
    --type ios \
    -f "$IPA" \
    --apiKey "$key_id" \
    --apiIssuer "$issuer_id"
  echo "✓ 업로드 요청 완료 — App Store Connect → TestFlight에서 Processing 확인"
}

open_upload_ui() {
  echo ""
  echo "▶ 업로드 UI 열기…"

  if $API_UPLOAD; then
    if upload_via_api; then
      return 0
    fi
    echo "⚠ API 업로드 실패 — 수동 업로드로 전환합니다."
  fi

  if open -a Transporter "$IPA" 2>/dev/null; then
    echo "✓ Transporter 열림 — Deliver 클릭"
    return 0
  fi

  if open "$ARCHIVE" 2>/dev/null; then
    echo "✓ Xcode Organizer 열림 — Distribute App → App Store Connect → Upload"
    return 0
  fi

  echo "❌ Transporter / Xcode를 열 수 없어요."
  echo "   IPA: $IPA"
  echo "   Transporter: https://apps.apple.com/app/transporter/id1450874784"
  return 1
}

print_next_steps() {
  cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 다음 단계
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 1. App Store Connect → TestFlight → 빌드 Processing (10~30분)
 2. Internal Testing → 테스터 추가 → 설치
 3. 스토어 출시 시: App Store → 버전 정보·스크린샷 → 심사 제출

 앱 등록 (최초 1회):
   App Store Name: Chapter - 내인생의 챕터
   홈 화면 이름: 챕터
   Bundle ID: com.bomi.chapter
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ── main ──

if $BUMP; then
  bump_build_number
fi

if ! $UPLOAD_ONLY; then
  preflight
  build_ipa
fi

if $BUILD_ONLY; then
  print_next_steps
  exit 0
fi

if [[ ! -f "$IPA" ]]; then
  echo "❌ IPA 없음. --upload-only 없이 먼저 빌드하세요."
  exit 1
fi

open_upload_ui
print_next_steps
