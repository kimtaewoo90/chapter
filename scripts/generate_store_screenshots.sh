#!/usr/bin/env bash
# App Store 스크린샷 생성 (6.7" + 6.5")
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUT_67="$ROOT/store_assets/app-store/ios/6.7-inch"
OUT_65="$ROOT/store_assets/app-store/ios/6.5-inch"

mkdir -p "$OUT_67" "$OUT_65"

echo "▶ Flutter golden 스크린샷 생성 (1290×2796)…"
flutter test test/store_screenshots_test.dart --update-goldens

echo "▶ 6.5\" 크기로 리사이즈 (1284×2778)…"
for f in "$OUT_67"/*.png; do
  base="$(basename "$f")"
  sips -z 2778 1284 "$f" --out "$OUT_65/$base" >/dev/null
  echo "  ✓ $base"
done

echo ""
echo "✓ 완료"
echo "  6.7\" (필수): $OUT_67"
echo "  6.5\" (권장): $OUT_65"
echo ""
echo "App Store Connect → 앱 → App Store → 미디어 관리에서 업로드하세요."
