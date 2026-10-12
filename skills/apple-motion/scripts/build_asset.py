#!/usr/bin/env python3
"""references/recipes.md 의 ```swift 블록을 이어 붙여 assets/AppleMotion.swift 를 만든다.

레시피의 단일 출처는 recipes.md 다. 코드를 고칠 때는 recipes.md 를 고친 뒤 이 스크립트를 다시 돌린다.
그래야 문서와 복사해 쓰는 파일이 어긋나지 않는다.

    python3 scripts/build_asset.py            # 파일 생성
    python3 scripts/build_asset.py --check    # 생성 + macOS/iOS 타입체크(Swift 5·6)
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "references", "recipes.md")
OUT = os.path.join(ROOT, "assets", "AppleMotion.swift")

HEADER = """//
//  AppleMotion.swift
//
//  Apple식 애니메이션 도구 모음 (iOS 17 / iPadOS 17 / macOS 14 이상).
//  macOS 노치 앱 Live Peninsula를 개발하며 다듬은 모션·크기 규칙을 일반화한 것이다.
//  이 파일은 apple-motion 스킬의 references/recipes.md 에서 자동 생성된다 — 고칠 때는 레시피를 고치고 다시 만든다.
//
//  프로젝트에 이 파일 하나를 넣으면 아래를 바로 쓸 수 있다:
//    Motion            모션 어휘 (settle / present / morph / lift / pressDown / pressRelease / exit / swap / reduced)
//    .motion(_:value:) 동작 줄이기를 자동으로 따르는 .animation
//    PressableStyle    누르는 순간 반응하는 버튼
//    Materialize       재질이 도착하는 등장
//    .contentDrop      들어올 때와 나갈 때가 다른 전환
//    EmergeFromSource  끊어도 이어지는 등장 (genie)
//    SegmentMeter · CountdownRing · DecayingShake · TransitionsExample
//    Physics · VelocityTracker · SnapDragExample   손의 속도를 이어받는 드래그
//    PagedDeck · Haptics · GlassMorphMenu · SymbolEffectsTour · Pop · IslandMorph
//    CometStroke · RotatingGlowBorder · LivingMesh · ZoomTransitionExample
//    AppleMetrics · .appleHitTarget() · ConcentricCardExample   컨트롤·베젤 규격, 최소 터치 영역, 동심 모서리
//    .applePointerEffect · Haptics.play(meaning:) · SystemSheetExample · AdaptiveRow · GlassLayeringExample · .rejectShake   플랫폼 HIG
//
//  이름이 이미 쓰이고 있으면(예: Motion, Haptics) 프로젝트에 맞게 접두어를 붙여 바꾼다.
//

"""


def extract():
    text = open(SRC, encoding="utf-8").read()
    blocks = re.findall(r"```swift\n(.*?)```", text, flags=re.S)
    if not blocks:
        sys.exit("swift 블록을 찾지 못했다: " + SRC)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(HEADER + "\n\n".join(b.rstrip("\n") for b in blocks) + "\n")
    print(f"{len(blocks)}개 블록 → {os.path.relpath(OUT, ROOT)} ({sum(1 for _ in open(OUT, encoding='utf-8'))}줄)")


def typecheck():
    env = {  # 하네스의 전체 환경 변수가 있으면 SwiftUIMacros 플러그인 서버가 실패할 수 있어 최소 환경만 넘긴다.
        "PATH": os.environ.get("PATH", ""),
        "HOME": os.environ.get("HOME", ""),
        "DEVELOPER_DIR": os.environ.get("DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer"),
    }
    targets = [
        ("macOS 14", ["xcrun", "swiftc", "-target", "arm64-apple-macos14.0"]),
        ("macOS 26", ["xcrun", "swiftc", "-target", "arm64-apple-macos26.0"]),
        ("iOS 17", ["xcrun", "--sdk", "iphonesimulator", "swiftc", "-target", "arm64-apple-ios17.0-simulator"]),
        ("iOS 26", ["xcrun", "--sdk", "iphonesimulator", "swiftc", "-target", "arm64-apple-ios26.0-simulator"]),
    ]
    failed = False
    for label, base in targets:
        for ver in ("5", "6"):
            r = subprocess.run(base + ["-typecheck", "-swift-version", ver, OUT], capture_output=True, text=True, env=env)
            out = r.stdout + r.stderr
            errors, warnings = out.count("error:"), out.count("warning:")
            ok = r.returncode == 0 and errors == 0
            failed |= not ok
            print(f"  {label:9s} Swift {ver}: {'OK' if ok else 'FAIL'}  (errors {errors}, warnings {warnings})")
            if not ok:
                print("\n".join(l for l in out.splitlines() if "error:" in l)[:800])
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    extract()
    if "--check" in sys.argv:
        typecheck()
