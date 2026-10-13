//
//  AppleMotion.swift
//
//  Apple식 애니메이션 도구 모음 (iOS 17 / iPadOS 17 / macOS 14 이상).
//  macOS 노치 앱 Live Peninsula를 개발하며 다듬은 모션·크기 규칙을 일반화한 것이다.
//  이 파일은 like-apple 스킬의 references/recipes.md 에서 자동 생성된다 — 고칠 때는 레시피를 고치고 다시 만든다.
//
//  검사용 묶음이다 — 사용자 프로젝트에는 필요한 레시피만 옮겨 쓴다. 들어 있는 것:
//    Motion            모션 어휘 (settle / present / morph / lift / pressDown / pressRelease / exit / swap / reduced)
//    .motion(_:value:) 동작 줄이기를 자동으로 따르는 .animation
//    PressableStyle    누르는 순간 반응하는 버튼
//    Materialize       재질이 도착하는 등장
//    .contentDrop      들어올 때와 나갈 때가 다른 전환
//    EmergeFromSource  끊어도 이어지는 등장 (genie)
//    SegmentMeter · CountdownRing · DecayingShake · TransitionsExample
//    Physics · VelocityTracker · PresentedOffset · SnapDragExample   손의 속도를 이어받는 드래그
//    PagedDeck · Haptics · GlassMorphMenu · SymbolEffectsTour · Pop · IslandMorph
//    CometStroke · RotatingGlowBorder · LivingMesh · ZoomTransitionExample
//    AppleMetrics · .appleHitTarget() · ConcentricCardExample   컨트롤·베젤 규격, 최소 터치 영역, 동심 모서리
//    .applePointerEffect · Haptics.play(meaning:) · SystemSheetExample · AdaptiveRow · GlassLayeringExample · .rejectShake   플랫폼 HIG
//
//  이름이 이미 쓰이고 있으면(예: Motion, Haptics) 프로젝트에 맞게 접두어를 붙여 바꾼다.
//

import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum Motion {
    /// 상태가 바뀌었다는 사실 자체(토글, 면이 나타남/사라짐, 호버, 드롭 상태).
    /// Apple `.smooth` — bounce 0. 사실은 튀지 않아야 하므로 되튐 없는 임계 감쇠가 기본이다.
    static let settle = Animation.smooth(duration: 0.30)

    /// 관성 없는 입력(키, 탭)으로 뜨는 HUD·카드. 관성이 없는 동작에 오버슈트를 주면 과장돼 보인다.
    static let present = Animation.smooth(duration: 0.38)

    /// 사용자가 직접 일으킨 모양 변화(펼침, 크기, 모서리). Apple `.snappy` — bounce 0.15(감쇠비 0.85).
    /// 오버슈트가 1% 아래라 튕김은 없고 감속감만 남는다.
    static let morph = Animation.snappy(duration: 0.42)

    /// 끌고 온 운동량이 남아 있는 움직임(파일을 들고 대상 위에 도착, 던진 뒤). Apple `.bouncy`(0.30)보다 살짝 조용한 0.28.
    static let lift = Animation.spring(duration: 0.35, bounce: 0.28)

    /// 누르는 건 사용자가 방금 한 일이라 기다릴 이유가 없다 — 거의 즉시.
    static let pressDown = Animation.easeOut(duration: 0.07)
    /// 놓은 뒤의 일은 물체처럼 돌아간다.
    static let pressRelease = Animation.smooth(duration: 0.26)

    /// 나갈 때는 들어올 때보다 빠르게. 미련이 남지 않고, 컨테이너가 접히기 전에 내용이 먼저 비워진다.
    static let exit = Animation.easeIn(duration: 0.13)

    /// 텍스트·이미지 교체. 움직이지 않고 밝기만 바뀐다.
    static let swap = Animation.easeInOut(duration: 0.28)

    /// 동작 줄이기 대체. 움직임은 빼고 "값이 바뀌었다"는 정보만 남긴다.
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

    // 이름을 Body로 하면 ButtonStyle의 연관 타입 Body와 부딪혀 컴파일이 안 된다.
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
            // 들어올 때와 나갈 때 곡선이 달라야 한다(P2). 같은 곡선을 쓰면 나갈 때도 0.3초 동안 흐려지며 번져서
            // "안개가 걷히는" 것처럼 보인다 — 실제 시뮬레이터 녹화에서 확인한 결함이다.
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
    var progress: Double          // 0 = 출발한 자리에 말려 있음, 1 = 다 나옴
    let anchor: UnitPoint         // 빨려드는 지점
    let startScale: Double        // 출발 크기 비율(썸네일 / 완성 크기)

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
            // 초반에만, 얕게. 큰 이미지를 매 프레임 블러하는 비용이라 반경이 곧 프레임 드랍이다.
            .blur(radius: progress < 0.5 ? (0.5 - progress) * 6 : 0)
            // 끝까지 반투명하면 유령처럼 보이므로 초반에 빨리 불투명해진다.
            .opacity(min(1, progress * 2.2))
    }
}

// 사용: 상태로 구동하고, 스프링 하나를 바깥에서 건다.
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
                // level이 조각 한 개 몫(1/count)을 지날 때마다 그 조각이 0에서 1로 켜진다.
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
    let elapsed: Double           // 지나간 몫 0...1
    let isRunning: Bool
    var tint: Color = .orange
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: min(max(elapsed, 0), 1), to: 1)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))      // 12시가 기준선이다. 시계가 그러니까.
        }
        .padding(lineWidth / 2)                       // 선은 경로 양쪽으로 번지므로 절반 들여 잉크를 상자 끝에 맞춘다
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
        // 동작 줄이기: 회전 대신 크기만 숨 쉰다. 알림을 없애는 게 아니라 어지럽지 않게 바꾼다.
        guard !reduceMotion else {
            withAnimation(.easeInOut(duration: 0.4)) { scale = 1.1 }
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.4)) { scale = 1 }
            try? await Task.sleep(nanoseconds: 400_000_000)
            return
        }

        // 맞는 순간 살짝 부푼다. 흔들림보다 먼저 끝나야 '맞았다'와 '흔들린다'가 겹치지 않는다.
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
    /// 가능하면 iOS 18 / macOS 15의 magic replace, 아니면 일반 replace.
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
    /// 지금 속도로 계속 미끄러지면 어디서 멈추는지(스크롤 감속과 같은 지수 감쇠).
    static func project(velocity: Double, deceleration: Double = 0.99) -> Double {
        velocity / 1000 * deceleration / (1 - deceleration)
    }

    /// 넘친 만큼에 비례하되 갈수록 덜 따라오는 곡선. 점근선이 dimension × constant.
    static func rubberBand(_ overshoot: Double, dimension: Double, constant: Double = 0.55) -> Double {
        guard overshoot > 0 else { return 0 }
        return (overshoot * dimension * constant) / (dimension + constant * overshoot)
    }

    /// 응답(초)·감쇠비 두 값으로 만드는 스프링. 시작 속도를 넘길 수 있는 건 이쪽뿐이다.
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

/// 놓는 순간 기준으로 직전 0.1초의 손끝 속도(pt/초)를 구한다. 그보다 오래된 움직임은 이미 멈춘 손의 것이다.
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

/// 화면에 실제로 그려지는 값. `@State`에는 목표값만 있으므로, 스프링이 도는 동안의 위치는 여기서 읽는다.
/// 상태가 아니라 참조라서 매 프레임 써도 뷰를 다시 그리게 하지 않는다.
final class PresentedValue {
    var value: Double = 0
}

/// 가로 위치를 그리면서, 애니메이션 중 매 프레임의 값을 `PresentedValue`에 적어 둔다.
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

/// 가로로 끌어 몇 개의 자리 중 하나에 내려앉는 카드.
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
                    // 잡는 순간 화면에 보이던 값. 목표값(x)에서 출발하면 스프링이 한창일 때 순간이동한다.
                    origin = presented.value
                    tracker.reset()
                }
                tracker.record(x: Double(value.translation.width))
                let raw = (origin ?? x) + Double(value.translation.width)
                // 애니메이션 없이 1:1. 도는 중이던 스프링은 여기서 멈추고, 보이던 자리에서 이어서 끈다.
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

    /// 스크롤이 만든 이동 중 화면에 남기는 비율. 1에 가까울수록 손가락에 더 붙는다.
    private static let travel: CGFloat = 0.55
    /// 이 거리(페이지 폭 대비)에서 완전히 사라진다.
    private static let fadeDistance: CGFloat = 0.46
    private static let maxBlur: CGFloat = 7

    func body(content: Content) -> some View {
        // scrollTransition 클로저는 Sendable이라 MainActor 정적 상수를 직접 못 읽는다. 지역 값으로 먼저 꺼낸다.
        let fadeDistance = Self.fadeDistance
        let travelRatio = reduceMotion ? 0 : Self.travel
        let maxBlur = reduceMotion ? 0 : Self.maxBlur
        let reduceMotion = reduceMotion
        let pageWidth = pageWidth

        return content.scrollTransition(.interactive, axis: .horizontal) { view, phase in
            let distance = min(abs(phase.value), 1)
            let t = min(distance / fadeDistance, 1)
            // ease-out: 초반에 빨리 옅어지고 막판엔 완만. 같은 거리에서 선형보다 항상 더 흐리다.
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
                            // 이동을 상쇄해 제자리에 두면 옆 화면이 지금 화면 위에 겹쳐 서 있다.
                            // 안 보일 뿐 눌리기는 하므로 보고 있는 화면만 클릭을 받게 한다.
                            .allowsHitTesting(selection == nil || selection == item.id)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selection)
            // 스크롤 뷰가 제 테두리에서 내용을 자르면 남는 이동분이 좌우 끝에서 싹둑 잘린다.
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
        // keyframeAnimator 클로저는 Sendable이라 환경 값을 직접 못 읽는다. 지역 값으로 먼저 꺼낸다.
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
    /// 같은 획을 세 겹으로 쌓아 빛이 번지게 한다.
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
    var progress: Double          // 0...1, 머리의 위치
    var tail: Double = 0.35       // 꼬리 길이(경로 대비). 1이면 손글씨
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
            // 돌려도 모서리가 비지 않도록 대각선 길이의 정사각형을 돌린다.
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

// 사용: CometStroke(progress: p, tail: 1, fill: .white, lineWidth: 6, blurRadius: 0) { MyPathShape() }
//       .onAppear { withAnimation(.easeInOut(duration: 4)) { p = 1 } }

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
    /// 컨트롤(버튼 등)의 기본·최소 크기. HIG 값이며 플랫폼마다 다르다.
    enum HitTarget {
        #if os(macOS)
        static let `default`: CGFloat = 28
        static let minimum: CGFloat = 20
        #else
        static let `default`: CGFloat = 44
        static let minimum: CGFloat = 28
        #endif
    }

    /// 베젤(눈에 보이는 배경·테두리)이 있는 컨트롤 주변 여백 ≈ 12pt, 없는 컨트롤은 눈에 보이는 가장자리 기준 ≈ 24pt.
    static let paddingAroundBezeled: CGFloat = 12
    static let paddingAroundBezelless: CGFloat = 24

    /// 동심 모서리: 안쪽 도형의 반경 = 바깥 반경 − 둘 사이 여백. 그래야 모서리를 따라 간격이 일정하다.
    static func concentricRadius(outer: CGFloat, inset: CGFloat) -> CGFloat {
        max(outer - inset, 0)
    }
}

extension View {
    /// 눈에 보이는 크기와 상관없이 누를 수 있는 영역을 규격 이상으로 만든다.
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
    /// 포인터가 올라왔을 때의 반응. iPadOS는 시스템 포인터 효과, macOS는 호버 밝기.
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
            // 큰 요소: 포인터 모양은 그대로, 틴트만. 크기를 키우지 않는다(이웃과 겹침).
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
        // macOS 햅틱은 드래그·포스 클릭 중의 신호다. 작업 결과(success 등)에는 대응 패턴이 없으므로 울리지 않는다.
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
        Button("편집") { isPresented = true }
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    Form { Toggle("변경 사항 있음", isOn: $hasChanges) }
                        .navigationTitle("편집")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("취소") { isPresented = false } }
                            ToolbarItem(placement: .confirmationAction) { Button("완료") { isPresented = false } }
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
        // HStack/VStack을 if로 갈아 끼우지 않는다 — AnyLayout은 정체성을 유지해 자리가 흐른다.
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
                            // 사진 위의 떠 있는 컨트롤: clear 유리 + 밝은 바탕 대비용 35% 딤.
                            Button("재생", systemImage: "play.fill") {}
                                .labelStyle(.iconOnly)
                                .frame(width: 44, height: 44)
                                .background(.black.opacity(0.35), in: Circle())
                                .glassEffect(.clear.interactive(), in: Circle())
                                .padding(12)
                        }
                    ForEach(0..<30, id: \.self) { i in
                        Text("행 \(i)").frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).padding(.horizontal)
                    }
                }
            }
            .scrollEdgeEffectStyle(.soft, for: .top)   // 툴바 배경 대신
            .navigationTitle("보관함")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("완료") {}.buttonStyle(.glassProminent)
                }
            }
        }
    }
}

extension View {
    /// 거절된 입력: trigger가 바뀔 때마다 좌우로 잦아드는 흔들림 한 번.
    func rejectShake<T: Equatable & Sendable>(trigger: T) -> some View {
        modifier(RejectShake(trigger: trigger))
    }
}

struct RejectShake<T: Equatable & Sendable>: ViewModifier {
    let trigger: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let amplitude = reduceMotion ? 0.0 : 1.0   // 클로저 밖에서 읽는다(Swift 6 격리)
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
