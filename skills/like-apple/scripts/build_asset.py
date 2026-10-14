#!/usr/bin/env python3
"""Concatenates the ```swift blocks of references/recipes.md into assets/AppleMotion.swift.

recipes.md is the single source of the recipes. After editing it, run this script again.
The generated file exists to check that all recipes compile together; it is not copied into user projects.

    python3 scripts/build_asset.py            # generate the file
    python3 scripts/build_asset.py --check    # generate + typecheck for macOS/iOS (Swift 5 and 6)
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
//  Apple-style motion toolkit (iOS 17 / iPadOS 17 / macOS 14 and later).
//  Generated from the like-apple skill's references/recipes.md — edit the recipes, then regenerate.
//
//  A verification bundle: bring only the recipes you need into a project. Contents:
//    Motion            motion vocabulary (settle / present / morph / lift / pressDown / pressRelease / exit / swap / reduced)
//    .motion(_:value:) .animation that follows Reduce Motion automatically
//    PressableStyle    a button that reacts the instant it's pressed
//    Materialize       a material that arrives
//    .contentDrop      different entrance and exit
//    EmergeFromSource  an interruptible entrance (genie)
//    SegmentMeter · CountdownRing · DecayingShake · TransitionsExample
//    Physics · VelocityTracker · PresentedOffset · SnapDragExample   a drag that carries the hand's velocity
//    PagedDeck · Haptics · GlassMorphMenu · SymbolEffectsTour · Pop · IslandMorph
//    CometStroke · RotatingGlowBorder · LivingMesh · ZoomTransitionExample
//    AppleMetrics · .appleHitTarget() · ConcentricCardExample   control/bezel specs, minimum hit area, concentric corners
//    .applePointerEffect · Haptics.play(meaning:) · SystemSheetExample · AdaptiveRow · GlassLayeringExample · .rejectShake   platform behavior
//
//  If a name is already taken in your project (e.g. Motion, Haptics), rename it with a prefix.
//

"""


def extract():
    text = open(SRC, encoding="utf-8").read()
    blocks = re.findall(r"```swift\n(.*?)```", text, flags=re.S)
    if not blocks:
        sys.exit("no swift blocks found: " + SRC)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(HEADER + "\n\n".join(b.rstrip("\n") for b in blocks) + "\n")
    print(f"{len(blocks)} blocks → {os.path.relpath(OUT, ROOT)} ({sum(1 for _ in open(OUT, encoding='utf-8'))} lines)")


def typecheck():
    env = {  # A full harness environment can make the SwiftUIMacros plugin server fail; pass a minimal one.
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
