# Apple motion catalog — from "make it like that" to SwiftUI

When someone says "like the Dynamic Island", "like the system HUD" or "like the Siri glow", first break the motion down into **what it is made of**.
Apple's motion is usually a combination of a few ingredients — one shared spring, asymmetric timing, an anchor, a value that flows. Each entry below gives the ingredients and the implementation.

**Evidence grades** — never blur them. What Apple publishes and what is reproduced by eye are different things.
- **[Apple]** Behavior guaranteed by an official API, WWDC session or guideline. Use as is.
- **[HIG]** Written in Apple's Human Interface Guidelines.
- **[SDK]** Measured on a real SDK (see [springs.md](springs.md)).
- **[Approx.]** A close reproduction of something Apple hasn't published. Say it "looks close", never that it *is* Apple's implementation.

Code lives under the same number in [recipes.md](recipes.md). Spring values are explained in [springs.md](springs.md). Sizes, type and corners are in [metrics.md](metrics.md).

| When they say | Entry |
| --- | --- |
| Button press, tap feedback | 1 |
| Toggle, something switching on and off | 2 |
| Drag a card and let it snap into place | 3 |
| A small pill-shaped status HUD or toast (custom) — for Apple's own system HUDs see "Per-feature" below | 4 |
| Like the Dynamic Island — a pill that grows and shrinks | 5 |
| Mac minimize (genie), being sucked in | 6 |
| Liquid Glass shapes merging and splitting | 7 |
| Rolling numbers, an icon swapping | 8 |
| An icon that pops, pulses or wiggles | 9 |
| A screen that zooms open from what you tapped | 10 |
| Paging like the Home Screen | 11 |
| Timer ring, progress | 12 |
| A ringing notification bell | 13 |
| Siri / Apple Intelligence glow | 14 |
| The handwritten "hello" | 15 |
| Rubber-band at the edge, fling to go further | 16 |
| Haptics under the finger | 17 |
| A sheet sliding up, half open, swiped away | 18 |
| "No" — dragging something locked, a wrong password | 19 |
| Pointer hover (iPad, Mac) | 20 |
| Layout reflowing for large text or a narrow window | 21 |
| List rows inserting, deleting, reordering | 22 |
| Switching tabs, pushing and popping screens | 23 |
| Loading and progress | 24 |
| A popover or panel changing size | 25 |

Platform guidance behind 18–25 is in [platforms.md](platforms.md).

---

### 1. Press — buttons and controls
**Ingredients:** shrink and dim slightly the instant it's pressed (0.07s) → return on a spring with no bounce on release → on pointer platforms, brighten on hover.
Show press with `brightness`, not `opacity` — a filled pill that turns translucent looks switched off, not pressed.
**Implementation:** `PressableStyle` (recipes §3). On Liquid Glass, `.glassEffect(.regular.interactive())` lets the system handle scale, bounce and shimmer [Apple, WWDC25].
**Grade:** [Approx.] values + [Apple]

### 2. Toggle — a surface appearing
**Ingredients:** the *fact* that state changed must not bounce → `Motion.settle` (smooth). Disabled dims to `opacity 0.35`, paused to `0.5`, like holding a breath.
**Implementation:** `.motion(Motion.settle, value:)` (recipes §1, §2). **Grade:** [Apple] default bounce 0 + [Approx.]

### 3. Drag a card and let it snap into place
**Ingredients:** 1:1 while dragging (no animation) → project the resting point from the velocity of the *last 0.1s* before release → nearest slot → pass velocity relative to the remaining distance to the spring →
ζ≈0.82 only when flung → rubber-band past the ends → on grab, start from the *visible* position.
**Check first:** standard iOS/iPadOS sheets already do all of this with `.presentationDetents`. Build it yourself only when a custom surface truly needs it.
**Implementation:** `SnapDragExample` · `PresentedOffset` · `Physics` · `VelocityTracker` (recipes §11). **Grade:** [Apple] velocity handoff (WWDC23) + [Approx.]

### 4. Pill-shaped status HUD (custom — not Apple's system volume/brightness HUD)
**Know this first:** this is a *custom* pill HUD pattern. It does **not** reproduce the actual iPhone, iPad or Mac system HUDs, which have their own shape and motion.
Don't apply it to "make it like the system HUD" — Apple's real HUDs aren't measured yet (see "Per-feature" below). Get a reference first.
**Ingredients:** ① appear with `present` (smooth) — a key press has no momentum ② the material *arrives* (blur + scale + offset + opacity, anchored at the edge it came from) ③ leave faster (`exit`)
④ the icon flows with `variableValue` instead of swapping symbol names ⑤ auto-hide after ~2s with `.task(id:)` — restarts on every input, cancels when the view goes away ⑥ while a key is held,
the HUD appears once and only the value flows (HIG: no added motion on frequent interactions).
**Known weak spots (seen in recordings):** a blur dissolve can look smeared · dotted `SegmentMeter`s read as a dashed line (a continuous bar or cells read better) ·
`.ultraThinMaterial` nearly disappears on white (needs contrast and a shadow) · a 0.13s `exit` vanishes in three frames — cleaner than smearing, but not confirmed to be what Apple does.
**Implementation:** `Materialize` · `SegmentMeter` · `.task(id:)` (recipes §4, §7). **Grade:** [Approx.] + [HIG]

### 5. Like the Dynamic Island — a pill that grows and shrinks
**Ingredients:** ① width, height and corner radius on **one shared spring** (`morph`) ② outgoing content clears before the container shrinks ③ incoming content settles in after the container opens (`contentDrop`)
④ the corner goes between capsule (height / 2) and a small radius, and the clip uses the same value.
Apple hasn't published the real curve or sizes. **Say it's a close reproduction** and that the sizes are examples.
**Bounce is undecided:** `morph` here (.snappy, overshoot <1%) is a "decelerate without bouncing" choice, not Apple's value. Whether the real Dynamic Island bounces more hasn't been measured;
a version built without this skill used bounce 0.30 (≈4.6% overshoot). Without a reference recording, don't claim either is right.
**Implementation:** `IslandMorph` · `.contentDrop` (recipes §5, §18). **Grade:** [Approx.]

### 6. Genie — being sucked in and coming back out
**Ingredients:** scale pinned to the point it's sucked into (anchor) + **height first, width later** (exponents 0.6 vs 2.0) + a shallow blur only early on + opacity snaps in fast.
The real genie is a curved warp Core Animation applies to windows only, so views can't use it — this reproduces the impression. Keep the view **always mounted** and draw it from `progress` (safe under rapid taps).
**Implementation:** `EmergeFromSource` (recipes §6). **Grade:** [Approx.]

### 7. Liquid Glass merging and splitting
**Ingredients:** put glass elements in a `GlassEffectContainer` and give `glassEffectID(_:in:)` a shared namespace; the system morphs them on state changes. Curve: `morph`.
Glass can't sample other glass, so nearby glass must share a container.
**Watch out (macOS, AppKit):** an `NSGlassEffectView` in a window that isn't key (an inactive panel, say) can render as a dark slab — overriding the panel's `hasKeyAppearance` to return true fixes it (observed on macOS 27.2).
**Implementation:** `GlassMorphMenu` (recipes §14). **Grade:** [Apple, WWDC25]

### 8. Rolling numbers, swapping icons
**Ingredients:** numbers roll digit by digit with `.numericText(countsDown:)` (the direction must match reality) + `.monospacedDigit()`. Titles and names swap with `.opacity`, not a slide.
An icon that flips state (play ↔ pause) uses `.symbolEffect(.replace)` in place; `.replace.magic` where iOS 18 / macOS 15 allow.
**Implementation:** `TransitionsExample` · `.symbolReplace` (recipes §10). **Grade:** [Apple]

### 9. An icon that pops, pulses or wiggles
**Ingredients:** reach for symbol effects before rotating anything by hand — `.bounce` (arrival), `.pulse` (waiting), `.variableColor.iterative` (signal), `.wiggle` · `.breathe` · `.rotate` (iOS 18 / macOS 15). `value:` for once, `isActive:` for continuous.
**Implementation:** `SymbolEffectsTour` (recipes §15). A one-off "pop" is `Pop` (§16). **Grade:** [Apple]

### 10. A screen that zooms open from what you tapped
**Ingredients:** `matchedTransitionSource` on the source, `.navigationTransition(.zoom(sourceID:in:))` on the destination, one namespace. The system also hands off velocity while you drag it closed.
**Implementation:** `ZoomTransitionExample` (recipes §21, iOS 18). **Grade:** [Apple, WWDC24]

### 11. Paging like the Home Screen
**Ingredients:** system paging (`.scrollTargetBehavior(.paging)`) with depth added by `scrollTransition(.interactive)` (neighbor pages fade and recede). Don't add a manual "arrival spring" —
two beats overlap and it feels cheap. On macOS, two-finger swipes never reach `DragGesture`.
**Implementation:** `PagedDeck` · `PageDepth` (recipes §12). **Grade:** [Apple] paging + [Approx.] depth

### 12. Timer ring — time as shape
**Ingredients:** a shrinking ring (remaining time is the arc length) · the elapsed part stays faintly visible · starts at 12 o'clock · `linear(1s)` while running, a short ease when stopped · 0.5 opacity when paused.
**Implementation:** `CountdownRing` (recipes §8). **Grade:** [Approx.]

### 13. A ringing notification bell
**Ingredients:** hangs from the top (`anchor: .top`), swings with **decaying amplitude**, then rests after each ring. Under Reduce Motion it breathes in size instead of swinging.
**Implementation:** `DecayingShake` (recipes §9). **Grade:** [Approx.]

### 14. Siri / Apple Intelligence glow
**Ingredients:** ① a comet stroke: the head leads, the tail follows and catches up at the end ② the same stroke stacked in three blur layers for light ③ an angular gradient larger than the shape, rotated linearly and masked to the border
④ a mesh gradient drifting at **different periods**. Endless loops stop under Reduce Motion (HIG: avoid sustained oscillation).
Apple's implementation is private — this is a reproduction. **Implementation:** `CometStroke` · `RotatingGlowBorder` · `LivingMesh` (recipes §19, §20). **Grade:** [Approx.]

### 15. The handwritten "hello"
**Ingredients:** draw a vector path progressively with `trim`. `CometStroke(tail: 1)` draws it and then erases it. The path is a design-tool vector converted into a `Shape` in unit coordinates. Long `easeInOut` (≈4s).
**Implementation:** `CometStroke` (recipes §19). **Grade:** [Approx.]

### 16. Rubber-band at the edge, fling to go further
**Ingredients:** rubber-banding `x·d·c / (d + c·x)` (c≈0.55), momentum projection `(v/1000)·r/(1−r)` (r≈0.99). System scroll views already do this — only hand-built drags need it.
**Implementation:** `Physics` (recipes §11). **Grade:** [Apple] concept (WWDC18) + [Approx.] constants

### 17. Haptics under the finger
**Ingredients:** only when crossing a detent, in the same frame as the visual change; larger detents one step stronger. On macOS use `NSHapticFeedbackManager` (`sensoryFeedback` is mostly silent on Mac); most iPads have no haptic engine, so visuals come first.
**Implementation:** `Haptics` (recipes §13, §25). **Grade:** [HIG] haptics complement motion + [Approx.]

### 18. Sheets — sliding up, half open, swiped away
**Ingredients:** all of it belongs to the system — velocity handoff, snapping to detents, edge rubber-banding, the background dimming and receding. A hand-built sheet drifts out of step with the system's.
**Configure (HIG):** on iPhone start at the medium detent with a grabber; support swipe-to-dismiss (block it only with unsaved changes, then confirm); one sheet at a time.
iPad uses page/form sheets; macOS sheets get a fixed size that fits their content.
**Implementation:** `SystemSheetExample` (recipes §26). **Grade:** [Apple] + [HIG]

### 19. Saying "no"
**Ingredients:** no response at all reads as a frozen app [HIG Gestures]. ① dragging something locked **follows a little, then resists** (rubber-band, snaps back on release — you feel that it can't move)
② rejected input gets **a short side-to-side shake that dies down** (the familiar wrong-password shake) + the `failure` haptic on iOS ③ disabled controls are dimmed up front (`opacity 0.35`) so people don't have to press to find out.
Keep the shake short (3–4 decaying swings); under Reduce Motion, don't shake — change a border or text color instead.
**Implementation:** `Physics.rubberBand` (recipes §11) · `.rejectShake(trigger:)` (recipes §29) · `Haptics.play(meaning: .failure)` (recipes §25).
**Grade:** [HIG] "indicate when a gesture isn't available" + [Approx.] shake curve (Apple's isn't measured)

### 20. Pointer hover (iPadOS, macOS)
**Ingredients:** on iPadOS, the system pointer effects — highlight for small elements on a transparent background, lift for small opaque ones (rises, shadow, specular, magnetism), hover for large ones (tint; scale only if it won't collide with neighbors).
On macOS, a `+0.08` hover brightness and system cursors. Make bar-button hit areas contiguous so the pointer doesn't flicker between them.
**Implementation:** `.applePointerEffect(_:)` (recipes §24). **Grade:** [Apple] `hoverEffect` + [HIG] + [Approx.] macOS brightness

### 21. Layout reflowing for large text or a narrow window
**Ingredients:** side-by-side views stack vertically at large text sizes or narrow widths. Swapping `HStack`/`VStack` with `if` rebuilds the views and snaps → `AnyLayout` keeps identity, so positions flow on one spring.
Decide by size class and text size, not device type [HIG].
**Implementation:** `AdaptiveRow` (recipes §27). **Grade:** [Apple] + [HIG]

### 22. List rows inserting, deleting, reordering
**Ingredients:** change the `List`/`ForEach` data inside `withAnimation(Motion.settle)` and the system flows inserts, deletes and moves. Don't add a `.transition` per row (it fights the system's row animation).
Swipe-to-delete and edit-mode reordering use the system motion of `onDelete` / `onMove`. A drill-down list keeps the **selected row highlighted** when you come back.
**Grade:** [Apple] + [HIG]

### 23. Switching tabs, pushing and popping screens
**Ingredients:** use the default transitions of `TabView` and `NavigationStack`. Tabs are a **frequent interaction**, so don't add custom slides or fades [HIG].
Push/pop is a system transition that can be **grabbed mid-way and reversed** with the edge swipe — a custom transition loses that interruptibility. Only screens that grow out of content use `.navigationTransition(.zoom)` (entry 10).
**Grade:** [Apple] + [HIG]

### 24. Loading and progress
**Ingredients:** determinate (`ProgressView(value:)`) whenever possible, advancing evenly. Indicators **never stop moving** (stopped = broken). Indeterminate → determinate is fine; **spinner ↔ bar is not.**
Show **something as soon as possible** while waiting (`.redacted(reason: .placeholder)`). A button whose action doesn't finish instantly shows a spinner inside the button.
The launch screen matches the first screen so nothing flashes at the hand-off.
**Grade:** [HIG]

### 25. A popover or panel changing size
**Ingredients:** a popover switching between compact and expanded views **animates its size** — an instant jump looks like a different popover replaced it [HIG]. Width, height and corners share `Motion.morph`;
content leaves fast and arrives late. Keep HUD-style panels small.
**Implementation:** same ingredients as `IslandMorph` (recipes §18). **Grade:** [HIG] + [Approx.]

---

## Per-feature Apple motion — not measured yet

The alarm, the timer countdown, the stopwatch and the volume HUD **all move differently.** Each has its own curves, order and materials, and lumping them into "a timer ring like that"
is exactly what stops it feeling like Apple. These need a **reference measured before building**. There are no confirmed values, so don't fill them in from memory.
How to measure, and how accurate it is: [measurement.md](measurement.md). Once measured, move the entry up into the numbered list with its values.

| Feature | Status | What to measure first |
| --- | --- | --- |
| iOS volume HUD | **Unmeasured** | position, size, shape (how the fill rises) / entry and exit direction and timing / response at max and min / the fill curve as the value changes / material (light, dark) |
| macOS volume/brightness HUD | **Unmeasured** | position (may differ by OS version) / cell shape / entry and exit timing / holding the key down |
| Clock › Timer | **Unmeasured** | whether the ring shrinks linearly during the countdown / how digits update / the start-pause button transition / what happens at zero |
| Clock › Alarm | **Unmeasured** | screen and icon motion when it rings / the on-off toggle / deceleration of the time wheel |
| Clock › Stopwatch | **Unmeasured** | how laps enter the list / how the hands and digits update |
| AirPods pairing card | **Unmeasured** | the curve of the card rising from the bottom / the 3D model's entrance / dismissal |
| Charging indicator | **Unmeasured** | how long the icon or ring takes to fill, and its curve / color change |
| Control Center toggles | **Unmeasured** | press scale / color and icon change when turning on / the shape change on long-press expansion |

When someone asks for one of these "like Apple": ① ask for a reference recording ② measure it ③ until then, say **"this one hasn't been measured yet"**,
and if you use a numbered entry as a stand-in, say it's an approximation.
