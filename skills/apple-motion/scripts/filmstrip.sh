#!/bin/bash
# filmstrip.swift 를 컴파일해 실행한다. 사용법은 filmstrip.swift 머리말 참고.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="${TMPDIR:-/tmp}/apple-motion-filmstrip"
if [ ! -x "$BIN" ] || [ "$DIR/filmstrip.swift" -nt "$BIN" ]; then
  env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
    xcrun swiftc -O -swift-version 5 "$DIR/filmstrip.swift" -o "$BIN"
fi
"$BIN" "$@"
