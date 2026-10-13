---
name: like-apple
description: Make native APPS feel like Apple made them — Apple-style animation, sizing and platform behavior in SwiftUI for iOS, iPadOS and macOS, grounded in Apple's Human Interface Guidelines and distilled from building the Live Peninsula macOS notch app. Includes a catalog of Apple motion behaviors (Dynamic Island, pill HUD, genie, Liquid Glass morph, Siri glow, zoom transition, SF Symbol effects, number roll, sheet snapping, button press, countdown ring, reject shake) plus app-structure behavior (sheets, tab/navigation transitions, list insert/delete, loading, popover resize, iPad pointer effects); per-platform HIG rules (touch vs pointer vs keyboard, haptic patterns, size classes, Liquid Glass vs standard materials, component rules); Apple's spring system measured against the SDK; HIG-verified type sizes, control/bezel sizes and concentric corners; 29 code recipes compile-checked on iOS 17/26 and macOS 14/26 (written into the user's code only as needed, never dropped in as a whole file); and tools to MEASURE a reference recording. Use whenever the user builds or reviews a Swift/SwiftUI app UI and wants it to look, move or feel "like Apple" — "애플처럼/애플스럽게", "Dynamic Island처럼", "시스템 HUD처럼", "알람/타이머", "Liquid Glass", "스프링", "쫀득하게", "튕김", "전환", "햅틱", "동작 줄이기", "글자 크기", "베젤", "둥근 모서리", "여백", "아이패드 포인터", "맥에서 어색해", "HIG" — or says it feels cheap/janky/"구리다", even without naming Apple. Covers native apps on iOS, iPadOS and macOS for now; watchOS, visionOS and tvOS are not covered yet.
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

**Origin: Live Peninsula.** This skill is the result of building **Live Peninsula**, a macOS notch app, as a solo developer. To keep that app's philosophy — Apple-like motion,
rounded bezels and concentric corners, quietly precise movement like the system's — the notch's open/close spring, the hotkey HUD, files dragged into the tray,
the lock-screen music card and the studio timer ruler were built and rebuilt over and over: "it used to be like this; here's why it changed."
The principles in §3 (P1–P13) and every value graded [App] came from that process; the source file for each rule is in [evidence.md](references/evidence.md).
Apple's HIG and SDK measurements were layered on top so the same feel can be reached in any iOS · iPadOS · macOS app, not just Live Peninsula.

> The reference files are written in Korean; read them as-is. In them the [App] grade is written **[앱]**.

## 0. Where things are

| | What | File |
| --- | --- | --- |
| **Catalog** | 25 Apple behaviors (incl. app structure) broken into ingredients + implementation + evidence grade. Look here first | [references/catalog.md](references/catalog.md) |
| **Code recipes** | 29 ready-to-use recipes. Use as a starting point; write only what's needed | [references/recipes.md](references/recipes.md) (verification bundle: `assets/AppleMotion.swift` — compile-checked on macOS 14/26 · iOS 17/26 × Swift 5/6; never copied into the user's project) |
| **Springs** | Apple presets, damping ratio ↔ bounce, overshoot and settle time | [references/springs.md](references/springs.md), `scripts/spring_probe.sh` |
| **Platforms & app structure (HIG)** | iOS · iPadOS · macOS differences in input, haptics, layout and materials; HIG rules for sheets, tab bars, toolbars, popovers, alerts, lists, progress | [references/platforms.md](references/platforms.md) |
| **Sizes, type, bezels** | Apple type sizes (22 values SDK-verified for iOS/macOS), control/bezel sizes, concentric corners, Live Peninsula's current size audit | [references/metrics.md](references/metrics.md) |
| **Reference measurement** | Record an Apple device → view frames → numbers → spring fit (with ranges). Accuracy verified | [references/measurement.md](references/measurement.md), `scripts/filmstrip.sh` `track_video.sh` `fit_spring.py` |
| **Evidence** | Which Live Peninsula file or bug each rule came from | [references/evidence.md](references/evidence.md) |

**Evidence grades** — never mix them. **[Apple]** guaranteed by official APIs, sessions or HIG · **[SDK]** measured on this Mac's SDK ·
**[HIG]** Apple Human Interface Guidelines text · **[App]** an approximation that converged by eye in Live Peninsula. For behaviors whose curves Apple hasn't published — Dynamic Island, genie, Siri glow —
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
   When changing recipe code, edit `recipes.md` and regenerate with `python3 scripts/build_asset.py --check` (so docs and file never drift).
5. **Be honest.** State that [App]-grade behaviors are approximations. When asked for "Apple's values", separate [SDK]-measured values from [App] approximations.
6. **Check with your eyes.** Compiling doesn't guarantee the look. Record in the simulator and unroll frames with `filmstrip.sh`;
   if there's a reference, measure both with the same tools — this skill's own `Materialize` only revealed a 0.3s smear on exit after being recorded.
7. **Finish.** Reduced-motion replacement, rapid tapping and mid-motion grabs, slow-motion check, the §8 checklist. Breaking under rapid taps is the most common defect.

---

## 2. Apple's official motion principles (HIG)

A summary of [developer.apple.com/design/human-interface-guidelines/motion](https://developer.apple.com/design/human-interface-guidelines/motion).

- **Purposeful.** Motion supports the experience without overshadowing it. Motion for its own sake distracts and causes discomfort.
- **Optional.** Never convey important information through motion alone. Supplement with haptics and sound.
- **Realistic.** Follow gestures and expectations. Unrealistic motion disorients.
- **Brief and precise.** Light, unobtrusive animation communicates better.
- **No added motion on frequent interactions.** Standard elements already have subtle system motion. Let people cancel; don't make them wait on repeated interactions.
- **For people with Reduce Motion on [HIG Accessibility]:** reduce automatic and repeating animation (zoom, scaling, peripheral motion), **tone down spring bounce**, keep animation tied directly to gestures,
  don't animate z-axis depth changes, **replace x/y/z movement transitions with fades, and avoid animating blur in and out.**
- **Interruptible.** Don't make people wait for an animation to finish — especially one they see repeatedly. (→ P4)
- **Use animated symbols where they fit.** SF Symbols 5+ symbol animation (`symbolEffect`) comes before hand-made rotation or scaling.
- **Intensity depends on input.** Liquid Glass reacts more strongly to direct touch to feel tactile, and more calmly to a trackpad. (→ P15)
- **Be careful with fast-moving or blinking animation** [HIG Accessibility] — it can cause dizziness and, in severe cases, seizures. Endless glows and meshes stay slow and faint, and stop under Reduce Motion.
- **Minimize time-boxed elements** [HIG Accessibility] — never put important information or the only path to an action in a HUD or toast that disappears on its own.

---

## 3. Principles — rules hardened in Live Peninsula

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
name (`phaseSpring`, `LevelIconMotion.spring`). New animations pick a name, not a number.

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

| Goal | Use | Notes |
| --- | --- | --- |
| Smooth change when a value changes | `.animation(curve, value:)` | Applies to properties attached **above** the modifier. Put it *after* what it animates |
| Several state changes from an event handler | `withAnimation(curve) { ... }` | |
| Values changed outside `withAnimation`, e.g. timer callbacks | `.animation(curve, value:)` on the observing side | Attach it where the value is observed, not where it's set, or the transition won't run |
| Instant follow during drag | `withTransaction(Transaction(animation: nil))` | 1:1 |
| A different curve in one spot | `.transaction(value:) { t in t.animation = ... }` | e.g. linear only while locked, untouched otherwise |
| Numbers | `.contentTransition(.numericText(countsDown:))` + `.monospacedDigit()` | No sideways jitter when digit count changes |
| Flip an icon's state | `.contentTransition(.symbolEffect(.replace))` | iOS 18 / macOS 15: `.replace.magic(fallback:)` — guard with `#available` |
| One-off emphasis | `.symbolEffect(.bounce.down, value: count)` | Fix the value under Reduce Motion |
| Continuous value → many segments | `Animatable` + `Canvas` | recipes §7 |
| Appear/fold progress | `Animatable` `ViewModifier` (progress 0→1), view always mounted | recipes §6 |
| Paging | `.scrollTargetBehavior(.paging)` + `.scrollTransition(.interactive)` | recipes §12 |
| Landing that carries hand velocity | `.interpolatingSpring(mass:stiffness:damping:initialVelocity:)` | `.spring()` has no initial-velocity parameter |
| Insert/remove a view | `.transition(.asymmetric(...))` | Only where interruption can't happen |
| Per-frame updates | `TimelineView(.animation(minimumInterval:))` | 30fps was enough for progress bars |
| Repeating/delayed work | `.task { while !Task.isCancelled { ... } }` | Recursive `DispatchQueue` keeps running after the view is gone |
| Observing a value that changes every frame | Confine observation **inside** the modifier | Observing outside redraws the whole card every frame |
| Liquid Glass merging and splitting | `GlassEffectContainer` + `.glassEffectID(_:in:)` + `withAnimation(Motion.morph)` | recipes §14. Nearby glass must share a container |
| Opening like an app zooming in | `.matchedTransitionSource` + `.navigationTransition(.zoom(sourceID:in:))` | recipes §21. iOS 18 |
| A single "pop" | `keyframeAnimator(initialValue:trigger:)` + `SpringKeyframe` | recipes §16 |
| Doing something when an animation finishes | `withAnimation(_, completionCriteria: .logicallyComplete) { } completion: { }` | Don't guess time with `asyncAfter`. Fires when perceived duration ends |
| Replacing content with a blur | `.transition(.blurReplace)` | recipes §17 |
| Icon pop / pulse / wiggle | `.symbolEffect(.bounce / .pulse / .variableColor / .wiggle …)` | recipes §15. Look here before rotating things by hand |
| Endless glow or mesh | `repeatForever` at **different periods**; stop under `reduceMotion` | recipes §19·§20 |
| iPad pointer hover | `.hoverEffect(.highlight / .lift)` + `.contentShape(.hoverEffect, shape)` | recipes §24. macOS: `.onHover` brightness |
| Sheet size and dismissal | `.presentationDetents` · `.presentationDragIndicator(.visible)` · `.interactiveDismissDisabled(hasChanges)` | recipes §26. Never hand-build sheet dragging |
| Re-layout for large text or narrow windows | `AnyLayout(HStackLayout / VStackLayout)` + `.motion(Motion.settle, value:)` | recipes §27. Don't swap stacks with `if` |
| Separating content under a toolbar | `.scrollEdgeEffectStyle(.soft, for: .top)` (iOS 26 / macOS 26) | recipes §28. No background colors |
| Emphasizing the one key action | `.buttonStyle(.glassProminent)` (26) · `.borderedProminent` below that | Only one, trailing |
| Rejecting input | `.rejectShake(trigger:)` (`keyframeAnimator`) + `Haptics.play(meaning: .failure)` | recipes §29 |
| List insert/delete/move | Change data inside `withAnimation`, use `onDelete` · `onMove` | No per-row `.transition` |

---

## 6. Platform differences

Motion rules are identical across the three platforms. What differs is **input**, **haptics**, **space** and minimum OS (P15). HIG basis and per-component rules: [platforms.md](references/platforms.md).

| | iOS | iPadOS | macOS |
| --- | --- | --- | --- |
| Input | Finger, direct manipulation | Finger + pointer + keyboard | Pointer / trackpad |
| Hover | None (`.onHover` simply never fires; harmless) | `.onHover` / `.hoverEffect` with a pointer | **Required** — say "here" before the click |
| Horizontal swipe | Both `DragGesture` and scroll | Same | Two-finger swipes are *scroll events* → never reach `DragGesture`. Use `ScrollView` paging |
| Haptics | `.sensoryFeedback` (17+) or `UIFeedbackGenerator` | Most have no haptic engine — supplementary only | `.sensoryFeedback` compiles but is mostly **silent** (confirmed in Live Peninsula). Use `NSHapticFeedbackManager` (recipes §13) |
| Size | Fixed screen | Variable via Split View / Stage Manager — never assume fixed pt | Resizable windows |
| Press scale | 0.94–0.97 | Same | Same + hover brightness |
| Pointer effects | — | highlight (small, transparent background) · lift (small, opaque) · hover (large; tint instead of scale) — recipes §24 | Hover brightness + system cursors (`.pointerStyle`, macOS 15+) |
| Haptic meanings | notification (outcome) · impact (snap, collision) · selection (value change) | Mostly none | alignment · levelChange · generic, **only during drag or force click** — recipes §25 |
| Layout decisions | Size class + text size | Size class (windows change constantly) + text size | No size class — window width (`ViewThatFits`) + text size |
| Modals | Sheet with medium detent + grabber, swipe to dismiss | Page/form sheets; fewer modals and full-screen transitions | Fixed-size sheets, panels for repeated input. Other windows stay usable |
| Popovers | Not in compact → sheet | Only when wide | Detachable into a panel |
| Placement | Frequent controls in the reachable bottom/middle | Window controls must not cover leading toolbar buttons | Nothing important at the window bottom or behind the notch. Every command also in the menu bar |
| Liquid Glass response | Direct touch — strong | Strong for touch, calm for pointer | Trackpad — calm |

**Minimum OS** (lower bounds confirmed by recipe typechecks): `.numericText`, `.smooth`, `.symbolEffect`, `scrollTransition`, `.transaction(value:)`,
`scrollTargetBehavior` → **iOS 17 / macOS 14**. `Image(systemName:variableValue:)` → iOS 16 / macOS 13.
`.replace.magic` → iOS 18 / macOS 15 (guard with `#available`). To support lower versions, wrap only that modifier in `#available`
and fall back to an `.opacity` transition.

Split shared code with `#if os(macOS)` / `#elseif canImport(UIKit)` (see `Haptics`). Motion curves and the `Motion` enum never need to split.

---

## 7. Symptom → cause → fix

| Symptom | Cause | Fix |
| --- | --- | --- |
| Jumps on open/close | Damping 0.68 → 5% overshoot | 0.85 (overshoot <1%) |
| Icon flickers while a key is held | Symbol name swapped per value range | `variableValue` / `Animatable` + damping 1.0 |
| Text gets clipped by corners as the container folds | Content disappears later than the container | Exit faster than the container (0.13) |
| Swipe animation feels cheap | Native paging + manual settle spring on different beats | Keep only one |
| Flings away after a long pause before release | `DragGesture.velocity` keeps the last movement speed | Compute from the last 0.1s before release |
| Grabbing a moving ruler teleports it | Starts from the target value | Record the drawn value and start from there |
| UI freezes under rapid taps | Stacked `.transition` insert/remove + large blur | State-driven (always mounted) + shallower blur |
| Ruler/ring wobbles every second | Spring on a countdown | `linear(1)` |
| Press feels sluggish | Same curve for press and release | Press `easeOut 0.07` / release spring |
| Pressed button looks switched off | Press shown with `opacity` | `brightness(-0.07)` |
| Numbers jitter at two digits | Not fixed-width | `.monospacedDigit()` |
| Text slides and clips in a narrow column | `move` transition | `.contentTransition(.opacity)` |
| A view hidden with opacity still catches hover/drops | `opacity 0` doesn't disable hit-testing | Add `allowsHitTesting(!hidden)` |
| Animation keeps running after the view is gone | Self-calling `DispatchQueue.asyncAfter` | `.task` (cancels automatically) |
| The whole card redraws every frame | Per-frame value observed outside | Confine observation inside the modifier |
| No haptics felt on macOS | `.sensoryFeedback` is silent on Mac | `NSHapticFeedbackManager` |
| Still moves with Reduce Motion on | Curve changed but transforms (offset/scale) kept | Pin the transform values themselves to 0/1 |
| No response when the iPad pointer hovers | Custom button has no pointer effect | `.hoverEffect(.highlight / .lift)` (recipes §24) |
| Pointer flickers between bar buttons | Gaps between hit areas | Make hit areas contiguous |
| Hovered table row overlaps its neighbor | Scaling an adjacent element | Tint only (`.hover`) |
| Large text clips or overlaps rows | Fixed height, horizontal layout | Switch to vertical with `AnyLayout`, automatic row height (recipes §27) |
| Layout snaps when it changes | HStack/VStack swapped with `if` | `AnyLayout` + one shared spring |
| Area under the toolbar looks muddy and heavy | Background color/blur laid under the toolbar | Remove it; use a scroll edge effect (recipes §28) |
| Everything is glass and it's distracting | Glass on the content layer and many custom controls | Glass on the functional layer only; standard materials for content (P14) |
| Swiping a sheet closed lost unsaved work | Unsaved changes not protected | `interactiveDismissDisabled(hasChanges)` + confirm (recipes §26) |
| Sheet drag feels subtly unlike the system | Sheet was hand-built | System sheet via `presentationDetents` (P8) |
| A resizing popover looks like a different window | Size change not animated | Animate the size with `Motion.morph` (catalog 25) |
| Pressing does nothing and feels broken | Rejection/disabled state not shown | Dim disabled controls up front; `rejectShake` for rejection (recipes §29) |
| Looks frozen while loading | Indicator stopped, or spinner↔bar switch | A constantly moving, preferably determinate indicator (catalog 24) |
| HUD disappears before it can be read | Important info in a time-boxed element | Keep important info on screen; stay longer under VoiceOver (platforms §7) |

---

## 8. Finishing checklist

Skimming this while writing or reviewing code catches most problems.

- [ ] I can state in one line what information this motion carries.
- [ ] The curve comes from the §4 vocabulary; any new number has a comment explaining why.
- [ ] State changes and inertia-free input use damping 1.0. Any elasticity has a *source of momentum*.
- [ ] Press/release and enter/exit keep different time.
- [ ] Properties that move together share one spring. The same thing isn't animated in two places.
- [ ] Doesn't break under rapid taps or mid-motion grabs (state-driven, starts from the visible value).
- [ ] Values flow instead of jumping between ranges (`variableValue` / `Animatable` / `numericText`).
- [ ] Drags are 1:1, carry release velocity, and rubber-band at the edges.
- [ ] Nothing the system already does was rebuilt (sheet detents, paging, numericText, symbolEffect, glassEffectID, zoom transition).
- [ ] No motion added to frequent interactions (a held key) — the value flows and it appears once.
- [ ] [Apple] and [App] approximations were kept apart. No pretending to know private implementations.
- [ ] Information survives Reduce Motion (transforms removed, fade/brightness instead). Reduce Transparency and contrast settings checked too.
- [ ] Haptics only at meaningful moments (detents), same frame as the visual change. `NSHapticFeedbackManager` on macOS.
- [ ] Large blurs are short and shallow. Observation of per-frame values is narrowed.
- [ ] Text uses semantic styles (`.font(.body)` etc.) or Apple style sizes, and never goes below the minimum (iOS 11 / macOS 10pt).
- [ ] Control hit areas meet spec (iOS 44 / macOS 28pt; minimum 28 / 20). Nested rounded shapes are concentric (`outer − inset`).
- [ ] Repeating work uses `.task`. Decoration has `allowsHitTesting(false)`. Accessibility labels/values are set.
- [ ] Checked **per target platform**: touch and haptics on iPhone, pointer effects and variable windows on iPad, hover, cursors and the menu bar on Mac (P15).
- [ ] System components (sheets, tab bars, navigation, lists, popovers) are configured per HIG, not hand-built ([platforms.md §6](references/platforms.md)).
- [ ] Liquid Glass only on the functional layer, used sparingly. Standard materials for content. No background color under bars (P14).
- [ ] Haptics follow HIG pattern **meanings** and don't double up on standard controls. They can be turned off and the app is whole without them.
- [ ] Layout holds at the largest text size and the smallest and largest windows, and positions flow when it changes.
- [ ] Unavailable actions look unavailable (dimmed disabled, reject shake). Nothing important lives in elements that disappear on their own.

### Auditing existing code

```bash
# Curve kinds and frequency — check whether values for the same intent are scattered
grep -rhoE '\.(spring|smooth|snappy|easeInOut|easeOut|easeIn|linear)\([^)]*\)' --include='*.swift' . | sort | uniq -c | sort -rn | head -30

# Files that animate but never read Reduce Motion
comm -23 <(grep -rlE --include='*.swift' 'withAnimation|\.animation\(' . | sort) <(grep -rl --include='*.swift' 'accessibilityReduceMotion' . | sort)
```
