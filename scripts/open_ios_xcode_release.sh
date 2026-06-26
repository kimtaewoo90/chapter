#!/usr/bin/env bash
# flutter run 대신 Xcode로 Release 빌드·설치 (iOS 26에서 가장 안정적)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/prepare_ios_archive.sh"
