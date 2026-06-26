#!/usr/bin/env python3
"""GoogleService-Info.plist → Info.plist (URL scheme + GIDClientId). macOS/iOS Google 로그인 필수."""

from __future__ import annotations

import plistlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GS_PATH = ROOT / "ios/Runner/GoogleService-Info.plist"
INFO_PATH = ROOT / "ios/Runner/Info.plist"


def main() -> int:
    if not GS_PATH.is_file():
        print(f"❌ 없음: {GS_PATH}")
        return 1

    with GS_PATH.open("rb") as f:
        gs = plistlib.load(f)

    reversed_id = gs.get("REVERSED_CLIENT_ID")
    client_id = gs.get("CLIENT_ID")
    if not reversed_id:
        print("❌ GoogleService-Info.plist에 REVERSED_CLIENT_ID가 없습니다.")
        print("   1. Firebase Console → Authentication → Sign-in method → Google 사용 설정")
        print("   2. 프로젝트 설정 → iOS 앱(com.bomi.chapter) → GoogleService-Info.plist 다시 다운로드")
        print(f"   3. {GS_PATH} 교체 후 이 스크립트 재실행")
        return 1

    with INFO_PATH.open("rb") as f:
        info = plistlib.load(f)

    url_types: list = info.setdefault("CFBundleURLTypes", [])
    if not any(
        reversed_id in entry.get("CFBundleURLSchemes", [])
        for entry in url_types
        if isinstance(entry, dict)
    ):
        url_types.append(
            {
                "CFBundleTypeRole": "Editor",
                "CFBundleURLSchemes": [reversed_id],
            }
        )
        print(f"✓ Info.plist URL scheme 추가: {reversed_id}")
    else:
        print("✓ URL scheme 이미 있음")

    if client_id:
        info["GIDClientId"] = client_id
        print(f"✓ GIDClientId 설정")
    else:
        print("⚠ CLIENT_ID 없음 — plist를 Firebase에서 다시 받으세요.")

    with INFO_PATH.open("wb") as f:
        plistlib.dump(info, f)

    print("완료. flutter clean && flutter run 으로 재빌드하세요.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
