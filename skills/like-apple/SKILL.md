---
name: like-apple
description: Make SwiftUI apps on iOS, iPadOS and macOS move and feel like Apple made them — springs, press and hover feedback, drag-and-release, enter/exit timing, Liquid Glass, haptics, Reduce Motion, bezel and corner sizing — grounded in Apple's HIG, SDK measurements and hands-on motion research. Includes a catalog of Apple motions, 29 compile-checked recipes and tools to measure a reference recording. Use when building or reviewing Swift/SwiftUI UI that should feel Apple-like, or when motion feels cheap or janky — "애플처럼", "애플스럽게", "Dynamic Island처럼", "스프링", "쫀득하게", "튕김", "구리다". Native apps only; not watchOS, visionOS or tvOS yet.
---

# Like Apple — Apple-style motion for iOS · iPadOS · macOS apps

When asked for "like the Dynamic Island" or "like the system HUD", break the motion down into **what it is made of** and translate it precisely into SwiftUI.
Apple-like motion is not flashy; it is **quietly precise**, and it reduces to four sentences:

1. Carry the velocity the hand created.
2. Anything can be interrupted and reversed at any time.
3. Motion carries information (it is not decoration).
4. Don't exaggerate — bounce only when there is momentum.

**Scope: apps.** Native iOS · iPadOS · macOS apps only (SwiftUI first, UIKit/AppKit as support). watchOS · visionOS · tvOS are not covered yet (planned).
Beyond motion, match **sizing (bezels, rounded corners, type) and platform conventions (input method, haptics, materials, system components)** to Apple's HIG —
motion can be perfect and the app still won't feel like Apple if the iPad pointer gets no response or the Mac has no hover.

**Basis.** Know-how from researching Apple-like motion while building the Live Peninsula app, cross-checked against Apple's HIG and measured on the SDK.

## 0. Where things are

| | What | File |
| --- | --- | --- |
| **Catalog** | 25 Apple behaviors (incl. app structure) broken into ingredients + implementation + evidence grade. Look here first | [references/catalog.md](references/catalog.md) |
| **Code recipes** | 29 ready-to-use recipes. Use as a starting point; write only what's needed | [references/recipes.md](references/recipes.md) (verification bundle: `assets/AppleMotion.swift` — compile-checked on macOS 14/26 · iOS 17/26 × Swift 5/6; never copied into the user's project) |
| **Springs** | Apple presets, damping ratio ↔ bounce, overshoot and settle time | [references/springs.md](references/springs.md), `scripts/spring_probe.sh` |
| **Platforms & app structure (HIG)** | iOS · iPadOS · macOS differences in input, haptics, layout and materials; HIG rules for sheets, tab bars, toolbars, popovers, alerts, lists, progress | [references/platforms.md](references/platforms.md) |
| **Sizes, type, bezels** | Apple type sizes (22 values SDK-verified for iOS/macOS), control/bezel sizes, concentric corners | [references/metrics.md](references/metrics.md) |
| **Reference measurement** | Record an Apple device → view frames → numbers → spring fit (with ranges). Accuracy verified | [references/measurement.md](references/measurement.md), `scripts/filmstrip.sh` `track_video.sh` `fit_spring.py` |
| **Tools & fixes** | Which SwiftUI API for which motion, the full per-platform table, and 30 symptom → cause → fix entries | [references/tools-and-fixes.md](references/tools-and-fixes.md) |

**Evidence grades** — never mix them. **[Apple]** guaranteed by an official API or WWDC session · **[HIG]** written in the Human Interface Guidelines ·
**[SDK]** measured on a real SDK · **[Approx.]** a close reproduction of something Apple hasn't published. For behaviors whose curves Apple hasn't published — Dynamic Island, genie, Siri glow —
say "this is a close reproduction" and never pretend to know Apple's values.

---

## 1. When asked for an Apple behavior

0. **If it must match an Apple behavior exactly, start from a reference.** Things whose motion differs per feature — alarm, timer, volume HUD — are never built from memory.
   If the "per-feature" table at the bottom of the catalog lists it as *unmeasured*, ask the user for a recording and measure it with [measurement.md](references/measurement.md).
   (The first "system HUD" was built from guesswork and was judged "not Apple-like".)
1. **Name it and break it down.** Look it up in the table at the top of [catalog.md](references/catalog.md). If it isn't there, split it into ingredients — does it move on one spring?
   Do entrance and exit keep different time? Is there an origin (anchor)? Does a value flow (rather than names being swapped)? Is there momentum?
2. **Check whether Apple already does it.** If a system API exists, use it — sheet detents, `glassEffectID`, `.navigationTransition(.zoom)`,
   `symbolEffect`, `numericText`, scroll paging. A hand-built version turns "cheap" the moment its timing drifts from the system's (P8).
   **App-structure components** — sheets, tab bars, navigation, lists, popovers, progress — follow the HIG setup rules in [platforms.md §6](references/platforms.md).
   Decide **which platform** first — the same behavior is expected differently on iPhone (touch), iPad (touch + pointer) and Mac (pointer + keyboard) (P15).
3. **Pick the spring.** Choose from the `Motion` vocabulary using the question order in [springs.md §4](references/springs.md). If a value is in doubt, don't guess —
   measure overshoot with `scripts/spring_probe.sh <response> <ζ>`.
   Set **sizes** for type, controls, spacing and corners to Apple's specs too — [metrics.md](references/metrics.md) (styles like `.font(.body)`, `.appleHitTarget()`, concentric corners).
4. **Write the code.** Find the matching recipe in [recipes.md](references/recipes.md) and use it as a starting point, writing **only what's needed, fitted to the project's code style, names and structure**.
   Never copy `assets/AppleMotion.swift` wholesale — that file exists to check that the recipes compile. Insert it whole only if the user asks.
   If the project already has something similar (a `Motion`-like vocabulary, a button style), use or extend it instead of adding another.
   (Only when maintaining this skill itself: edit `recipes.md`, then regenerate with `python3 scripts/build_asset.py --check`. Never edit an installed copy.)
5. **Be honest.** State that [Approx.] behaviors are approximations. When asked for "Apple's values", separate [SDK]-measured values from [Approx.] ones.
6. **Check with your eyes.** Compiling doesn't guarantee the look. Record in the simulator and unroll frames with `filmstrip.sh`;
   if there's a reference, measure both with the same tools — this skill's own `Materialize` only revealed a 0.3s smear on exit after being recorded.
7. **Finish.** Reduced-motion replacement, rapid tapping and mid-motion grabs, slow-motion check, the §8 checklist. Breaking under rapid taps is the most common defect.

---

## 2. Apple's official motion principles (HIG)

From [HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion) and HIG Accessibility:
- **Purposeful, brief, precise, realistic** — motion supports the experience; it follows gestures and expectations; never motion for its own sake.
- **Optional** — never the only carrier of important information; pair with haptics or sound.
- **No added motion on frequent interactions**, and let people **cancel** — never make them wait on something they see repeatedly (→ P4).
- **Animated SF Symbols** (`symbolEffect`) before hand-made rotation or scaling.
- **Intensity follows input** — Liquid Glass reacts strongly to touch, calmly to a trackpad (→ P15).
- **Reduce Motion**: cut automatic/repeating motion, tone down bounce, no z-depth animation, x/y/z moves become fades, no blur in/out (→ P11).
- **Avoid fast or blinking motion** (dizziness, seizures); keep endless glows slow and faint.
- **Minimize time-boxed elements** — nothing important or the only path to an action in a HUD or toast that disappears on its own.

---

## 3. Principles

### P1. Critical damping (1.0) is the default. Elasticity only with momentum

Start at `dampingFraction: 1.0` (no overshoot). Bounce only when *the hand created momentum* — something was flung, or dragged in and landed.
- The **fact** that state changed must not bounce → `settle` (1.0).
- Overshoot on **inertia-free input** (key presses, taps) looks exaggerated → `present` (1.0).
- Shape changes the user caused get a very faint bounce (0.82–0.86) — 0.68 overshot by ~5% on open/close (height 38↔175) and visibly jumped;
  raising it to 0.85 dropped overshoot below 1% and left only deceleration.
- Only a dragged file landing on its target bounces like 0.72 — because that momentum really existed.

### P2. Start and end keep different time

Using the same curve both ways makes one side feel sluggish.
- **Press / release**: pressing is what the user just did, so there's no reason to wait → `easeOut 0.07`. Returning happens after the finger lifts → spring.
- **Enter / exit**: a fast exit (0.13) leaves nothing lingering. Content must already be empty before the container folds,
  or "an empty shell closes slowly, or text gets clipped by the corners". Entering is the reverse — the container opens first and content settles in with `delay(0.08)`.
- **Fill / drain** (surfaces like glass): `easeOut 0.55` filling, `easeIn 0.4` draining.

### P3. Properties that move together share one spring. Never animate the same thing in two places

Width, height and corner radius share the same `morph` spring — they must move as one or the shape warps.
Two animations on different beats within one motion make the screen look shaky:
- The container folds on press while the button bounces in place → remove the button's bounce (1.0).
- A manual "arrival spring" on top of native paging → keep only one. (This was the real cause of "the animation feels cheap".)

### P4. Interruptible — drive by state, start from the visible value

`if isOpen { View().transition(...) }` is an insert/remove animation and can't be interrupted. Tap again before it ends and removals and insertions
pile up; add a large blur and the main thread stalls. Anywhere interruption can happen (taps, toggles, things that get tapped rapidly):
- **Keep the view mounted** and draw it from a `progress`/`isOn` value. A spring retargets from its current value, so rapid taps continue smoothly.
- While a held key keeps sending new targets, the spring carries its current value and velocity — no break.
- If it can be *grabbed* mid-motion, start from the **value drawn on screen**, not the `@State` target (otherwise it teleports).
- Use `.transition` only where interruption can't happen, and state direction explicitly with `asymmetric`.

### P5. Flow values; don't swap names

Changing the symbol name per range (`wave.1 → .2 → .3`) cuts abruptly at each change and flickers when the value sits on a boundary.
Use `Image(systemName:variableValue:)` to light segments by value, or, where unsupported, animate a single `Animatable` value and
compute each segment's brightness per frame (separate `opacity` per segment lights them all at once). Use **damping 1.0** here —
segments switch as they cross thresholds, so a bounce flickers at the threshold.

### P6. Choose the curve by *what is moving*

| What moves | Curve | Why |
| --- | --- | --- |
| An object pushed by hand | spring | Objects have inertia |
| A filling **surface** (glass, water) | ease | A bounce looks like a panel wobbling, not water settling |
| A value that tracks time (seconds countdown) | **linear** (duration = tick period) | A spring wobbles every second |
| Text/image replacement | easeInOut 0.25–0.35 + `.opacity` | Brightness only, no movement — sliding text in a narrow column looks clipped |

### P7. Carry the hand's velocity (drag → animation)

No seam between drag and animation is what makes it "stick to the finger". (Code: recipes §11)
1. On grab, start from the **visible value** → 2. while dragging, 1:1 with `Transaction(animation: nil)` →
3. rubber-band past bounds → 4. compute velocity yourself from **the last 0.1s before release**, not `DragGesture`'s `velocity`
(it keeps the last speed even after the finger stops, so pausing mid-drag and releasing later still flings) →
5. **project** the resting point as `current + (v/1000)·d/(1−d)` and snap to the nearest target →
6. pass **velocity relative to the remaining distance** (`v ÷ (target − current)`) to `interpolatingSpring(initialVelocity:)` →
7. damping ~0.82 **only when flung**; 1.0 when released gently.

### P8. Don't rebuild what the system does

Horizontal pages are `ScrollView` + `.scrollTargetBehavior(.paging)` + `.scrollTransition(.interactive)`. Momentum projection, edge
rubber-banding and grab-to-reverse are already handled. In particular, **macOS swipes are two-finger trackpad scroll events and
never reach `DragGesture`.** Numbers use `.numericText`; icon swaps use `.symbolEffect(.replace)`.
A hand-built version turns "cheap" the moment its timing drifts from the system's.

### P9. Materials "arrive"

A plain fade reads as "switched on". Moving blur + scale + offset + opacity together from **the origin (anchor)** reads as "the material arrived".
- Blur costs every frame. A 280pt image's blur ate frames under rapid taps → radius 6→3, turned off past halfway.
- SwiftUI `.blur` doesn't apply to materials drawn by AppKit/UIKit (`NSVisualEffectView`, `NSGlassEffectView`, `UIVisualEffectView`) — apply it to content only.
- Text on glass recedes through weight and contrast, not faint gray (the background may show through).

### P10. Give motion meaning

- Pause as shrinking: when playback pauses, the album art shrinks to 0.94 — the state reads without text, and "paused" becomes a property of the object rather than a label.
- Time as shape: a shrinking ring (remaining time is the arc length); no need to read numbers.
- A bell hangs from the top (`anchor: .top`), swings with **decaying amplitude**, then **rests** after each ring. Constant amplitude reads as a machine vibrating; no rest reads as noise.
- An icon flipping state uses `symbolEffect(.replace)` in place; "this is the spot" uses `.bounce.down`.
- Disabled/paused dims to `opacity 0.5` like holding a breath — so a frozen state doesn't read as broken.

### P11. Reduce Motion means "replace", not "turn off"

Keep the information; change only the *movement*. Design a replacement for every motion.
- Spring → `easeOut 0.12–0.25` fade (`Motion.reduced`). Movement, scale, rotation, blur → remove; keep opacity/brightness only.
- Swinging bell → a breathing size pulse. Never remove the alert itself.
- Disable with a fixed trigger, e.g. `symbolEffect(.bounce, value: reduceMotion ? 0 : count)`.
- Called out by HIG: **animating blur in/out**, **x/y/z movement transitions** (→ fade), **spring bounce** (→ reduce). `Materialize` pins blur, offset and scale under Reduce Motion.
- Read `@Environment(\.accessibilityReduceMotion)` per view. To handle it in one place, use recipes §2's `.motion(_:value:)`.
- Also: `\.accessibilityReduceTransparency` (translucent → opaque, drop blur), `\.colorSchemeContrast` (stronger borders).

### P12. Input feedback: immediate, continuous, only at meaningful moments

- React at the **moment** of press (`isPressed`), not on release. Show press with `brightness(-0.07)` + `scale(0.94–0.96)`, not `opacity` —
  fading a filled pill makes it look switched off, not pressed.
- On pointer platforms (macOS, iPadOS with a pointer), hover says "here" first (`brightness +0.08`).
- Haptics **only when passing a detent** — not on grab or release. Larger units (5 min) one step stronger. Same frame as the visual change.
- Disabled controls dim to `opacity 0.35` — better than pressing and having nothing happen.
- Non-interactive decoration (halos etc.) gets `allowsHitTesting(false)`.

### P13. Values in one place, with reasons

Response 0.3–0.6 and damping 0.6–1.0 scattered across the same intent (state change) is what "an inconsistent app" is. Gather them in a
`Motion`-like enum under *names by kind*, with one line per constant explaining **why that value**. Even feature-local values get a `static let`
name (e.g. `static let phaseSpring`). New animations pick a name, not a number.

### P14. Materials separate layers — glass only on the functional layer

Liquid Glass is the material of **the functional layer floating above content** (toolbars, tab bars, sidebars, floating controls) [HIG Materials].
- The content layer (backgrounds, cards, lists) uses **standard materials** (`.regularMaterial` etc.), not glass. Exception: sliders and toggles that become glass only while touched.
- Use glass **sparingly** on custom controls. If everything is glass, glass loses its purpose of pointing at the content.
- Don't lay solid or translucent backgrounds under bars — let content flow beneath and lift controls with a **scroll edge effect**.
- **Clear glass only over photos and video**, with a 35% dim on bright backgrounds. Text-heavy surfaces (alerts, sidebars, popovers) use regular.
- Choose materials **by meaning, not apparent color** — they change with Reduce Transparency, Increase Contrast and the user's glass appearance setting.
Code: recipes §14 · §28. Details: [platforms.md §5](references/platforms.md).

### P15. Fit the platform's hand — same behavior, different input

Motion curves are the same on all three platforms. What changes is **what you touch it with**, and with it the kind and strength of feedback [HIG Pointing devices · Gestures · Playing haptics].
- **iPhone**: a finger presses directly → clear press response, haptics (by iOS pattern meaning). No custom drags that collide with system edge gestures.
- **iPad**: touch + **pointer** + keyboard mixed → add pointer effects (highlight · lift · hover). Most iPads have no haptic engine, so visuals come first. Window size changes constantly.
- **Mac**: pointer + keyboard → **hover first**, press one step calmer. System cursors with fixed meanings. Haptics only during drag or force click. Every command also in the menu bar.
- Decide layout by **available space (size class) and text size**, not device type. When it changes, don't swap views — let positions flow with `AnyLayout` (same reason as P5).
Code: recipes §24 (pointer) · §25 (haptic meaning) · §27 (layout). Details: [platforms.md §1–4](references/platforms.md).

---

## 4. Motion vocabulary

Same table as the `Motion` enum in recipes §1. Written with **Apple preset names**; each value's overshoot and settle time are
measured in [springs.md](references/springs.md). (`.snappy(duration: 0.42)` is bit-for-bit the same curve as `.spring(response: 0.42, dampingFraction: 0.85)` [SDK].)

| Name | Apple form | Use |
| --- | --- | --- |
| `settle` | `.smooth(duration: 0.30)` | State changes: toggles, surfaces appearing/disappearing, hover, drop state |
| `present` | `.smooth(duration: 0.38)` | HUDs and cards raised by inertia-free input |
| `morph` | `.snappy(duration: 0.42)` | User-caused size, corner, expansion (several properties on one spring) |
| `lift` | `.spring(duration: 0.35, bounce: 0.28)` | Leftover momentum from a drag: landing on a drop target |
| `flick` | `interpolatingSpring` + initial velocity, ζ 0.82 (bounce 0.18) | Settling after a fling (ζ 1.0 if released gently) |
| `pressDown` | `.easeOut(duration: 0.07)` | The moment of press |
| `pressRelease` | `.smooth(duration: 0.26)` | Returning after release (up to bounce 0.38 if elasticity is wanted — only with no overlapping motion) |
| `exit` | `.easeIn(duration: 0.13)` · `.linear(0.05–0.20)` | Leaving. Faster than the container |
| `enterAfter` | `.spring(duration: 0.42, bounce: 0.16)` + `.delay(0.08)` | Content settling after the container opens (`contentDrop`) |
| `swap` | `.easeInOut(duration: 0.28)` | Text/image replacement (`.contentTransition(.opacity)`) |
| `roll` | `.smooth(duration: 0.30)` | Rolling numbers (`.numericText`) |
| `tick` | `.linear(duration: 1)` (same length as the update period) | Values updated every second |
| `fill` | `.easeOut(0.55)` in / `.easeIn(0.40)` out | Filling surfaces (glass) |
| `reduced` | `.easeOut(duration: 0.2)` | Reduce Motion replacement for every motion |

> Older parts of a codebase often use 0.7–0.8 damping (values written before P1). Follow whichever value was *later changed with a stated reason*.
> When fixing existing code, don't rewrite everything — move only the animations you touch onto the vocabulary.

---

## 5. Choosing the tool

Which SwiftUI API to use for each kind of motion (`.animation` vs `withAnimation`, drags, numbers, symbols, paging, glass, zoom, sheets, layout changes, rejection, lists) is a lookup table in [tools-and-fixes.md §1](references/tools-and-fixes.md). Two rules that matter most:
- `.animation(curve, value:)` applies to properties **above** it — put it after what it animates, and attach it where the value is *observed* (values changed outside `withAnimation` won't animate otherwise).
- A landing that carries hand velocity needs `.interpolatingSpring(...initialVelocity:)`; `.spring()` has no initial-velocity parameter.

---

## 6. Platform differences

Motion rules are identical across the three platforms. What differs is **input**, **haptics**, **space** and minimum OS (P15). HIG basis and per-component rules: [platforms.md](references/platforms.md).

The full per-platform table (input, hover, swipes, haptics, size, pointer effects, layout, modals, popovers, placement, Liquid Glass response) is in [tools-and-fixes.md §2](references/tools-and-fixes.md).

**Minimum OS** (lower bounds confirmed by recipe typechecks): `.numericText`, `.smooth`, `.symbolEffect`, `scrollTransition`, `.transaction(value:)`,
`scrollTargetBehavior` → **iOS 17 / macOS 14**. `Image(systemName:variableValue:)` → iOS 16 / macOS 13.
`.replace.magic` → iOS 18 / macOS 15 (guard with `#available`). To support lower versions, wrap only that modifier in `#available`
and fall back to an `.opacity` transition.

Split shared code with `#if os(macOS)` / `#elseif canImport(UIKit)` (see `Haptics`). Motion curves and the `Motion` enum never need to split.

---

## 7. Symptom → cause → fix

When the user describes a symptom ("it jumps", "feels cheap", "text gets clipped", "flings away", "freezes on rapid taps", "no response on iPad hover"…), look it up in [tools-and-fixes.md §3](references/tools-and-fixes.md) — 30 symptoms with cause and fix.

---

## 8. Finishing checklist

- [ ] The motion's information fits in one line; the curve comes from §4, and any new number has a comment saying why.
- [ ] Damping 1.0 for state changes and inertia-free input; any bounce has a source of momentum (P1).
- [ ] Press/release and enter/exit keep different time; properties moving together share one spring (P2, P3).
- [ ] Survives rapid taps and mid-motion grabs; values flow instead of jumping (P4, P5).
- [ ] Drags are 1:1, carry release velocity and rubber-band at the edges (P7).
- [ ] Nothing the system does was rebuilt (detents, paging, numericText, symbolEffect, glassEffectID, zoom); system components follow [platforms.md §6](references/platforms.md) (P8).
- [ ] [Apple]/[HIG]/[SDK] facts and [Approx.] reproductions kept apart.
- [ ] Reduce Motion keeps the information (transforms removed, fades instead); Reduce Transparency and contrast checked (P11).
- [ ] Haptics only at detents, by HIG meaning, same frame as the visual; `NSHapticFeedbackManager` on macOS; optional.
- [ ] Semantic text styles, hit areas at spec (iOS 44 / macOS 28pt), concentric nested corners ([metrics.md](references/metrics.md)).
- [ ] Liquid Glass only on the functional layer, used sparingly (P14).
- [ ] Checked per platform — touch on iPhone, pointer and resizable windows on iPad, hover, cursors and menu bar on Mac (P15).
- [ ] Holds at the largest text size and window extremes; unavailable actions look unavailable; nothing important in self-dismissing elements.
- [ ] Repeating work in `.task`; decoration `allowsHitTesting(false)`; blurs short and shallow; accessibility labels set.

To audit an existing codebase (scattered curves, files that never read Reduce Motion), use the commands in [tools-and-fixes.md §4](references/tools-and-fixes.md).
