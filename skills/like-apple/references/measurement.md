# Measurement — Apple motion by numbers, not by eye

## Why

An Apple behavior built from memory tends to be a lookalike of whatever you last built. A "system HUD" made by guessing was judged "not Apple-like" in practice,
and the recording showed why: sixteen dots that read as a dashed line, a pale gray pill that vanished on white, and a blur dissolve that smeared for 0.3s on the way in *and* out —
the HUD of no actual Apple device. Compiling guarantees nothing about how it looks.

So for an Apple behavior: **don't build it from memory — measure a reference, then build.** And record your own implementation and measure it the same way.

## Workflow

1. **Get a reference.** Ask the user for a screen recording from a real Apple device (or app). See "What to record" below.
2. **Look at it.** `scripts/filmstrip.sh` lays the frames out on one sheet with time labels — first write down which properties move (position, size, opacity, blur) and in what order.
3. **Measure it.** `scripts/track_video.sh` extracts the region's change per frame into CSV, and `scripts/fit_spring.py` fits a spring and reports it **with ranges**.
4. **Implement.** Pick the closest `Motion` value or Apple preset. If several presets fall inside the range, say they can't be told apart and match the 10%→90% time and overshoot instead.
5. **Measure yourself the same way.** Record your implementation in the simulator, measure it with the same tools and overlay it on the reference. If it's off, go back to 4.

## Tools

```bash
# ① frames as a filmstrip (window, frame count, frames per row, [crop x y w h])
scripts/filmstrip.sh ref.mov strip.png 2.0 3.2 16 4 0 330 1206 330

# ② region change as CSV (region x y w h, background frame time, analysis window, threshold, [fixed background color])
scripts/track_video.sh ref.mov 150 340 900 210 2.75 1.5 7.5 8 > data.csv         # a frame without the element as background
scripts/track_video.sh ref.mov 0 400 1206 240 0 0.3 9.8 60 253 > data.csv         # element always present → fixed background color (253)

# ③ fit a spring to one transition
python3 scripts/fit_spring.py data.csv --col bw --from 3.35 --to 4.4
python3 scripts/fit_spring.py --selftest                                          # verify the tool itself (≈25s)
```

**Which column to measure** — the cleaner the signal, the more trustworthy the fit.
| Column | What | Works well for | Careful |
| --- | --- | --- | --- |
| `bw` `bh` `bx` `by` | bounding box of changed pixels | size and movement of **crisp edges** (Dynamic Island width, sheet height) | blur and shadows soften the edge |
| `mean` | mean brightness difference ≈ opacity × area | opacity fades | mixes blur, size and content changes; repeated input makes the end value wobble |
| `count` | number of changed pixels | area changes | changes with the content too |

## Accuracy — claim only what was verified

- **The time axis is exact.** Measuring `linear(0.5s)` from a simulator recording gave 10%→90% = 0.400s and 10%→50% = 0.200s exactly.
- **The 10%→90% time** came out at **0.90–0.99×** the truth (about 5% short on average) for five known springs (smooth 0.30/0.60, snappy 0.42 ×2, bounce 0.35/0.28). Trust this for timing comparisons first.
- **The parameters (response, damping)** trade off against each other and are hard to pin to one value. With zero noise they're recovered exactly (0.1% error), but in practice the two blur together.
  So the tool reports **ranges**. They were calibrated to contain the truth 97% of the time on synthetic data (σ=0.02, 60fps, 36 cases) and 9/9 on real recordings with known answers (5 known springs + 4 Dynamic Island width windows) — **the sample is small, so read it as "about 95%".**
  Average width is about 0.17s for response and 0.36 for damping. In other words, one 60fps recording **can't always tell smooth, snappy and bouncy apart.**
- To sharpen it: a low-noise signal (`bw`, crisp edges), 120fps or more, a short window containing one transition. (On synthetic data at noise 0.005 and 120fps, widths shrank to 0.05s and 0.15.)
- **Things that aren't springs** won't fit. If `rmse` is above 0.08 it may be an ease or linear — then use the 10%→90% time and curve shape directly, not parameters.

## Recording your implementation in the simulator

The iOS Simulator tooling needs `xcode-select` pointing at Xcode (requires sudo). If it doesn't, use `simctl` through `DEVELOPER_DIR`.

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcrun simctl list devices booted                                   # find the UDID
xcrun simctl launch <UDID> <bundle.id> -autoDemo hud               # a launch argument that plays the demo by itself means no taps are needed
xcrun simctl io <UDID> recordVideo --codec h264 --force out.mov &  # stop with kill -INT
# build: env -i PATH="$PATH" HOME="$HOME" DEVELOPER_DIR=$DEVELOPER_DIR xcodebuild -project … -scheme … -sdk iphonesimulator -destination 'id=<UDID>' CODE_SIGNING_ALLOWED=NO build
```
- Recordings are **variable frame rate** — no frames while nothing changes, up to 120fps while moving. That's normal.
- Passing a harness's full environment can make the SwiftUI macro plugin server fail in `swiftc`/`xcodebuild`. Pass a minimal environment with `env -i`.
- An auto-play launch argument (`-autoDemo`) lets you re-record repeatedly without a person tapping.

## What to record (when asking the user)

- **The feature on a real Apple device**, start to finish, with a second of slack on each side. Repeating the same action 3–4 times lets you average.
- **60fps or more if possible.** iPhone/iPad screen recording is around 60fps; for finer detail, film the screen with another camera's slow motion (240fps).
- **System-drawn UI** such as the volume/brightness HUD **may not appear in screen recordings** (this varies by device and OS, so it isn't certain). If it doesn't, film it with another camera.
- If possible, once each in **light mode, dark mode, and with Reduce Motion on**.
- What to measure (common to every feature): start and end position and size / entry and exit time (10%→90%) / spring or ease / any overshoot /
  the order of properties that move together (which leads, which lags) / response to repeated input (holding a key) / response at max and min.
