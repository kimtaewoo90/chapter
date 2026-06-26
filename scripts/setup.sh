#!/usr/bin/env bash
set -euo pipefail

FLUTTER="${FLUTTER:-flutter}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "→ Xcode 라이선스 확인 (필요 시: sudo xcodebuild -license)"
$FLUTTER doctor

echo "→ 플랫폼 파일 생성 (기존 lib/ 유지)"
$FLUTTER create . --org com.chapter --project-name chapter --platforms=ios,android,web

echo "→ .env (AI 키, Git 제외)"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "  .env.example → .env 복사됨. GEMINI_API_KEY 를 .env 에 넣어주세요."
else
  echo "  .env 이미 있음"
fi

echo "→ 의존성 설치"
$FLUTTER pub get

echo "→ Firebase 연동 (FlutterFire CLI 필요)"
if command -v flutterfire &>/dev/null; then
  flutterfire configure
else
  echo "  flutterfire CLI 미설치: dart pub global activate flutterfire_cli"
  echo "  수동으로 lib/firebase_options.dart 를 채워주세요."
fi

echo "완료. 실행: flutter run"
