#!/usr/bin/env bash
# 하위 호환 — deploy.sh 사용 권장
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/scripts/deploy_ios.sh" "$@"
