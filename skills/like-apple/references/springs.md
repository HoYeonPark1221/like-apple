# Apple's springs — understand the structure instead of memorizing numbers

Grades: **[SDK]** measured directly with SwiftUI's `Spring` · **[WWDC]** from Apple's sessions · **[Approx.]** a value tuned by eye, not published by Apple.

## 1. Apple describes a spring with two numbers

| Form | Meaning | Used by |
| --- | --- | --- |
| `duration`, `bounce` | perceived length (s), amount of bounce | `.spring(duration:bounce:)`, `.smooth` `.snappy` `.bouncy` |
| `response`, `dampingRatio` | the same thing under other names | `.spring(response:dampingFraction:)` |

**[SDK] They are the same spring:** `duration = response`, `bounce = 1 − dampingRatio`
(e.g. ζ 0.85 ↔ bounce 0.15, ζ 0.72 ↔ bounce 0.28). Comparing the curves, the maximum difference is 0.0.
When you must build one from mass, stiffness and damping (`interpolatingSpring`): **mass = 1, stiffness = (2π ÷ response)², damping = 2 · ζ · √stiffness**
— **[SDK]** a spring built this way matches `Spring(response:dampingRatio:)` exactly, including with an initial velocity.

`duration` is the **perceived** length, not when it fully stops — a spring has an exponentially decaying tail **[WWDC]**.
To time something to the end of an animation, don't guess a delay; use `completionCriteria: .logicallyComplete` (recipes §17).

## 2. Apple's presets — values read from the SDK

| Preset | bounce | damping ζ | overshoot | settles within 1% | Character |
| --- | --- | --- | --- | --- | --- |
| `.smooth` | 0 | 1.00 | 0% | 0.53s | General purpose. No bounce |
| `.snappy` | 0.15 | 0.85 | 0.6% | 0.35s | Brisk, but doesn't bounce |
| `.bouncy` | 0.30 | 0.70 | 4.6% | 0.52s | Visibly springy |

Measured at each preset's default length (0.5s) [SDK]. Changing the length keeps the damping ratio — `.snappy(duration: 0.42)` is
**bit-for-bit the same curve** as `.spring(response: 0.42, dampingFraction: 0.85)` [SDK].

**Apple's guidance [WWDC23 "Animate with springs"]:** default to bounce 0. Raise it only to add playfulness, to make the end of a gesture feel physical,
or to add energy. Large bounce easily feels exaggerated in UI (re-check the exact threshold in the session video). Use it consistently with the app's personality.

## 3. The `Motion` vocabulary ↔ Apple presets

Values reached through trial and error line up with Apple's preset names [SDK + Approx.], so the `Motion` enum is written in Apple's names.

| `Motion` | Apple form | response | ζ | bounce | overshoot | settles within 1% |
| --- | --- | --- | --- | --- | --- | --- |
| `settle` | `.smooth(duration: 0.30)` | 0.30 | 1.00 | 0 | 0.0% | 0.32s |
| `present` | `.smooth(duration: 0.38)` | 0.38 | 1.00 | 0 | 0.0% | 0.40s |
| `pressRelease` | `.smooth(duration: 0.26)` | 0.26 | 1.00 | 0 | 0.0% | 0.27s |
| `morph` | `.snappy(duration: 0.42)` | 0.42 | 0.85 | 0.15 | 0.6% | 0.30s |
| flick landing | `.spring(duration: 0.42, bounce: 0.18)` | 0.42 | 0.82 | 0.18 | 1.1% | 0.40s |
| `lift` | slightly calmer than `.bouncy` | 0.35 | 0.72 | 0.28 | 3.8% | 0.37s |

Values that cause trouble [SDK]:

| Value | Overshoot | Result |
| --- | --- | --- |
| response 0.42, ζ **0.68** | **5.4%** | on a panel opening and closing (height 38↔175) it reads as "jumping" |
| response 0.50, ζ **0.50** | **16.3%** | toy-like wobble; rapid taps stack the wobbles |
| response 0.18, ζ 0.50 (a bell's "strike") | 16.3% | fine because it's short (0.25s) — large, but too brief to read as wobble |
| response 0.40, ζ 0.80 (a common default) | 1.5% | acceptable, but a number without intent |

**Reading overshoot by eye [Approx.]:** under 1% is "no bounce, just deceleration", 3–5% is "noticeably springy", 10%+ is "toy".

## 4. Which spring to pick

1. Did the hand give it momentum (flung, dragged in and landed)? **No** → `.smooth`, no bounce.
2. Is it a shape change the user caused (expanding, resizing, corners)? → `.snappy` (0.85) — deceleration without bounce.
3. Momentum, and playfulness fits? → bounce 0.2–0.3 (calmer than `.bouncy`).
4. A value that tracks time (a seconds countdown)? → linear, not a spring.
5. A filling surface (glass)? → ease.

## 5. Velocity and interruption

- **[WWDC23]** A spring carries the velocity at the end of a gesture, and if a new animation starts before the old one finishes, it continues from the current velocity toward the new target.
  That's why changing only the target (state-driven) is the basis of interruptible animation.
- **[WWDC24]** While a gesture keeps changing a value, `.interactiveSpring` makes each change inherit the previous animation so velocity never breaks.
- When you must hand over the release velocity *yourself*, use `.interpolatingSpring(…, initialVelocity:)` — the value is **velocity relative to the remaining distance** (recipes §11).

## 6. Measure it yourself

Measure the curve before settling on a value. Numbers are hard to judge by eye — 0.68 "looks fine" in code and still overshoots 5%.

```bash
scripts/spring_probe.sh 0.42 0.85        # response, dampingRatio → overshoot, settle time, Apple form
scripts/spring_probe.sh 0.42 0.82 1.5    # third argument: initial velocity (relative to remaining distance)
```
