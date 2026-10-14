//
//  AppleMotion.swift
//
//  Apple-style motion toolkit (iOS 17 / iPadOS 17 / macOS 14 and later).
//  Generated from the like-apple skill's references/recipes.md — edit the recipes, then regenerate.
//
//  A verification bundle: bring only the recipes you need into a project. Contents:
//    Motion            motion vocabulary (settle / present / morph / lift / pressDown / pressRelease / exit / swap / reduced)
//    .motion(_:value:) .animation that follows Reduce Motion automatically
//    PressableStyle    a button that reacts the instant it's pressed
//    Materialize       a material that arrives
//    .contentDrop      different entrance and exit
//    EmergeFromSource  an interruptible entrance (genie)
//    SegmentMeter · CountdownRing · DecayingShake · TransitionsExample
//    Physics · VelocityTracker · PresentedOffset · SnapDragExample   a drag that carries the hand's velocity
//    PagedDeck · Haptics · GlassMorphMenu · SymbolEffectsTour · Pop · IslandMorph
//    CometStroke · RotatingGlowBorder · LivingMesh · ZoomTransitionExample
//    AppleMetrics · .appleHitTarget() · ConcentricCardExample   control/bezel specs, minimum hit area, concentric corners
//    .applePointerEffect · Haptics.play(meaning:) · SystemSheetExample · AdaptiveRow · GlassLayeringExample · .rejectShake   platform behavior
//
//  If a name is already taken in your project (e.g. Motion, Haptics), rename it with a prefix.
//

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
