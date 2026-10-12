#!/usr/bin/env python3
"""track_video 가 뽑은 CSV 한 열에 스프링을 맞춰 response·감쇠비(=Apple duration·bounce)를 구한다.

    python3 scripts/fit_spring.py data.csv --col mean --from 2.9 --to 3.6
    python3 scripts/fit_spring.py --selftest       # 정답을 아는 합성 데이터로 도구 자체를 검증

--from/--to  분석 구간(초). 한 번의 전환(나타남 또는 사라짐)만 포함하게 자른다.
--col        mean(투명도×면적) | count(면적) | bx by bw bh(바운딩 박스: 이동·크기)
방향(0→1 / 1→0)은 구간의 처음과 끝 값으로 자동 판별해 0→1로 정규화한다.

주의: 이 도구는 "곡선이 스프링 모양인가"를 가정하고 맞춘다. 맞춘 값(rmse)이 크면 스프링이 아니라
ease일 수 있다 — 그 경우 10%→90% 시간과 곡선 모양을 그대로 쓴다.
"""
import argparse
import csv
import math
import random
import sys


def step(t, r, z):
    """스프링의 단위 계단 응답. r = response(초), z = 감쇠비. SwiftUI Spring(response:dampingRatio:)과 같은 식."""
    if t <= 0:
        return 0.0
    w = 2 * math.pi / r
    if z < 1 - 1e-9:
        wd = w * math.sqrt(1 - z * z)
        return 1 - math.exp(-z * w * t) * (math.cos(wd * t) + z / math.sqrt(1 - z * z) * math.sin(wd * t))
    if z <= 1 + 1e-9:
        return 1 - math.exp(-w * t) * (1 + w * t)
    s = math.sqrt(z * z - 1)
    return 1 - ((z + s) * math.exp(-(z - s) * w * t) - (z - s) * math.exp(-(z + s) * w * t)) / (2 * s)


def sse(ts, ys, t_on, r, z):
    return sum((y - step(t - t_on, r, z)) ** 2 for t, y in zip(ts, ys))


def fit(ts, ys):
    first = ts[0]
    best = (1e18, 0, 0, 0)
    # 거친 격자
    for t_on in [first - 0.05 + 0.01 * i for i in range(0, 70)]:
        for r in [0.06 + 0.04 * i for i in range(0, 32)]:
            for z in [0.3 + 0.1 * i for i in range(0, 12)]:
                e = sse(ts, ys, t_on, r, z)
                if e < best[0]:
                    best = (e, t_on, r, z)
    # 촘촘히
    _, t0, r0, z0 = best
    for t_on in [t0 - 0.01 + 0.002 * i for i in range(0, 11)]:
        for r in [max(0.03, r0 - 0.04) + 0.005 * i for i in range(0, 17)]:
            for z in [max(0.2, z0 - 0.1) + 0.0125 * i for i in range(0, 17)]:
                e = sse(ts, ys, t_on, r, z)
                if e < best[0]:
                    best = (e, t_on, r, z)
    e, t_on, r, z = best
    return t_on, r, z, math.sqrt(e / len(ts))


# 범위의 폭을 정하는 보정 계수. 이론값(χ² 3자유도 95%)은 7.8이지만, 정규화에 쓴 시작·끝 값의 추정 오차 등이 빠져
# 실제로는 정답이 범위 밖으로 나갔다. 합성 데이터(노이즈 σ=0.02, 60fps, 36케이스, 시드 777)로 보정해 k=30에서
# 정답 포함 비율 97%(35/36)를 얻었다. 노이즈 모양이 가우시안이 아닌 실제 영상에서는 이보다 안 맞을 수 있다.
RANGE_K = 30.0
# 깨끗한 데이터(rmse≈0.003)에서는 잔차로 추정한 노이즈가 0에 가까워 범위가 지나치게 좁아진다. 실제 영상에는 가장자리
# 안티앨리어싱·임계값·프레임 양자화 같은 체계 오차가 남기 때문에 정규화된 값 기준 σ의 하한을 둔다.
SIGMA2_FLOOR = 2.5e-4
# 보정: 정답을 아는 시뮬레이터 녹화 9창(알려진 스프링 5 + Dynamic Island 폭 4)에서 하한 σ≥0.01이면 정답이 모두 범위에 들어왔다
# (하한이 없으면 6/9). 표본이 적으므로 한 단계 여유를 둔 σ≥0.016을 쓴다. 평균 범위 폭은 response 0.17s, dampingRatio 0.36.


def uncertainty(ts, ys, t_on0, r0, z0):
    """최적값 주변에서 '데이터가 구분하지 못하는' 파라미터 범위(대략 95%).
    노이즈 크기를 잔차에서 추정하고, 오차가 그만큼(χ² 3자유도 95%) 늘어나는 안쪽을 범위로 본다.
    response와 감쇠비는 서로 보완하므로 한 값만 내놓으면 정밀해 보이는 착각을 준다."""
    n = len(ts)
    e0 = sse(ts, ys, t_on0, r0, z0)
    sigma2 = max(e0 / max(n - 3, 1), SIGMA2_FLOOR)   # 노이즈 하한 — 아래 SIGMA2_FLOOR 설명 참고
    limit = e0 + RANGE_K * sigma2
    r_ok, z_ok = [r0], [z0]                          # 최적점 자신은 항상 범위 안
    for r in [max(0.03, r0 - 0.2) + 0.01 * i for i in range(41)]:
        for z in [0.3 + 0.025 * i for i in range(45)]:
            m = min(sse(ts, ys, t_on0 - 0.04 + 0.008 * i, r, z) for i in range(11))
            if m <= limit:
                r_ok.append(r)
                z_ok.append(z)
    return (min(r_ok), max(r_ok)), (min(z_ok), max(z_ok))


PRESETS = [("smooth", 1.00), (".snappy", 0.85), (".bouncy", 0.70)]


def presets_in(z_lo, z_hi):
    return [name for name, z in PRESETS if z_lo - 0.02 <= z <= z_hi + 0.02]


def normalize(ts, vs):
    k = max(3, len(vs) // 10)
    v0 = sorted(vs[:k])[k // 2]
    v1 = sorted(vs[-k:])[k // 2]
    if abs(v1 - v0) < 1e-9:
        sys.exit("구간의 처음과 끝 값이 같다 — 전환이 이 구간에 없다")
    return [(v - v0) / (v1 - v0) for v in vs], ("0→1" if v1 > v0 else "1→0")


def crossing(ts, ys, level):
    for (t0, y0), (t1, y1) in zip(zip(ts, ys), zip(ts[1:], ys[1:])):
        if y0 < level <= y1:
            return t0 + (level - y0) / (y1 - y0) * (t1 - t0)
    return None


def report(ts, vs, label="", quiet=False):
    ys, direction = normalize(ts, vs)
    # 변화가 시작되는 지점부터만 쓴다 (앞의 평평한 구간이 길면 격자 탐색이 흐려진다)
    start = max(0, next((i for i, y in enumerate(ys) if y > 0.02), 0) - 2)
    ts2, ys2 = ts[start:], ys[start:]
    t_on, r, z, rmse = fit(ts2, ys2)
    (r_lo, r_hi), (z_lo, z_hi) = uncertainty(ts2, ys2, t_on, r, z)
    t10, t90 = crossing(ts2, ys2, 0.10), crossing(ts2, ys2, 0.90)
    peak = max(ys2)
    if not quiet:
        print(f"{label}방향 {direction}, 샘플 {len(ts2)}개, rmse {rmse:.3f}")
        print(f"  최적값      : response {r:.3f}s  dampingRatio {z:.3f}  (Apple: .spring(duration: {r:.3f}, bounce: {max(0.0, 1 - z):.3f}))")
        print(f"  데이터가 허용하는 범위(보정된 ≈95%): response {r_lo:.2f}~{r_hi:.2f}s,  dampingRatio {z_lo:.2f}~{min(z_hi, 1.4):.2f}")
        names = presets_in(z_lo, z_hi)
        print(f"  범위에 걸리는 Apple 프리셋: {', '.join(names) if names else '없음(프리셋 사이)'}"
              + ("  ← 이 데이터만으로는 구분할 수 없다" if len(names) > 1 else ""))
        if t10 is not None and t90 is not None:
            print(f"  직접 잰 값  : 10%→90% {t90 - t10:.3f}s,  최고점 {100 * (peak - 1):+.1f}%  (1을 넘으면 오버슈트)")
        print("  해석 주의   : rmse>0.08이면 스프링이 아니라 ease일 수 있다. 프레임이 적거나 노이즈가 크면 범위가 넓어진다 — "
              "더 정확히 알려면 슬로모션(120fps↑)으로 다시 찍는다.")
    return r, z, rmse, (r_lo, r_hi), (z_lo, z_hi)


def selftest():
    ok = True
    # (1) 노이즈 없으면 정확히 복원돼야 한다 — 알고리즘 자체의 검증
    print("(1) 노이즈 0: 정답 → 복원")
    for r, z in [(0.42, 0.85), (0.30, 1.0), (0.35, 0.72), (0.5, 0.5)]:
        ts = [1.0 + i / 60 for i in range(84)]
        ys = [step(t - 1.07, r, z) for t in ts]
        start = max(0, next((i for i, y in enumerate(ys) if y > 0.02), 0) - 2)
        _, rr, zz, _ = fit(ts[start:], ys[start:])
        good = abs(rr - r) <= 0.01 and abs(zz - z) <= 0.03
        ok &= good
        print(f"    r={r:.2f} ζ={z:.2f} → r={rr:.3f} ζ={zz:.3f}  {'OK' if good else 'FAIL'}")

    # (2) 노이즈가 있으면 값이 흔들린다 — 그래서 '범위'가 정직한지(정답을 포함하는지) 확인
    print("(2) 노이즈 있음(σ=0.02, 60fps): 보고한 범위가 정답을 포함하는 비율")
    rnd = random.Random(2024)
    n, hit_r, hit_z = 16, 0, 0
    for _ in range(n):
        r = rnd.uniform(0.25, 0.55)
        z = min(1.0, rnd.choice([1.0, 0.85, 0.7, 0.55]) + rnd.uniform(-0.03, 0.03))
        on = rnd.uniform(0.95, 1.1)
        ts = [1.0 + i / 60 for i in range(84)]
        vs = [3 + 11 * (step(t - on, r, z) + rnd.gauss(0, 0.02)) for t in ts]
        _, _, _, (rl, rh), (zl, zh) = report(ts, vs, quiet=True)
        hit_r += rl - 0.005 <= r <= rh + 0.005
        hit_z += zl - 0.01 <= z <= zh + 0.01
    print(f"    response 범위 포함 {hit_r}/{n}, dampingRatio 범위 포함 {hit_z}/{n}  (목표: ≥ 85%)")
    ok &= hit_r >= 0.85 * n and hit_z >= 0.85 * n
    print("자체 검증:", "통과" if ok else "실패")
    sys.exit(0 if ok else 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv", nargs="?")
    ap.add_argument("--col", default="mean")
    ap.add_argument("--from", dest="t0", type=float)
    ap.add_argument("--to", dest="t1", type=float)
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        selftest()
    if not a.csv:
        ap.error("csv 경로가 필요하다")
    rows = list(csv.DictReader(open(a.csv)))
    ts = [float(r["t"]) for r in rows]
    vs = [float(r[a.col]) for r in rows]
    if a.t0 is not None or a.t1 is not None:
        lo, hi = a.t0 if a.t0 is not None else -1e9, a.t1 if a.t1 is not None else 1e9
        pairs = [(t, v) for t, v in zip(ts, vs) if lo <= t <= hi]
        ts, vs = [p[0] for p in pairs], [p[1] for p in pairs]
    if len(ts) < 8:
        sys.exit("샘플이 너무 적다 — 구간을 넓혀라")
    report(ts, vs)


if __name__ == "__main__":
    main()
