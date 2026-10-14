#!/usr/bin/env python3
"""Fits a spring to one column of the CSV from track_video to get response and damping ratio (= Apple duration and bounce).

    python3 scripts/fit_spring.py data.csv --col mean --from 2.9 --to 3.6
    python3 scripts/fit_spring.py --selftest       # verify the tool itself on synthetic data with known answers

--from/--to  analysis window (s). Cut it to contain a single transition (appear or disappear).
--col        mean (opacity × area) | count (area) | bx by bw bh (bounding box: movement, size)
Direction (0→1 / 1→0) is detected from the first and last values and normalized to 0→1.

Careful: this tool assumes the curve is spring-shaped. If the fit error (rmse) is large it may be
an ease, not a spring — then use the 10%→90% time and the curve shape directly.
"""
import argparse
import csv
import math
import random
import sys


def step(t, r, z):
    """Unit step response of a spring. r = response (s), z = damping ratio. Same formula as SwiftUI Spring(response:dampingRatio:)."""
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
    # coarse grid
    for t_on in [first - 0.05 + 0.01 * i for i in range(0, 70)]:
        for r in [0.06 + 0.04 * i for i in range(0, 32)]:
            for z in [0.3 + 0.1 * i for i in range(0, 12)]:
                e = sse(ts, ys, t_on, r, z)
                if e < best[0]:
                    best = (e, t_on, r, z)
    # fine grid
    _, t0, r0, z0 = best
    for t_on in [t0 - 0.01 + 0.002 * i for i in range(0, 11)]:
        for r in [max(0.03, r0 - 0.04) + 0.005 * i for i in range(0, 17)]:
            for z in [max(0.2, z0 - 0.1) + 0.0125 * i for i in range(0, 17)]:
                e = sse(ts, ys, t_on, r, z)
                if e < best[0]:
                    best = (e, t_on, r, z)
    e, t_on, r, z = best
    return t_on, r, z, math.sqrt(e / len(ts))


# Calibration factor for the range width. The theoretical value (χ², 3 dof, 95%) is 7.8, but it ignores errors such as the estimated start/end values used for
# normalization, so the truth fell outside the range in practice. Calibrated on synthetic data (noise σ=0.02, 60fps, 36 cases, seed 777): k=30
# contains the truth 97% of the time (35/36). Real video with non-Gaussian noise may do worse.
RANGE_K = 30.0
# On clean data (rmse≈0.003) the noise estimated from residuals is near zero and the range gets too narrow. Real video keeps systematic errors
# (edge anti-aliasing, thresholding, frame quantization), so σ has a floor on the normalized scale.
SIGMA2_FLOOR = 2.5e-4
# Calibration: on 9 simulator-recording windows with known answers (5 known springs + 4 Dynamic Island widths), a floor of σ≥0.01 put every answer in range
# (6/9 without a floor). The sample is small, so σ≥0.016 adds a margin. Average range width: response 0.17s, dampingRatio 0.36.


def uncertainty(ts, ys, t_on0, r0, z0):
    """The parameter range around the best fit that the data can't distinguish (roughly 95%).
    Estimates the noise from residuals and takes the region where the error grows by no more than that (χ², 3 dof, 95%).
    Response and damping trade off, so reporting a single value would create false precision."""
    n = len(ts)
    e0 = sse(ts, ys, t_on0, r0, z0)
    sigma2 = max(e0 / max(n - 3, 1), SIGMA2_FLOOR)   # noise floor — see SIGMA2_FLOOR
    limit = e0 + RANGE_K * sigma2
    r_ok, z_ok = [r0], [z0]                          # the best fit itself is always in range
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
        sys.exit("first and last values are equal — there is no transition in this window")
    return [(v - v0) / (v1 - v0) for v in vs], ("0→1" if v1 > v0 else "1→0")


def crossing(ts, ys, level):
    for (t0, y0), (t1, y1) in zip(zip(ts, ys), zip(ts[1:], ys[1:])):
        if y0 < level <= y1:
            return t0 + (level - y0) / (y1 - y0) * (t1 - t0)
    return None


def report(ts, vs, label="", quiet=False):
    ys, direction = normalize(ts, vs)
    # use only from where the change starts (a long flat lead-in blurs the grid search)
    start = max(0, next((i for i, y in enumerate(ys) if y > 0.02), 0) - 2)
    ts2, ys2 = ts[start:], ys[start:]
    t_on, r, z, rmse = fit(ts2, ys2)
    (r_lo, r_hi), (z_lo, z_hi) = uncertainty(ts2, ys2, t_on, r, z)
    t10, t90 = crossing(ts2, ys2, 0.10), crossing(ts2, ys2, 0.90)
    peak = max(ys2)
    if not quiet:
        print(f"{label}direction {direction}, {len(ts2)} samples, rmse {rmse:.3f}")
        print(f"  best fit    : response {r:.3f}s  dampingRatio {z:.3f}  (Apple: .spring(duration: {r:.3f}, bounce: {max(0.0, 1 - z):.3f}))")
        print(f"  range the data allows (calibrated ≈95%): response {r_lo:.2f}~{r_hi:.2f}s,  dampingRatio {z_lo:.2f}~{min(z_hi, 1.4):.2f}")
        names = presets_in(z_lo, z_hi)
        print(f"  Apple presets in range: {', '.join(names) if names else 'none (between presets)'}"
              + ("  ← this data alone can't tell them apart" if len(names) > 1 else ""))
        if t10 is not None and t90 is not None:
            print(f"  measured    : 10%→90% {t90 - t10:.3f}s,  peak {100 * (peak - 1):+.1f}%  (above 0 = overshoot)")
        print("  careful     : rmse>0.08 may mean an ease, not a spring. Few frames or high noise widen the range — "
              "for more precision, re-record in slow motion (120fps+).")
    return r, z, rmse, (r_lo, r_hi), (z_lo, z_hi)


def selftest():
    ok = True
    # (1) with no noise it must recover exactly — verifies the algorithm itself
    print("(1) zero noise: truth → recovered")
    for r, z in [(0.42, 0.85), (0.30, 1.0), (0.35, 0.72), (0.5, 0.5)]:
        ts = [1.0 + i / 60 for i in range(84)]
        ys = [step(t - 1.07, r, z) for t in ts]
        start = max(0, next((i for i, y in enumerate(ys) if y > 0.02), 0) - 2)
        _, rr, zz, _ = fit(ts[start:], ys[start:])
        good = abs(rr - r) <= 0.01 and abs(zz - z) <= 0.03
        ok &= good
        print(f"    r={r:.2f} ζ={z:.2f} → r={rr:.3f} ζ={zz:.3f}  {'OK' if good else 'FAIL'}")

    # (2) with noise the values wobble — so check that the range is honest (contains the truth)
    print("(2) with noise (σ=0.02, 60fps): how often the reported range contains the truth")
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
    print(f"    response in range {hit_r}/{n}, dampingRatio in range {hit_z}/{n}  (target: ≥ 85%)")
    ok &= hit_r >= 0.85 * n and hit_z >= 0.85 * n
    print("self-test:", "PASS" if ok else "FAIL")
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
        ap.error("a csv path is required")
    rows = list(csv.DictReader(open(a.csv)))
    ts = [float(r["t"]) for r in rows]
    vs = [float(r[a.col]) for r in rows]
    if a.t0 is not None or a.t1 is not None:
        lo, hi = a.t0 if a.t0 is not None else -1e9, a.t1 if a.t1 is not None else 1e9
        pairs = [(t, v) for t, v in zip(ts, vs) if lo <= t <= hi]
        ts, vs = [p[0] for p in pairs], [p[1] for p in pairs]
    if len(ts) < 8:
        sys.exit("too few samples — widen the window")
    report(ts, vs)


if __name__ == "__main__":
    main()
