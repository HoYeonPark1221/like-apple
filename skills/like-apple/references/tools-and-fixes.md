# Tools and fixes — lookup tables moved out of SKILL.md

Read this when choosing a SwiftUI API for a motion (§1), checking platform specifics (§2), or diagnosing a reported symptom (§3), or auditing existing code (§4).

## 1. Choosing the tool

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

## 2. Platform differences

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

## 3. Symptom → cause → fix

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

## 4. Auditing existing code

```bash
# Curve kinds and frequency — check whether values for the same intent are scattered
grep -rhoE '\.(spring|smooth|snappy|easeInOut|easeOut|easeIn|linear)\([^)]*\)' --include='*.swift' . | sort | uniq -c | sort -rn | head -30

# Files that animate but never read Reduce Motion
comm -23 <(grep -rlE --include='*.swift' 'withAnimation|\.animation\(' . | sort) <(grep -rl --include='*.swift' 'accessibilityReduceMotion' . | sort)
```
