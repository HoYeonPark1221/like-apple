#!/bin/bash
# corner_radius.swift 를 컴파일해 실행한다. 사용법은 corner_radius.swift 머리말 참고.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="${TMPDIR:-/tmp}/like-apple-corner-radius"
if [ ! -x "$BIN" ] || [ "$DIR/corner_radius.swift" -nt "$BIN" ]; then
  env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
    xcrun swiftc -O -swift-version 5 "$DIR/corner_radius.swift" -o "$BIN" 2>&1 | grep -E "error" || true
fi
"$BIN" "$@"
