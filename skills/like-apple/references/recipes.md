# Recipes — SwiftUI motion code to start from

The ```swift blocks below **compile as-is when concatenated top to bottom into one file**
(typechecked with minimum targets iOS 17+ / iPadOS 17+ / macOS 14+, in both Swift 5 and Swift 6 language modes —
`nonisolated` on `animatableData` avoids Swift 6 MainActor isolation errors). Names don't collide, so you can lift
any single block; blocks depend only on the first one (`Motion`).

**How to use:** a recipe is a starting point. Bring only what's needed into the user's project, renamed and restyled to fit it.
`assets/AppleMotion.swift` concatenates every block only to check that the recipes compile — never copy it wholesale.

Contents
1. Motion vocabulary `Motion` (Apple preset names)
2. Reduce Motion in one place `.motion(_:value:)`
3. A button that reacts the instant it's pressed `PressableStyle`
4. A material that arrives `Materialize`
5. Different entrance and exit `contentDrop`
6. An entrance you can interrupt `EmergeFromSource` (state-driven)
7. A value that flows `SegmentMeter` (Animatable + Canvas)
8. A shrinking ring `CountdownRing`
9. A decaying swing `DecayingShake`
10. Number and symbol transitions
11. A drag that carries the hand's velocity `SnapDragExample`
12. Page depth `PagedDeck`
13. Haptics per platform `Haptics`
14. Liquid Glass morphing `GlassMorphMenu` (Apple API)
15. SF Symbols effects at a glance `SymbolEffectsTour`
16. A keyframe "pop" `Pop`
17. Knowing when it finished + blur replace `CompletionExample`
18. A Dynamic Island–style shape change `IslandMorph`
19. Comet-stroke glow `CometStroke` · rotating border `RotatingGlowBorder`
20. A living mesh `LivingMesh`
21. Zoom transition `ZoomTransitionExample` (iOS 18)
22. Control and bezel specs, minimum hit area `AppleMetrics` · `.appleHitTarget()`
23. Concentric corners `ConcentricCardExample`
24. Pointer effects `.applePointerEffect(_:)` (iPadOS highlight · lift · hover / macOS hover)
25. Haptics chosen by meaning `Haptics.play(meaning:)` (HIG pattern meanings)
26. System sheets `SystemSheetExample` (detents · grabber · protecting unsaved changes)
27. Layout that flows with space `AdaptiveRow` (Dynamic Type · size class)
28. Layering Liquid Glass `GlassLayeringExample` (iOS 26 / macOS 26)
29. Reject shake `.rejectShake(trigger:)`

---

## 1. Motion vocabulary

Gather values under names instead of scattering numbers through the code. The name says "what kind of motion this is",
so a new animation picks a kind, not a number.

```swift
import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum Motion {
    /// The fact that state changed (toggles, surfaces appearing/disappearing, hover, drop state).
    /// Apple `.smooth` — bounce 0. A fact shouldn't bounce, so critical damping is the default.
    static let settle = Animation.smooth(duration: 0.30)

    /// HUDs and cards raised by inertia-free input (keys, taps). Overshoot on motion without momentum looks exaggerated.
    static let present = Animation.smooth(duration: 0.38)

    /// Shape changes the user caused (expanding, resizing, corners). Apple `.snappy` — bounce 0.15 (damping 0.85).
    /// Overshoot stays under 1%, so there's deceleration without bounce.
    static let morph = Animation.snappy(duration: 0.42)

    /// Motion with leftover momentum from a drag (a file landing on a target, after a fling). Slightly calmer than `.bouncy` (0.30): 0.28.
    static let lift = Animation.spring(duration: 0.35, bounce: 0.28)

    /// Pressing is what the user just did — no reason to wait. Nearly instant.
    static let pressDown = Animation.easeOut(duration: 0.07)
    /// What happens after release returns like an object.
    static let pressRelease = Animation.smooth(duration: 0.26)

    /// Leave faster than you arrive. Nothing lingers, and content clears before the container folds.
    static let exit = Animation.easeIn(duration: 0.13)

    /// Text and image replacement. No movement, only brightness.
    static let swap = Animation.easeInOut(duration: 0.28)

    /// Reduce Motion replacement. Drop the movement; keep only "the value changed".
    static let reduced = Animation.easeOut(duration: 0.2)
}
```

## 2. Reduce Motion in one place

Use this instead of `.animation(_:value:)` and every animation follows `accessibilityReduceMotion` automatically.
It only swaps the curve, so where the *transform* itself (movement, scale) must go away, turn that off through the value too (see §4 `Materialize`).

```swift
private struct AdaptiveAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? Motion.reduced : animation, value: value)
    }
}

extension View {
    func motion<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(AdaptiveAnimation(animation: animation, value: value))
    }
}
```

## 3. A button that reacts the instant it's pressed

- Press and release use different curves. With the same curve, the press feels sluggish.
- Show press with `brightness`, not `opacity`. A filled pill that turns translucent looks switched off, not pressed.
- Hover says "here" ahead of time on pointer platforms (macOS, iPadOS with a pointer). On touch-only iPhone it simply never fires; harmless.
- `ButtonStyle` can't hold `@State`, so hover needs one wrapper view.

```swift
struct PressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.95

    func makeBody(configuration: Configuration) -> some View {
        StyleBody(configuration: configuration, pressedScale: pressedScale)
    }

    // Naming this `Body` collides with ButtonStyle's associated type and fails to compile.
    private struct StyleBody: View {
        let configuration: ButtonStyleConfiguration
        let pressedScale: CGFloat
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .brightness(configuration.isPressed ? -0.07 : (isHovering ? 0.08 : 0))
                .scaleEffect(configuration.isPressed ? pressedScale : 1)
                .animation(
                    configuration.isPressed ? Motion.pressDown : Motion.pressRelease,
                    value: configuration.isPressed
                )
                .animation(.easeOut(duration: 0.15), value: isHovering)
                .onHover { isHovering = $0 }
        }
    }
}
```

## 4. A material that arrives

A plain fade reads as "switched on". Moving blur, scale, offset and opacity together from **the origin (anchor)**
reads as "the material arrived".

Careful: (a) blur costs every frame — keep it small and short, not large and lingering. (b) SwiftUI's `.blur` doesn't apply to materials drawn by
AppKit/UIKit (`NSVisualEffectView`, `NSGlassEffectView`, `UIVisualEffectView`), so apply it *to content only*.
(c) Under Reduce Motion, drop every transform and keep opacity only.

```swift
struct Materialize: ViewModifier {
    let isPresented: Bool
    var anchor: UnitPoint = .top
    var blur: CGFloat = 8
    var scale: CGFloat = 0.92
    var offsetY: CGFloat = -6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let settled = isPresented || reduceMotion
        content
            .blur(radius: settled ? 0 : blur)
            .scaleEffect(settled ? 1 : scale, anchor: anchor)
            .offset(y: settled ? 0 : offsetY)
            .opacity(isPresented ? 1 : 0)
            // Entrance and exit need different curves (P2). With the same curve the exit also blurs and smears for 0.3s
            // and looks like fog lifting — a defect seen in an actual simulator recording.
            .animation(reduceMotion ? Motion.reduced : (isPresented ? Motion.present : Motion.exit), value: isPresented)
    }
}
```

## 5. Different entrance and exit

How content comes and goes while its container (a notch, sheet, card) changes size.
- **Entering**: the container opens first, then the content settles in a little later (`delay`).
- **Leaving**: clear the content *faster* than the container. If the container folds with content still inside, an empty shell closes slowly or text gets clipped by the corners.

```swift
extension AnyTransition {
    static var contentDrop: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: -10))
                .animation(.spring(response: 0.42, dampingFraction: 0.84).delay(0.08)),
            removal: .opacity.combined(with: .offset(y: -6))
                .animation(Motion.exit)
        )
    }
}
```

Things that should **fold back into where they came from**, like list items, use the same path both ways:
`.transition(reduceMotion ? .opacity : .scale(scale: 0.82).combined(with: .opacity))`.
For the `.transition` to actually run, you often need `.animation(_, value:)` on the *observing* side rather than where the value is set
(when the value changes outside `withAnimation`, e.g. in a timer callback).

## 6. An entrance you can interrupt (state-driven)

`if isOpen { View().transition(...) }` is an insert/remove animation and can't be interrupted. Tap again before it ends and
removals and insertions stack up; add a heavy blur and the main thread stalls.
Keep the view **always mounted** and draw it from `progress` (0→1). A spring retargets from its current value, so it keeps moving no matter how often it's tapped.

Spreading the vertical (exponent 0.6, early) and horizontal (exponent 2.0, late) rates gives the impression of a genie squeezing through a narrow neck.

```swift
struct EmergeFromSource: ViewModifier, Animatable {
    var progress: Double          // 0 = curled up at the origin, 1 = fully out
    let anchor: UnitPoint         // the point it's sucked into
    let startScale: Double        // starting scale ratio (thumbnail / final size)

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: startScale + (1 - startScale) * pow(progress, 2.0),
                y: startScale + (1 - startScale) * pow(progress, 0.6),
                anchor: anchor
            )
            // Early and shallow only. Blurring a large image every frame costs frames, so radius is frame drops.
            .blur(radius: progress < 0.5 ? (0.5 - progress) * 6 : 0)
            // Translucent until the end looks ghostly, so it turns opaque early.
            .opacity(min(1, progress * 2.2))
    }
}

// Usage: drive it by state and apply one spring outside.
// art.modifier(EmergeFromSource(progress: isOpen ? 1 : 0, anchor: .bottomLeading, startScale: 0.3))
//    .motion(Motion.morph, value: isOpen)
```

`progress` changes every frame, so if an outer view observes it directly, the whole card redraws every frame.
Confine observation (`@ObservedObject`) **inside** a modifier like this to narrow what redraws to opacity and size.

## 7. A value that flows (don't swap names)

Swapping image or symbol names per range (`wave.1 → wave.2 → wave.3`) cuts abruptly at each change and flickers when the value sits near a boundary.
Animate one value (`level`) and **compute each segment's brightness from it every frame**, and the segments light up in order.
A separate `opacity` animation per segment won't work — they all light at once.

If the SF Symbol supports variable values, that's cheapest: `Image(systemName: "speaker.wave.3.fill", variableValue: level)`.
For symbols that don't (a sun, say), draw it as below. Use **damping 1.0** here — segments switch as they cross a threshold,
so a bounce flickers back and forth across it.

```swift
struct SegmentMeter: View, Animatable {
    var level: Double             // 0...1
    var count = 8

    nonisolated var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let gap: CGFloat = 3
            let width = (size.width - gap * CGFloat(count - 1)) / CGFloat(count)
            for index in 0..<count {
                // Each time level passes one segment's share (1/count), that segment goes from 0 to 1.
                let lit = min(max(level * Double(count) - Double(index), 0), 1)
                let rect = CGRect(x: CGFloat(index) * (width + gap), y: 0, width: width, height: size.height)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: width / 2),
                    with: .color(.primary.opacity(0.3 + 0.7 * lit))
                )
            }
        }
    }
}

// SegmentMeter(level: volume).motion(Motion.settle, value: volume)
```

## 8. A shrinking ring (time as shape)

- In a countdown the eye looks for what's **left**, not what's gone. A shrinking ring, not a filling one.
- Don't erase the elapsed part completely; leave it faint — otherwise it looks like pieces disappearing rather than shrinking.
- Values updated every second are joined with **linear over 1s**. A spring wobbles every second. When it isn't running (rewind, phase change), use a short ease — filling slowly over a second feels sluggish.

```swift
struct CountdownRing: View {
    let elapsed: Double           // elapsed fraction 0...1
    let isRunning: Bool
    var tint: Color = .orange
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: min(max(elapsed, 0), 1), to: 1)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))      // 12 o'clock is the baseline, like a clock.
        }
        .padding(lineWidth / 2)                       // a stroke spreads to both sides of the path; inset by half so the ink meets the box edge
        .animation(isRunning ? .linear(duration: 1) : .easeOut(duration: 0.25), value: elapsed)
        .accessibilityElement()
        .accessibilityLabel("Time remaining")
        .accessibilityValue("\(Int(((1 - elapsed) * 100).rounded())) percent")
    }
}
```

## 9. A decaying swing

A bell hangs from a loop at the top → the pivot is **the top** (`anchor: .top`), not the center. Rotating around the center
reads as "loading", not "ringing". Amplitude shrinks with each swing — constant amplitude looks like a machine vibrating.
It rings once and **rests** — without rest it's noise, not an alert, and the eye starts ignoring it.
Use `.task` instead of a self-calling `DispatchQueue` — it cancels automatically when the view goes away.

```swift
struct DecayingShake: View {
    var systemName = "bell.fill"
    var tint: Color = .orange

    @State private var angle: Double = 0
    @State private var scale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let swings: [(angle: Double, duration: Double)] = [
        (17, 0.10), (-13, 0.11), (9, 0.11), (-6, 0.12), (3, 0.12), (0, 0.14)
    ]
    private static let restBetweenRings: Double = 1.3

    var body: some View {
        Image(systemName: systemName)
            .foregroundStyle(tint)
            .rotationEffect(.degrees(angle), anchor: .top)
            .scaleEffect(scale)
            .task {
                while !Task.isCancelled {
                    await ringOnce()
                    try? await Task.sleep(nanoseconds: UInt64(Self.restBetweenRings * 1_000_000_000))
                }
            }
    }

    private func ringOnce() async {
        // Reduce Motion: breathe in size instead of rotating. Don't remove the alert — make it not dizzying.
        guard !reduceMotion else {
            withAnimation(.easeInOut(duration: 0.4)) { scale = 1.1 }
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.4)) { scale = 1 }
            try? await Task.sleep(nanoseconds: 400_000_000)
            return
        }

        // A slight swell at the strike. It must finish before the swing so "struck" and "swinging" don't overlap.
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { scale = 1.18 }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { scale = 1 }
        }

        for swing in Self.swings {
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: swing.duration)) { angle = swing.angle }
            try? await Task.sleep(nanoseconds: UInt64(swing.duration * 1_000_000_000))
        }
    }
}
```

## 10. Number and symbol transitions

- Numbers: `.numericText` rolls the digits. Match `countsDown` to the real direction. Without `.monospacedDigit()`, it jitters sideways between one and two digits.
- Titles and names: `.opacity`. Sliding them makes text in a narrow column slide sideways and look clipped.
- An icon that flips state (play ↔ pause): `.symbolEffect(.replace)` in place. Even when the name changes, the body stays and only what differs is swapped.
- One-off emphasis like "it landed": `.symbolEffect(.bounce.down, value: count)`. Under Reduce Motion, pin `value` to `0` to turn it off.

```swift
extension ContentTransition {
    /// Magic replace on iOS 18 / macOS 15 when available, plain replace otherwise.
    static var symbolReplace: ContentTransition {
        if #available(iOS 18, macOS 15, *) {
            .symbolEffect(.replace.magic(fallback: .replace))
        } else {
            .symbolEffect(.replace)
        }
    }
}

struct TransitionsExample: View {
    var seconds: Int
    var isPlaying: Bool
    var enterCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            Text("\(seconds)")
                .monospacedDigit()
                .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: true))
                .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: seconds)

            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .contentTransition(reduceMotion ? .opacity : .symbolReplace)
                .motion(Motion.settle, value: isPlaying)

            Image(systemName: "tray.and.arrow.down")
                .symbolEffect(.bounce.down, value: reduceMotion ? 0 : enterCount)
        }
    }
}
```

## 11. A drag that carries the hand's velocity

There must be no seam between drag and animation for it to feel "stuck to the finger". In order:

1. **On grab**: start from the value *visible on screen*, not the target. Otherwise grabbing mid-spring teleports it.
   SwiftUI's `@State` only holds the target, so record the drawn value separately (inside an `Animatable`).
2. **While dragging**: apply immediately with `Transaction(animation: nil)` → 1:1 with the finger.
3. **Past the bounds**: rubber-band. It follows less the further it goes.
4. **On release**: don't trust `DragGesture`'s velocity; compute it yourself from **the last 0.1s of movement**.
   `value.velocity` keeps the last movement speed even after the finger stops, so pausing mid-drag and releasing later still flings.
5. **Project the resting point**: `current + (v/1000)·d/(1−d)` (the same exponential decay as scroll deceleration, not a textbook `v²/2a`) → nearest target.
6. **Hand the initial velocity to the spring**: `.spring()` has no such parameter, so use `interpolatingSpring(initialVelocity:)`.
   The value is **velocity relative to the remaining distance** (`v / (target − current)`).
7. **Overshoot slightly only when flung** (damping ~0.82). A gentle release that overshoots and comes back reads as wobble.

```swift
enum Physics {
    /// Where it would stop if it kept sliding at this velocity (the same exponential decay as scroll deceleration).
    static func project(velocity: Double, deceleration: Double = 0.99) -> Double {
        velocity / 1000 * deceleration / (1 - deceleration)
    }

    /// Proportional to the overshoot but following less and less. The asymptote is dimension × constant.
    static func rubberBand(_ overshoot: Double, dimension: Double, constant: Double = 0.55) -> Double {
        guard overshoot > 0 else { return 0 }
        return (overshoot * dimension * constant) / (dimension + constant * overshoot)
    }

    /// A spring from response (s) and damping ratio. This is the only form that accepts an initial velocity.
    static func spring(response: Double, damping: Double, velocity: Double) -> Animation {
        let stiffness = pow(2 * Double.pi / response, 2)
        return .interpolatingSpring(
            mass: 1,
            stiffness: stiffness,
            damping: 2 * damping * stiffness.squareRoot(),
            initialVelocity: velocity
        )
    }
}

/// Finger velocity (pt/s) over the last 0.1s before release. Older movement belongs to a hand that already stopped.
final class VelocityTracker {
    private var samples: [(time: TimeInterval, x: Double)] = []

    func reset() { samples.removeAll(keepingCapacity: true) }

    func record(x: Double, at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        samples.append((time, x))
        if samples.count > 8 { samples.removeFirst(samples.count - 8) }
    }

    func releaseVelocity(at now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Double {
        let recent = samples.filter { now - $0.time <= 0.1 }
        guard let first = recent.first, let last = recent.last, last.time - first.time > 0.001 else { return 0 }
        return (last.x - first.x) / (last.time - first.time)
    }
}

/// The value actually drawn on screen. `@State` only holds the target, so read the in-flight position here.
/// It's a reference, not state, so writing it every frame doesn't trigger a redraw.
final class PresentedValue {
    var value: Double = 0
}

/// Draws a horizontal offset and records each animated frame's value into `PresentedValue`.
struct PresentedOffset: ViewModifier, Animatable {
    var x: Double
    let presented: PresentedValue

    nonisolated var animatableData: Double {
        get { x }
        set { x = newValue }
    }

    func body(content: Content) -> some View {
        presented.value = x
        return content.offset(x: x)
    }
}

/// A card dragged horizontally that settles into one of several slots.
struct SnapDragExample: View {
    let snapPoints: [Double] = [0, 120, 240]
    @State private var x: Double = 0
    @State private var origin: Double?
    @State private var tracker = VelocityTracker()
    @State private var presented = PresentedValue()

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.tint)
            .frame(width: 80, height: 80)
            .modifier(PresentedOffset(x: x, presented: presented))
            .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if origin == nil {
                    // The value visible at the moment of grab. Starting from the target (x) teleports it mid-spring.
                    origin = presented.value
                    tracker.reset()
                }
                tracker.record(x: Double(value.translation.width))
                let raw = (origin ?? x) + Double(value.translation.width)
                // 1:1 with no animation. A running spring stops here and the drag continues from where it was visible.
                withTransaction(Transaction(animation: nil)) { x = resisted(raw) }
            }
            .onEnded { _ in
                origin = nil
                let velocity = tracker.releaseVelocity()
                let projected = x + Physics.project(velocity: velocity)
                guard let target = snapPoints.min(by: { abs($0 - projected) < abs($1 - projected) }) else { return }

                let distance = target - x
                let relative = abs(distance) < 0.5 ? 0 : min(max(velocity / distance, -10), 10)
                let isFlick = abs(velocity) > 100
                withAnimation(Physics.spring(response: 0.42, damping: isFlick ? 0.82 : 1.0, velocity: relative)) {
                    x = target
                }
            }
    }

    private func resisted(_ raw: Double) -> Double {
        guard let lower = snapPoints.min(), let upper = snapPoints.max() else { return raw }
        let dimension = 300.0
        if raw < lower { return lower - Physics.rubberBand(lower - raw, dimension: dimension) }
        if raw > upper { return upper + Physics.rubberBand(raw - upper, dimension: dimension) }
        return raw
    }
}
```

## 12. Page depth (system paging + scrollTransition)

Don't build horizontal paging with `DragGesture`. In particular, **macOS swipes are two-finger trackpad *scroll events* and
never reach `DragGesture`.** System paging already picks the next page from release velocity (momentum projection), rubber-bands at the ends,
and lets you grab a page mid-flight and reverse it.

Don't add a manual "arrival spring" on top. The moment it starts (right after `selection` changes) and the moment native deceleration actually stops
don't line up, so a fast flick shows two motions on two beats — that's what "the animation feels cheap" turns out to be.
**Keep one and trust it.** Compute depth directly from scroll position with `scrollTransition(.interactive)`.

```swift
struct PageDepth: ViewModifier {
    let reduceMotion: Bool
    let pageWidth: CGFloat

    /// How much of the scroll movement stays on screen. Closer to 1 sticks closer to the finger.
    private static let travel: CGFloat = 0.55
    /// Fully gone at this distance (relative to page width).
    private static let fadeDistance: CGFloat = 0.46
    private static let maxBlur: CGFloat = 7

    func body(content: Content) -> some View {
        // The scrollTransition closure is Sendable and can't read MainActor statics directly; copy them to locals first.
        let fadeDistance = Self.fadeDistance
        let travelRatio = reduceMotion ? 0 : Self.travel
        let maxBlur = reduceMotion ? 0 : Self.maxBlur
        let reduceMotion = reduceMotion
        let pageWidth = pageWidth

        return content.scrollTransition(.interactive, axis: .horizontal) { view, phase in
            let distance = min(abs(phase.value), 1)
            let t = min(distance / fadeDistance, 1)
            // ease-out: fades fast early and gently at the end — always fainter than linear at the same distance.
            let fade = 1 - (1 - t) * (1 - t)
            let blur = maxBlur * fade

            return view
                .offset(x: -phase.value * pageWidth * (1 - travelRatio))
                .opacity(1 - fade)
                .blur(radius: blur)
                .scaleEffect(reduceMotion ? 1 : 1 - 0.1 * distance)
        }
    }
}

struct PagedDeck<Item: Identifiable, Content: View>: View where Item.ID: Hashable {
    let items: [Item]
    @Binding var selection: Item.ID?
    @ViewBuilder let content: (Item) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(items) { item in
                        content(item)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .modifier(PageDepth(reduceMotion: reduceMotion, pageWidth: geo.size.width))
                            // Offsetting the travel leaves neighbor pages standing on top of the current one.
                            // They're invisible but still clickable, so only the page being viewed accepts hits.
                            .allowsHitTesting(selection == nil || selection == item.id)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selection)
            // If the scroll view clips content to its bounds, the leftover travel gets chopped at the edges.
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
        }
    }
}
```

## 13. Haptics per platform

Haptics are part of motion — they fire in **the same frame** as the visible change, and only at **meaningful moments**.
Fire when crossing a detent; not on grab or release. Larger units (like 5-minute detents) one step stronger.

On macOS, `.sensoryFeedback` compiles but most patterns **pass silently**. `NSHapticFeedbackManager` is what actually reaches
a Force Touch trackpad. Most iPads have no haptic engine, so never make haptics the only feedback — the visual comes first.

```swift
enum Haptics {
    enum Kind { case tick, detent, confirm }

    @MainActor
    static func play(_ kind: Kind) {
        #if os(macOS)
        let pattern: NSHapticFeedbackManager.FeedbackPattern = switch kind {
        case .tick: .alignment
        case .detent: .levelChange
        case .confirm: .generic
        }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
        #elseif canImport(UIKit)
        switch kind {
        case .tick: UISelectionFeedbackGenerator().selectionChanged()
        case .detent: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .confirm: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}
```

The declarative iOS 17+ path is `.sensoryFeedback(trigger: detent) { _, new in new % 5 == 0 ? .levelChange : .alignment }`.
To reach macOS users too, don't rely on it alone — also call `Haptics.play` above from `onChange`.

## 14. Liquid Glass morphing (Apple API)

Don't hand-build Liquid Glass elements merging and splitting. Inside one `GlassEffectContainer`, give `glassEffectID(_:in:)`
a shared namespace and change state inside `withAnimation`; the system morphs them (WWDC25).
- Glass can't sample other glass, so glass placed close together must share a container.
- `.interactive()` lets the system handle scale, bounce and shimmer on press (presented as an iOS feature — on macOS only the typecheck was confirmed, not the visual).
- The curve is `Motion.morph` (snappy) — a glass morph is a shape change the user caused.

```swift
@available(iOS 26.0, macOS 26.0, *)
struct GlassMorphMenu: View {
    @Namespace private var glass
    @State private var isExpanded = false

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 20) {
                Button {
                    withAnimation(Motion.morph) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus").frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive())
                .glassEffectID("toggle", in: glass)

                if isExpanded {
                    ForEach(["photo", "camera", "doc"], id: \.self) { name in
                        Image(systemName: name)
                            .frame(width: 44, height: 44)
                            .glassEffect()
                            .glassEffectID(name, in: glass)
                    }
                }
            }
        }
    }
}
```

## 15. SF Symbols effects at a glance

Before spinning an icon with `rotationEffect`, look for a symbol effect. Some run once when a value (`value:`) changes;
others stay on with `isActive:`. Under Reduce Motion, pin the trigger or turn `isActive` off.

| Effect | Use | Driven by |
| --- | --- | --- |
| `.bounce` | a "pop" — arrival, completion (`.bounce.down`: landing) | `value:` |
| `.pulse` | in progress, waiting | `isActive:` |
| `.variableColor.iterative` | signal, loading lighting up in sequence | `isActive:` |
| `.wiggle` · `.breathe` · `.rotate` | iOS 18 / macOS 15+ | `value:` / `isActive:` |
| `.replace` | an icon flipping state | `contentTransition` (§10) |

```swift
struct SymbolEffectsTour: View {
    var count: Int
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 24) {
            Image(systemName: "bell.fill").symbolEffect(.bounce, value: reduceMotion ? 0 : count)
            Image(systemName: "wifi").symbolEffect(.variableColor.iterative, isActive: isActive && !reduceMotion)
            Image(systemName: "heart.fill").symbolEffect(.pulse, isActive: isActive && !reduceMotion)
            if #available(iOS 18, macOS 15, *) {
                Image(systemName: "bell.fill").symbolEffect(.wiggle, value: reduceMotion ? 0 : count)
                Image(systemName: "heart.fill").symbolEffect(.breathe, isActive: isActive && !reduceMotion)
                Image(systemName: "arrow.2.circlepath").symbolEffect(.rotate, isActive: isActive && !reduceMotion)
            }
        }
    }
}
```

## 16. A keyframe "pop"

Emphasis that grows once and returns (a like, "added"). `KeyframeAnimator` restarts from the beginning whenever `trigger` changes.
Grow short and fast (snappy), return without bounce (smooth).

```swift
struct Pop: ViewModifier {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        // The keyframeAnimator closure is Sendable and can't read environment values directly; copy to a local first.
        let reduce = reduceMotion
        return content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(reduce ? 1 : scale)
        } keyframes: { _ in
            KeyframeTrack {
                SpringKeyframe(1.18, duration: 0.14, spring: .snappy)
                SpringKeyframe(1.0, spring: .smooth(duration: 0.3))
            }
        }
    }
}

extension View {
    func pop(on trigger: Int) -> some View { modifier(Pop(trigger: trigger)) }
}
```

## 17. Knowing when it finished + blur replace

A spring has an exponentially decaying tail, so waiting for it to "fully stop" never ends. Apple says to use the moment the perceived duration (`duration`) ends —
`completionCriteria: .logicallyComplete`. Use this instead of guessing time with a timer (`asyncAfter`).
For the moment content changes, `.transition(.blurReplace)` handles blur and opacity together.

```swift
struct CompletionExample: View {
    @State private var isShown = false
    @State private var label = "A"

    var body: some View {
        VStack(spacing: 12) {
            if isShown {
                Text(label).transition(.blurReplace)
            }
            Button("Show") {
                withAnimation(Motion.present, completionCriteria: .logicallyComplete) {
                    isShown = true
                } completion: {
                    label = "done"
                }
            }
        }
    }
}
```

## 18. A Dynamic Island–style shape change

A small pill that suddenly grows and shrinks comes down to three things.
1. **The whole shape moves on one spring** — width, height and corners share `Motion.morph`. Separately, the shape warps.
2. **Outgoing content clears before the container** (`Motion.exit`); incoming content settles in after the container opens (`contentDrop`).
3. The corner goes between **half the height (a capsule) and a smaller value**. Clip with the same value so content never crosses the corner.

Apple hasn't published the exact curve the Dynamic Island uses. This composition is a close reproduction,
and the sizes (defaults below) are examples — fit the real size to the device and content.

```swift
struct IslandMorph<Compact: View, Expanded: View>: View {
    @Binding var isExpanded: Bool
    var compactSize = CGSize(width: 126, height: 37)
    var expandedSize = CGSize(width: 340, height: 160)
    var expandedCornerRadius: CGFloat = 44
    @ViewBuilder var compact: () -> Compact
    @ViewBuilder var expanded: () -> Expanded

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let size = isExpanded ? expandedSize : compactSize
        let radius = isExpanded ? expandedCornerRadius : size.height / 2
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ZStack {
            if isExpanded {
                expanded().transition(reduceMotion ? .opacity : .contentDrop)
            } else {
                compact().transition(.opacity.animation(Motion.exit))
            }
        }
        .frame(width: size.width, height: size.height)
        .background(.black, in: shape)
        .clipShape(shape)
        .animation(reduceMotion ? Motion.reduced : Motion.morph, value: isExpanded)
    }
}
```

## 19. Comet-stroke glow · rotating border

The ingredients behind the Apple Intelligence / Siri light and the handwritten "hello".
- **Comet stroke**: cut the path with `trim` so the head (`progress`) leads and the tail follows by `tail`. At the end the tail catches the head and the stroke disappears.
  `from = max(0, progress − tail, 2·progress − 1)` — three phases (grow / travel / vanish) in one expression; with `tail = 1` it draws and then erases, like handwriting.
- **Glow**: stack the same stroke three times with different widths and blur (a sharp core + two spreading layers of light).
- **Rotating border**: rotate an `AngularGradient` larger than the shape, linearly, and mask it to the border. Endless rotation stops under Reduce Motion.
  (HIG warns against sustained oscillation and rotation.)
- The key is animating one progress value (`progress`) as `Animatable` — never animate the stroke's pieces separately.

```swift
extension Shape {
    /// Stacks the same stroke three times so the light spreads.
    func glow(fill: some ShapeStyle, lineWidth: Double, blurRadius: Double = 8, lineCap: CGLineCap = .round) -> some View {
        self
            .stroke(style: StrokeStyle(lineWidth: lineWidth / 2, lineCap: lineCap))
            .fill(fill)
            .overlay {
                self.stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
                    .fill(fill)
                    .blur(radius: blurRadius)
            }
            .overlay {
                self.stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: lineCap))
                    .fill(fill)
                    .blur(radius: blurRadius / 2)
            }
    }
}

struct CometStroke<Content: Shape, Fill: ShapeStyle>: View, Animatable {
    var progress: Double          // 0...1, where the head is
    var tail: Double = 0.35       // tail length (relative to the path). 1 = handwriting
    var fill: Fill
    var lineWidth: Double = 4
    var blurRadius: Double = 6
    @ViewBuilder var shape: Content

    nonisolated var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        shape
            .trim(from: max(0, progress - tail, 2 * progress - 1), to: progress)
            .glow(fill: fill, lineWidth: lineWidth, blurRadius: blurRadius)
    }
}

struct RotatingGlowBorder<S: InsettableShape>: View {
    let shape: S
    var colors: [Color] = [.purple, .orange, .pink, .cyan, .purple]
    var lineWidth: CGFloat = 4
    var period: Double = 4

    @State private var rotation = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            // Rotate a square as wide as the diagonal so the corners never go empty.
            let side = hypot(geo.size.width, geo.size.height)
            AngularGradient(colors: colors, center: .center)
                .frame(width: side, height: side)
                .rotationEffect(.degrees(rotation))
                .frame(width: geo.size.width, height: geo.size.height)
                .mask { shape.strokeBorder(lineWidth: lineWidth) }
        }
        .task(id: reduceMotion) {
            if reduceMotion {
                withTransaction(Transaction(animation: nil)) { rotation = 0 }
            } else {
                withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) { rotation = 360 }
            }
        }
    }
}

// Usage: CometStroke(progress: p, tail: 1, fill: .white, lineWidth: 6, blurRadius: 0) { MyPathShape() }
//        .onAppear { withAnimation(.easeInOut(duration: 4)) { p = 1 } }
```

## 20. A living mesh

To make a mesh gradient breathe: move its control points and colors separately with `repeatForever(autoreverses: true)` at **different periods**.
When the periods aren't multiples of each other, the pattern rarely repeats and looks organic (1.5s, 1.8s, 2.2s).
Under Reduce Motion, leave a still mesh.

```swift
@available(iOS 18.0, macOS 15.0, *)
struct LivingMesh: View {
    @State private var a = false
    @State private var b = false
    @State private var c = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [b ? 0.5 : 0.8, 0], [1, 0],
                [0, 0.5], a ? [0.3, 0.4] : [0.7, 0.6], [1, c ? 0.4 : 0.6],
                [0, 1], [b ? 0.4 : 0.7, 1], [1, 1]
            ],
            colors: [
                b ? .purple : .cyan, a ? .blue : .mint, c ? .orange : .yellow,
                a ? .blue : .red, a ? .white : .cyan, a ? .purple : .red,
                a ? .cyan : .red, c ? .mint : .purple, b ? .blue : .red
            ]
        )
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { a.toggle() }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { b.toggle() }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { c.toggle() }
        }
    }
}
```

## 21. Zoom transition (iOS 18)

A cell growing into a full screen, like an app opening. Put `matchedTransitionSource` on the source and `.navigationTransition(.zoom)` on the destination
with a shared namespace. The system even hands off velocity while you drag it closed (WWDC24) — don't build it yourself.

```swift
#if os(iOS)
@available(iOS 18.0, *)
struct ZoomTransitionExample: View {
    @Namespace private var zoom
    private let items = Array(1...6)

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(items, id: \.self) { item in
                    NavigationLink(value: item) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.tint)
                            .frame(height: 100)
                    }
                    .matchedTransitionSource(id: item, in: zoom)
                }
            }
            .padding()
            .navigationDestination(for: Int.self) { item in
                Text("Detail \(item)")
                    .navigationTransition(.zoom(sourceID: item, in: zoom))
            }
        }
    }
}
#endif
```

## 22. Control and bezel specs, minimum hit area

Apple specifies default and minimum control sizes, and the spacing around controls with and without a visible background (**bezel**) [HIG Accessibility].
Even when the visible icon is small, the **pressable area** must meet the spec — so use `contentShape` together with a minimum frame.
Don't hard-code text sizes; use **semantic styles** like `.font(.body)` — SwiftUI gives each platform its size (iOS body 17, macOS body 13) and scales with Dynamic Type
(size table in [metrics.md](metrics.md)). Scale text-bound dimensions with `@ScaledMetric`.

```swift
enum AppleMetrics {
    /// Default and minimum size of a control (button etc.). HIG values; they differ per platform.
    enum HitTarget {
        #if os(macOS)
        static let `default`: CGFloat = 28
        static let minimum: CGFloat = 20
        #else
        static let `default`: CGFloat = 44
        static let minimum: CGFloat = 28
        #endif
    }

    /// Space around a control with a bezel (visible background/border) ≈ 12pt; around a bezel-less one, from its visible edge ≈ 24pt.
    static let paddingAroundBezeled: CGFloat = 12
    static let paddingAroundBezelless: CGFloat = 24

    /// Concentric corners: inner radius = outer radius − the inset between them, so the gap stays even around the corner.
    static func concentricRadius(outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(outer - inset, 0)
    }
}

extension View {
    /// Makes the pressable area at least the spec size regardless of the visible size.
    func appleHitTarget(_ size: CGFloat = AppleMetrics.HitTarget.default) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
}
```

## 23. Concentric corners

Nested rounded shapes (a card inside a card, a panel inside the screen corner) **look misaligned when their radii are equal.** Shrinking the inner radius to `outer − inset` keeps the gap even around the corner.
On iOS 26 / macOS 26, `ConcentricRectangle` reads the `containerShape` and computes the radius for you. There's no public API for the exact screen (device) corner radius,
so never hard-code it — leave it to `ContainerRelativeShape` / `ConcentricRectangle`. Corners are always `style: .continuous`.

```swift
struct ConcentricCardExample: View {
    var outerRadius: CGFloat = 36
    var inset: CGFloat = 12

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous).fill(.black)
            RoundedRectangle(
                cornerRadius: AppleMetrics.concentricRadius(outer: outerRadius, inset: inset),
                style: .continuous
            )
            .fill(.gray.opacity(0.3))
            .padding(inset)
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
struct ConcentricAutoExample: View {
    var body: some View {
        ConcentricRectangle()
            .fill(.gray.opacity(0.3))
            .padding(12)
            .containerShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
    }
}
```

## 24. Pointer effects (iPadOS · macOS)

On pointer platforms, say "here" **before the click**. iPadOS provides three system effects [HIG Pointing devices]:
- **highlight** — small elements on a transparent background (bar buttons, tabs, segments). The pointer becomes a rounded-rectangle background.
- **lift** — small elements on an opaque background (app icons, Control Center buttons). They rise slightly with a shadow and specular highlight.
- **hover** — large elements. The pointer keeps its shape; only tint, scale and shadow change. **Don't scale elements that touch their neighbors** (table rows) — they collide.

Highlight and lift **morph the pointer into the element**, so give them the corner radius for a seamless change (`contentShape(.hoverEffect, ...)`).
Make the hit areas of buttons in a bar **contiguous** — a gap makes the pointer flicker back to its default shape.
macOS has no such effects, so use hover brightness (`+0.08`, P12) and a faint background instead. When the cursor shape carries meaning (a link, dragging),
use system cursors such as `.pointerStyle(.link)` on macOS 15+; never draw your own.

```swift
enum PointerEffectKind { case highlight, lift, hover }

extension View {
    /// How it responds when the pointer arrives. System pointer effects on iPadOS, hover brightness on macOS.
    func applePointerEffect(_ kind: PointerEffectKind, cornerRadius: CGFloat = 12) -> some View {
        modifier(ApplePointerEffect(kind: kind, cornerRadius: cornerRadius))
    }
}

struct ApplePointerEffect: ViewModifier {
    let kind: PointerEffectKind
    let cornerRadius: CGFloat
    @State private var isHovering = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        #if os(iOS)
        switch kind {
        case .highlight:
            content.contentShape(.hoverEffect, shape).hoverEffect(.highlight)
        case .lift:
            content.contentShape(.hoverEffect, shape).hoverEffect(.lift)
        case .hover:
            // Large element: the pointer keeps its shape; tint only. Don't scale it (it would collide with neighbors).
            content
                .background(shape.fill(.primary.opacity(isHovering ? 0.06 : 0)))
                .onHover { hovering in withAnimation(Motion.settle) { isHovering = hovering } }
        }
        #else
        content
            .brightness(isHovering ? 0.08 : 0)
            .background(shape.fill(.primary.opacity(isHovering && kind != .lift ? 0.06 : 0)))
            .onHover { hovering in withAnimation(Motion.settle) { isHovering = hovering } }
        #endif
    }
}
```

## 25. Haptics chosen by meaning

The HIG says to use system haptics **only for their documented meanings** — playing the success haptic on a failure breaks a connection people have learned [HIG Playing haptics].
So choose by "what happened", not "which vibration". `Haptics.play(_:)` from §13 stays; this adds meaning names.

| Meaning | iOS | macOS (Force Touch trackpad) |
| --- | --- | --- |
| `selection` a value moved one step (picker, detent) | `UISelectionFeedbackGenerator` | `.alignment` |
| `snap` clicked into place | `UIImpactFeedbackGenerator(.light)` | `.alignment` |
| `boundary` reached start, end, min or max | `UIImpactFeedbackGenerator(.rigid)` | `.alignment` |
| `success` · `warning` · `failure` outcome of a task | `UINotificationFeedbackGenerator` | **none** — show it visually |

Per the HIG, macOS haptics are signals **during a drag or a force click** (alignment, pressure level, generic). There's no pattern for task outcomes,
so show the outcome on screen. Every haptic must be **optional**, and the app must work fully without them.

```swift
enum HapticMeaning {
    case selection, snap, boundary, success, warning, failure
}

extension Haptics {
    @MainActor
    static func play(meaning: HapticMeaning) {
        #if os(macOS)
        // macOS haptics signal drags and force clicks. There's no pattern for task outcomes (success etc.), so play nothing.
        let pattern: NSHapticFeedbackManager.FeedbackPattern? = switch meaning {
        case .selection, .snap, .boundary: .alignment
        case .success, .warning, .failure: nil
        }
        if let pattern { NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now) }
        #elseif canImport(UIKit)
        switch meaning {
        case .selection: UISelectionFeedbackGenerator().selectionChanged()
        case .snap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .boundary: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .failure: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
```

## 26. System sheets — configure, don't build

Dragging a sheet up and down (velocity handoff, snapping to detents, rubber-banding, swipe-to-dismiss) is already done by the system — don't use §11 for sheets (P8).
The job is to **configure** it per HIG [HIG Sheets]:
- On iPhone, show it at the **medium detent** first and let it grow (progressive disclosure). If it's resizable, show the **grabber** — it also works with VoiceOver.
- **Support swipe-to-dismiss.** Block it only when there are unsaved changes (`interactiveDismissDisabled`), and confirm when people try to close.
- One sheet at a time — closing a sheet only to land on another one loses people.
- iPad uses page / form sheets (default size, dimmed background). macOS sheets usually don't resize, so give them **a default size that fits the content**.
  For repeated input while watching the result, use a panel (macOS) or a non-modal sheet (`presentationBackgroundInteraction`) instead.

```swift
struct SystemSheetExample: View {
    @State private var isPresented = false
    @State private var hasChanges = false
    @State private var detent: PresentationDetent = .medium

    var body: some View {
        Button("Edit") { isPresented = true }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    Form { Toggle("Has changes", isOn: $hasChanges) }
                        .navigationTitle("Edit")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { isPresented = false } }
                            ToolbarItem(placement: .confirmationAction) { Button("Done") { isPresented = false } }
                        }
                }
                .presentationDetents([.medium, .large], selection: $detent)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(hasChanges)
                #if os(macOS)
                .frame(minWidth: 360, minHeight: 240)
                #endif
            }
    }
}
```

## 27. Layout that flows with space

HIG: decide layout by **the space actually available** (size class, window size) and **text size**, not device type or orientation [HIG Layout].
iPad windows resize freely, and iPhone apps grow and shrink in iPhone Mirroring on the Mac. At large text sizes, side-by-side views must stack vertically so text isn't clipped.

This is where motion comes in: swapping `HStack` and `VStack` with `if` **rebuilds** the views and the layout snaps (the same problem as P5).
`AnyLayout` changes only the arrangement while keeping view identity, so **positions flow** on one spring.
macOS has no size class — when you need the window width, decide with `ViewThatFits` or `GeometryReader`.

```swift
struct AdaptiveRow<Leading: View, Trailing: View>: View {
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing
    @Environment(\.dynamicTypeSize) private var typeSize
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    private var stacksVertically: Bool {
        #if os(iOS)
        typeSize.isAccessibilitySize || sizeClass == .compact && typeSize >= .xxLarge
        #else
        typeSize.isAccessibilitySize
        #endif
    }

    var body: some View {
        // Don't swap HStack/VStack with `if` — AnyLayout keeps identity so positions flow.
        let layout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        layout {
            leading
            trailing
        }
        .motion(Motion.settle, value: stacksVertically)
    }
}
```

## 28. Layering Liquid Glass (iOS 26 / macOS 26)

The layer rules [HIG Materials · Layout · Scroll views]:
- **Liquid Glass belongs on the functional layer** (toolbars, tab bars, sidebars, floating controls). The content layer (backgrounds, cards) uses standard materials (`.regularMaterial` etc.).
  The exception is controls that turn to glass **only while touched**, like sliders and toggles.
- Use it **sparingly** on custom controls — only the most important functional elements.
- Don't lay solid or translucent backgrounds under a toolbar. Let content flow beneath the glass and lift controls with a **scroll edge effect** (one per view).
- **Clear glass only over photos and video**, with a 35% black dimming layer over bright content.
- A full-bleed background image extends under sidebars and toolbars — `backgroundExtensionEffect()` mirrors and blurs it to fill the covered parts.

```swift
@available(iOS 26.0, macOS 26.0, *)
struct GlassLayeringExample: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Image(systemName: "photo")
                        .resizable().scaledToFill()
                        .frame(height: 280).clipped()
                        .backgroundExtensionEffect()
                        .overlay(alignment: .bottomTrailing) {
                            // A floating control over a photo: clear glass + a 35% dim for contrast on bright content.
                            Button("Play", systemImage: "play.fill") {}
                                .labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.35), in: Circle())
                                .glassEffect(.clear.interactive(), in: Circle())
                                .padding(12)
                        }
                    ForEach(0..<30, id: \.self) { i in
                        Text("Row \(i)").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).padding(.horizontal)
                    }
                }
            }
            .scrollEdgeEffectStyle(.soft, for: .top)   // instead of a toolbar background
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {}.buttonStyle(.glassProminent)
                }
            }
        }
    }
}
```

## 29. Reject shake — saying "no"

When **input is rejected** — a wrong password, a place you can't drop, a locked item — no response at all reads as a frozen app [HIG Gestures].
Shake side to side **once**, dying down — don't repeat it like the bell in §9. Keep the amplitude small (starting at 10pt and shrinking), all within 0.35s.
`keyframeAnimator` restarts whenever the trigger changes, and continues smoothly if it changes again mid-shake.
Don't shake under Reduce Motion — keep a static cue such as a border or text color alongside (this modifier only turns the movement off). On iOS, play `Haptics.play(meaning: .failure)` at the same moment.
The shake curve is an approximation [Approx.] — Apple's curve hasn't been measured.

```swift
extension View {
    /// Rejected input: one side-to-side shake that dies down, every time the trigger changes.
    func rejectShake<T: Equatable & Sendable>(trigger: T) -> some View {
        modifier(RejectShake(trigger: trigger))
    }
}

struct RejectShake<T: Equatable & Sendable>: ViewModifier {
    let trigger: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let amplitude = reduceMotion ? 0.0 : 1.0   // read outside the closure (Swift 6 isolation)
        return content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, x in
            view.offset(x: x * amplitude)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(10, duration: 0.05)
                CubicKeyframe(-8, duration: 0.06)
                CubicKeyframe(6, duration: 0.06)
                CubicKeyframe(-3, duration: 0.07)
                CubicKeyframe(0, duration: 0.08)
            }
        }
    }
}
```
