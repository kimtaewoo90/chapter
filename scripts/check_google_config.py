#!/usr/bin/env python3
"""iOS·Android Google 로그인 설정 상태 점검."""

from __future__ import annotations

import json
import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GS_IOS = ROOT / "ios/Runner/GoogleService-Info.plist"
GS_ANDROID = ROOT / "android/app/google-services.json"


def check_ios() -> bool:
    print("── iOS ──")
    if not GS_IOS.is_file():
        print(f"❌ 없음: {GS_IOS}")
        return False
    with GS_IOS.open("rb") as f:
        data = plistlib.load(f)
    ok = True
    for key in ("CLIENT_ID", "REVERSED_CLIENT_ID"):
        if not data.get(key):
            print(f"❌ GoogleService-Info.plist에 {key} 없음")
            ok = False
        else:
            print(f"✓ {key}")
    if ok:
        print("  → python3 scripts/sync_google_ios_config.py 실행 권장")
    return ok


def check_android() -> bool:
    print("── Android ──")
    if not GS_ANDROID.is_file():
        print(f"❌ 없음: {GS_ANDROID}")
        return False
    with GS_ANDROID.open(encoding="utf-8") as f:
        data = json.load(f)
    clients = data.get("client") or []
    if not clients:
        print("❌ client 항목 없음")
        return False
    oauth = clients[0].get("oauth_client") or []
    if not oauth:
        print("❌ oauth_client 가 비어 있음 (Google 연결 느림/실패의 흔한 원인)")
        print("   1. Firebase Console → Authentication → Google 사용 설정")
        print("   2. 프로젝트 설정 → Android 앱 → SHA-1 지문 추가 (아래 스크립트로 확인)")
        print("   3. google-services.json 다시 다운로드 → android/app/ 에 교체")
        return False
    types = {c.get("client_type") for c in oauth}
    print(f"✓ oauth_client {len(oauth)}개 (types={types})")
    ok = True
    if 1 not in types:
        print("⚠ client_type 1 (Android) 없음 — SHA-1 미등록일 수 있음 → ./scripts/print_android_sha.sh")
        ok = False
    if 3 not in types:
        print("⚠ client_type 3 (Web) 없음")
        ok = False
    return ok


def main() -> int:
    ios_ok = check_ios()
    print()
    android_ok = check_android()
    print()
    if ios_ok and android_ok:
        print("✅ Google 설정 파일이 준비된 것으로 보입니다.")
        return 0
    print("❌ 위 항목을 Firebase Console에서 맞춘 뒤 파일을 다시 받고 재실행하세요.")
    print("   Android SHA-1: ./scripts/print_android_sha.sh")
    return 1


if __name__ == "__main__":
    sys.exit(main())
