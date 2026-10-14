#!/bin/bash
# Compiles and runs filmstrip.swift. See its header for usage.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="${TMPDIR:-/tmp}/like-apple-filmstrip"
if [ ! -x "$BIN" ] || [ "$DIR/filmstrip.swift" -nt "$BIN" ]; then
  env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
    xcrun swiftc -O -swift-version 5 "$DIR/filmstrip.swift" -o "$BIN"
fi
"$BIN" "$@"
