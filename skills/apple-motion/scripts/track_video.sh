#!/bin/bash
# track_video.swift 를 컴파일해 실행한다. 사용법은 track_video.swift 머리말 참고.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="${TMPDIR:-/tmp}/apple-motion-track-video"
if [ ! -x "$BIN" ] || [ "$DIR/track_video.swift" -nt "$BIN" ]; then
  env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
    xcrun swiftc -O -swift-version 5 "$DIR/track_video.swift" -o "$BIN" 2>&1 | grep -E "error" || true
fi
"$BIN" "$@"
