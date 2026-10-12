#!/bin/bash
# 스프링 값이 실제로 어떤 곡선을 만드는지 SDK에서 직접 계산한다 (추측 대신 측정).
#
#   scripts/spring_probe.sh 0.42 0.85        # response(=duration) 0.42초, 감쇠비 0.85
#   scripts/spring_probe.sh 0.42 0.85 0.5    # 시작 속도(남은 거리 대비)를 줄 수도 있다
#
# 출력: 오버슈트 %, 최고점 시각, 목표의 ±1% 안에 머무르기 시작하는 시각, Apple 파라미터(bounce) 표기.
# 감쇠비 = 1 − bounce, response = duration 이다 (SDK에서 확인).

set -euo pipefail
R="${1:?usage: spring_probe.sh <response> <dampingRatio> [relativeVelocity]}"
Z="${2:?usage: spring_probe.sh <response> <dampingRatio> [relativeVelocity]}"
V="${3:-0}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/probe.swift" <<EOF
import SwiftUI

let s = Spring(response: $R, dampingRatio: $Z)
var peak = 0.0, peakT = 0.0, lastOutside = 0.0, t = 0.0
while t <= 4.0 {
    let v: Double = s.value(target: 1.0, initialVelocity: $V, time: t)
    if v > peak { peak = v; peakT = t }
    if abs(v - 1) > 0.01 { lastOutside = t }
    t += 0.002
}
print(String(format: "response %.3f  dampingRatio %.3f  ->  bounce %.3f  (Apple: .spring(duration: %.3f, bounce: %.3f))", s.response, s.dampingRatio, s.bounce, s.duration, s.bounce))
print(String(format: "overshoot %.1f%%  at %.2fs   |   within 1%% of target after %.2fs", (peak - 1) * 100, peakT, lastOutside))
EOF

env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}" \
  xcrun swiftc -swift-version 5 -target arm64-apple-macos14.0 "$TMP/probe.swift" -o "$TMP/probe" 2>&1 | grep -E "error" || true
"$TMP/probe"
