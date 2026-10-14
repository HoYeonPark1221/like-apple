#!/bin/bash
# Compiles and runs corner_radius.swift. See its header for usage.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="${TMPDIR:-/tmp}/like-apple-corner-radius"
if [ ! -x "$BIN" ] || [ "$DIR/corner_radius.swift" -nt "$BIN" ]; then
  env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
    xcrun swiftc -O -swift-version 5 "$DIR/corner_radius.swift" -o "$BIN" 2>&1 | grep -E "error" || true
fi
"$BIN" "$@"
