# 레시피 — 출발점이 되는 SwiftUI 모션 코드

아래 ```swift 블록은 위에서 아래로 **하나의 파일로 이어 붙이면 그대로 컴파일된다**
(iOS 17+ / iPadOS 17+ / macOS 14+ 최소 타깃으로 타입체크 확인. Swift 5·6 언어 모드 모두 통과 —
`Animatable` 쪽 `animatableData`에 `nonisolated`를 붙인 건 Swift 6 모드에서 MainActor 격리 오류를 피하려는 것이다). 이름이 겹치지 않게 짜여 있으니
필요한 블록만 떼어 가도 되고, 앞 블록(`Motion`)에만 의존한다.

**쓰는 법:** 레시피는 출발점이다. 사용자 프로젝트에는 필요한 부분만, 그 프로젝트의 이름·스타일에 맞춰 옮겨 쓴다.
전체를 이어 붙인 `assets/AppleMotion.swift`는 레시피가 실제로 컴파일되는지 검사하려고 만든 것이라 통째로 복사하지 않는다.

목차
1. 모션 어휘 `Motion` (Apple 프리셋 이름)
2. 동작 줄이기를 한 곳에서 처리하는 `.motion(_:value:)`
3. 누르는 순간 반응하는 버튼 `PressableStyle`
4. 재질이 도착하는 `Materialize`
5. 들어올 때와 나갈 때가 다른 전환 `contentDrop`
6. 끊어도 이어지는 등장 `EmergeFromSource` (상태 구동)
7. 값을 흘리는 `SegmentMeter` (Animatable + Canvas)
8. 줄어드는 링 `CountdownRing`
9. 잦아드는 흔들림 `DecayingShake`
10. 숫자·심볼 전환
11. 손의 속도를 이어받는 드래그 `SnapDragExample`
12. 페이지 깊이 `PagedDeck`
13. 플랫폼별 햅틱 `Haptics`
14. Liquid Glass 변형 `GlassMorphMenu` (Apple API)
15. SF Symbols 효과 한눈에 `SymbolEffectsTour`
16. 키프레임 "톡" `Pop`
17. 끝난 시점 잡기 + 블러 교체 `CompletionExample`
18. Dynamic Island식 모양 변화 `IslandMorph`
19. 혜성 획 글로우 `CometStroke` · 회전 테두리 `RotatingGlowBorder`
20. 살아 있는 메시 `LivingMesh`
21. 줌 전환 `ZoomTransitionExample` (iOS 18)
22. 컨트롤·베젤 규격과 최소 터치 영역 `AppleMetrics` · `.appleHitTarget()`
23. 동심 모서리 `ConcentricCardExample`
24. 포인터 효과 `.applePointerEffect(_:)` (iPadOS highlight·lift·hover / macOS 호버)
25. 의미로 고르는 햅틱 `Haptics.play(meaning:)` (HIG 패턴 의미)
26. 시스템 시트 `SystemSheetExample` (detent · grabber · 저장 안 한 변경 보호)
27. 공간에 따라 흐르는 레이아웃 `AdaptiveRow` (Dynamic Type · size class)
28. Liquid Glass 층 나누기 `GlassLayeringExample` (iOS 26 / macOS 26)
29. 거절 흔들림 `.rejectShake(trigger:)`

---

## 1. 모션 어휘

값을 코드 곳곳에 흩뿌리지 않고 이름 하나로 모은다. 이름이 곧 "어떤 종류의 움직임인가"라서,
새 애니메이션을 붙일 때 숫자를 고르는 대신 종류를 고르게 된다.

```swift
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
```

## 2. 동작 줄이기를 한 곳에서

`.animation(_:value:)` 대신 이것을 쓰면 모든 애니메이션이 `accessibilityReduceMotion`을 자동으로 따른다.
곡선만 바꾸므로 이동·확대 같은 *변환* 자체를 빼야 하는 곳은 값으로 같이 꺼 준다(4번 `Materialize` 참고).

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

## 3. 누르는 순간 반응하는 버튼

- 누름/놓음 곡선이 다르다. 같은 곡선이면 눌러도 반응이 굼뜬 것처럼 느껴진다.
- 눌림은 `opacity`가 아니라 `brightness`로 말한다. 채운 알약에 투명도를 걸면 눌린 게 아니라 꺼진 것처럼 보인다.
- 호버는 포인터가 있는 플랫폼(macOS, 포인터 연결된 iPadOS)에서 "여기다"를 미리 알려 준다. 터치 전용 iPhone에서는 호출되지 않을 뿐 해롭지 않다.
- `ButtonStyle`은 `@State`를 못 가지므로 호버를 위해 한 겹 감싼다.

```swift
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
```

## 4. 재질이 도착하는 등장

단순 페이드는 "켜졌다"로 읽힌다. 블러·확대·이동·투명도를 **출발한 자리(anchor)** 에서 함께 움직여야
"재질이 도착했다"로 읽힌다.

주의: (a) 블러는 매 프레임 비용이 든다 — 크고 얕게 말고 작고 짧게. (b) SwiftUI의 `.blur`는 AppKit/UIKit이
그리는 재질(`NSVisualEffectView`, `NSGlassEffectView`, `UIVisualEffectView`)에는 걸리지 않으므로 *내용에만* 건다.
(c) 동작 줄이기에서는 변환을 전부 빼고 투명도만 남긴다.

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
            // 들어올 때와 나갈 때 곡선이 달라야 한다(P2). 같은 곡선을 쓰면 나갈 때도 0.3초 동안 흐려지며 번져서
            // "안개가 걷히는" 것처럼 보인다 — 실제 시뮬레이터 녹화에서 확인한 결함이다.
            .animation(reduceMotion ? Motion.reduced : (isPresented ? Motion.present : Motion.exit), value: isPresented)
    }
}
```

## 5. 들어올 때와 나갈 때가 다른 전환

컨테이너(노치, 시트, 카드)가 크기를 바꾸는 동안 안의 내용이 어떻게 드나드는가.
- **들어올 때**: 컨테이너가 먼저 벌어지고, 내용이 조금 늦게(`delay`) 내려앉는다.
- **나갈 때**: 내용을 컨테이너보다 *빠르게* 비운다. 내용이 남은 채 컨테이너가 접히면 빈 껍데기가 천천히 닫히거나 글자가 모서리에 깎인다.

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

목록 항목처럼 **들어온 자리로 도로 접혀 들어가야** 하는 것은 같은 길을 쓴다:
`.transition(reduceMotion ? .opacity : .scale(scale: 0.82).combined(with: .opacity))`.
이때 `.transition`이 실제로 돌려면 값을 바꾸는 쪽이 아니라 *보는 쪽*에 `.animation(_, value:)`를 걸어야 할 때가 많다
(타이머 콜백처럼 `withAnimation` 밖에서 값이 바뀌는 경우).

## 6. 끊어도 이어지는 등장 (상태 구동)

`if isOpen { View().transition(...) }`는 삽입/제거 애니메이션이라 도중에 끊을 수 없다. 끝나기 전에 다시 누르면
제거와 삽입이 겹쳐 쌓이고, 무거운 블러가 얹히면 메인 스레드가 밀려 멈춘다.
뷰는 **항상 두고** `progress`(0→1)로 그린다. 스프링은 현재 값에서 목표만 바꿔 잡으므로 몇 번을 연타해도 이어서 움직인다.

세로(지수 0.6, 일찍)와 가로(지수 2.0, 늦게)의 속도를 벌리면 좁은 목을 빠져나오는 램프 요정(genie) 같은 인상이 난다.

```swift
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
```

`progress`가 매 프레임 바뀌므로, 이 값을 바깥 뷰가 직접 관찰하면 프레임마다 카드 전체가 다시 그려진다.
관찰(`@ObservedObject`)은 이런 modifier **안으로 가둬서** 다시 그려지는 범위를 투명도·크기로 좁힌다.

## 7. 값을 흘리는 Animatable (이름 교체 금지)

구간마다 이미지·심볼 이름을 바꾸면(`wave.1 → wave.2 → wave.3`) 바뀌는 순간 뚝 끊기고, 값이 경계 근처에 머물면 깜빡인다.
값 하나(`level`)를 애니메이션하고 **매 프레임 조각별 밝기를 그 값에서 계산**하면 조각이 차례로 켜진다.
조각마다 따로 `opacity` 애니메이션을 걸면 전부 동시에 켜지므로 안 된다.

SF Symbols가 가변 값을 지원하면 그쪽이 가장 싸다: `Image(systemName: "speaker.wave.3.fill", variableValue: level)`.
지원하지 않는 심볼(예: 해)은 아래처럼 직접 그린다. 이때 스프링은 **감쇠 1.0** — 조각이 문턱을 넘는 순간 켜지고 꺼지므로
되튀면 문턱을 오가며 깜빡인다.

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
```

## 8. 줄어드는 링 (시간을 모양으로)

- 카운트다운에서 눈이 찾는 건 지나간 양이 아니라 **남은 양**이다. 채워지는 링이 아니라 줄어드는 링.
- 지나간 자리를 완전히 지우지 말고 옅게 남긴다 — 줄어드는 게 아니라 조각이 사라지는 것처럼 보인다.
- 초 단위로 갱신되는 값은 **linear 1초**로 잇는다. 스프링을 걸면 초마다 출렁인다. 돌고 있지 않을 때(되감기, 단계 전환)는 짧은 ease — 1초 동안 천천히 차오르면 굼뜨다.

```swift
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
```

## 9. 잦아드는 흔들림

종은 위쪽 고리에 매달려 흔들린다 → 회전 중심은 한가운데가 아니라 **꼭대기**(`anchor: .top`). 가운데를 축으로 돌리면
"울린다"가 아니라 "로딩 중"으로 읽힌다. 진폭은 한 번 칠 때마다 줄어든다 — 같은 폭으로 계속 흔들리면 기계가 떠는 것이다.
한 번 울리고 **쉰다** — 쉬지 않으면 알림이 아니라 소음이 되어 눈이 무시하기 시작한다.
`DispatchQueue`로 자기 자신을 재호출하지 말고 `.task`를 쓴다 — 뷰가 사라지면 자동으로 취소된다.

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
```

## 10. 숫자·심볼 전환

- 숫자: `.numericText`가 자릿수를 굴린다. `countsDown`을 실제 방향에 맞춘다. `.monospacedDigit()`가 없으면 한 자리↔두 자리에서 좌우로 떨린다.
- 제목·이름 교체: `.opacity`. 슬라이드시키면 좁은 열에서 글자가 옆으로 미끄러지며 그 자체로 잘린 것처럼 보인다.
- 상태가 뒤집히는 아이콘(재생↔일시정지): 같은 자리에서 `.symbolEffect(.replace)`. 이름이 바뀌어도 몸통은 두고 달라진 부분만 갈아 끼운다.
- "톡 내려앉음" 같은 일회성 강조: `.symbolEffect(.bounce.down, value: count)`. 동작 줄이기에서는 `value`를 `0`으로 고정해 끈다.

```swift
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
```

## 11. 손의 속도를 이어받는 드래그

드래그와 애니메이션 사이에 이음매가 없어야 "손에 붙어 있다"는 느낌이 난다. 순서:

1. **잡는 순간**: 화면에 *보이던* 값에서 출발한다(목표값이 아니다). 안 그러면 스프링이 한창일 때 잡은 순간 순간이동한다.
   SwiftUI의 `@State`에는 목표값만 있으므로, 그려지는 값은 따로 적어 둔다(`Animatable` 안에서 기록).
2. **끄는 동안**: `Transaction(animation: nil)`로 즉시 반영 → 손가락과 1:1.
3. **경계 밖**: 러버밴딩. 넘친 만큼 덜 따라온다.
4. **놓는 순간**: 속도는 `DragGesture`가 주는 값을 믿지 말고 **직전 0.1초의 움직임**으로 직접 계산한다.
   `value.velocity`는 손이 멈춘 뒤에도 마지막 이동 속도를 들고 있어서, 끌다 멈추고 한참 있다 놓아도 튕겨 나간다.
5. **멈출 자리를 투영**: `현재 + (v/1000)·d/(1−d)`(스크롤 감속과 같은 지수 감쇠. `v²/2a` 같은 교과서 식이 아니다) → 가장 가까운 목표.
6. **스프링에 시작 속도를 넘긴다**: `.spring()`에는 그 인자가 없으므로 `interpolatingSpring(initialVelocity:)`를 쓴다.
   이 값은 **남은 거리 대비 상대 속도**다(`v / (목표 − 현재)`).
7. **튕겨 던졌을 때만** 살짝 넘쳤다 돌아온다(감쇠 ~0.82). 살살 놓은 것이 넘쳤다 돌아오면 흔들리는 것이다.

```swift
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

/// 가로로 끌어 몇 개의 자리 중 하나에 내려앉는 카드.
struct SnapDragExample: View {
    let snapPoints: [Double] = [0, 120, 240]
    @State private var x: Double = 0
    @State private var origin: Double?
    @State private var tracker = VelocityTracker()

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.tint)
            .frame(width: 80, height: 80)
            .offset(x: x)
            .gesture(drag)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if origin == nil {
                    origin = x                       // 잡는 순간 보이던 값
                    tracker.reset()
                }
                tracker.record(x: Double(value.translation.width))
                let raw = (origin ?? x) + Double(value.translation.width)
                // 애니메이션 없이 1:1. 스프링이 한창일 때 잡아도 그 자리에서 멈춘다.
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

## 12. 페이지 깊이 (시스템 페이징 + scrollTransition)

가로로 넘기는 화면은 `DragGesture`로 직접 만들지 않는다. 특히 **macOS의 스와이프는 트랙패드 두 손가락 *스크롤 이벤트*라
`DragGesture`에 아예 잡히지 않는다.** 시스템 페이징은 손을 뗀 속도로 다음 칸 정하기(모멘텀 투영), 끝에서의 러버밴딩,
넘어가는 도중에 잡아 되돌리기를 이미 한다.

그 위에 수동 "도착 스프링"을 한 번 더 얹지 않는다. 시작 시점(`selection` 변경 직후)과 네이티브 감속이 실제로 멈추는 시점이
같지 않아서, 빠르게 튕겨 넘기면 서로 다른 박자의 움직임 두 개가 겹쳐 보인다 — 그게 "애니메이션이 구리다"의 정체다.
**하나만 남기고 믿는다.** 깊이감은 `scrollTransition(.interactive)`로 스크롤 위치에서 직접 계산한다.

```swift
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
```

## 13. 플랫폼별 햅틱

햅틱도 모션의 일부다 — 눈에 보이는 변화와 **같은 프레임**에 울려야 하고, **의미 있는 순간**에만 울려야 한다.
눈금을 하나 지날 때(detent)는 울리고, 잡거나 놓는 순간에는 울리지 않는다. 5분 눈금처럼 큰 단위는 한 단계 굵게.

macOS에서 `.sensoryFeedback`은 컴파일되지만 대부분의 패턴이 **조용히 지나간다**(이 프로젝트에서 확인). Force Touch
트랙패드에 실제 신호를 보내는 건 `NSHapticFeedbackManager`다. 대부분의 iPad에는 햅틱 엔진이 없으므로
햅틱을 유일한 피드백으로 쓰지 말고 시각 피드백이 항상 먼저 있어야 한다.

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

선언적으로 쓰는 iOS 17+ 경로는 `.sensoryFeedback(trigger: detent) { _, new in new % 5 == 0 ? .levelChange : .alignment }`.
macOS 사용자에게도 닿게 하려면 이 선언형만 믿지 말고 위 `Haptics.play`를 `onChange`에서 함께 부른다.

## 14. Liquid Glass 변형 (Apple 공식 API)

Liquid Glass 요소가 서로 합쳐지고 갈라지는 움직임은 직접 만들지 않는다. 같은 `GlassEffectContainer` 안에서
`glassEffectID(_:in:)`에 같은 네임스페이스를 주고 상태를 `withAnimation`으로 바꾸면 시스템이 변형한다(WWDC25).
- 유리는 다른 유리를 샘플링하지 못하므로, 가까이 놓인 유리는 반드시 컨테이너로 묶는다.
- `.interactive()`는 눌렀을 때의 확대·되튐·반짝임을 시스템이 맡는다(세션에서 iOS 기능으로 소개됨 — macOS에서는 타입체크만 확인했고 시각 효과는 확인하지 않았다).
- 곡선은 `Motion.morph`(snappy)가 맞다 — 유리 변형은 사용자가 일으킨 모양 변화다.

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

## 15. SF Symbols 효과 한눈에

아이콘 움직임은 직접 `rotationEffect`를 돌리기 전에 먼저 심볼 효과를 찾는다. 값(`value:`)이 바뀔 때 한 번 도는 효과와,
`isActive:`로 켜 두는 효과가 있다. 동작 줄이기에서는 trigger를 고정하거나 `isActive`를 끈다.

| 효과 | 쓰임 | 구동 |
| --- | --- | --- |
| `.bounce` | "톡" — 도착·완료 (`.bounce.down`: 내려앉음) | `value:` |
| `.pulse` | 진행 중·대기 | `isActive:` |
| `.variableColor.iterative` | 신호·로딩이 차례로 켜짐 | `isActive:` |
| `.wiggle` · `.breathe` · `.rotate` | iOS 18 / macOS 15 이상 | `value:` / `isActive:` |
| `.replace` | 상태가 뒤집히는 아이콘 | `contentTransition` (10번) |

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

## 16. 키프레임 "톡"

한 번 커졌다 돌아오는 강조(좋아요, 추가됨). `KeyframeAnimator`는 `trigger`가 바뀔 때마다 처음부터 다시 돈다.
커질 때는 짧고 빠르게(snappy), 돌아올 때는 되튐 없이(smooth).

```swift
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
```

## 17. 끝난 시점 잡기 + 블러 교체

스프링은 지수적으로 줄어드는 꼬리가 있어서 "완전히 멈춘 시간"을 기다리면 끝이 없다. Apple은 체감 시간(`duration`)이 끝난
시점을 쓰라고 한다 — `completionCriteria: .logicallyComplete`. 타이머(`asyncAfter`)로 시간을 짐작하지 말고 이것을 쓴다.
내용이 바뀌는 순간의 시선 처리는 `.transition(.blurReplace)`가 흐림과 투명도를 함께 다룬다.

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

## 18. Dynamic Island식 모양 변화

작은 알약이 불쑥 커졌다 줄어드는 것의 정체는 세 가지다.
1. **모양 전체가 스프링 하나**로 움직인다 — 너비·높이·모서리가 같은 `Motion.morph`를 쓴다. 따로 놀면 일그러진다.
2. **나가는 내용이 컨테이너보다 먼저 비워진다**(`Motion.exit`), 들어오는 내용은 컨테이너가 벌어진 뒤 내려앉는다(`contentDrop`).
3. 모서리는 **높이의 절반(알약) ↔ 더 작은 값**으로 움직인다. 클립 모양도 같은 값으로 잘라야 내용이 모서리를 넘지 않는다.

Apple이 Dynamic Island에 쓰는 정확한 곡선은 공개되어 있지 않다. 위 구성은 이 앱에서 시각 검증으로 수렴한 근사이고,
크기 값(아래 기본값)은 예시다 — 실제 크기는 기기·콘텐츠에 맞춘다.

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

## 19. 혜성 획 글로우 · 회전 테두리

Apple Intelligence·Siri 계열의 빛과 손글씨 "hello"가 쓰는 재료다.
- **혜성 획**: 경로를 `trim`으로 잘라 머리(`progress`)가 앞서고 꼬리가 `tail`만큼 뒤따른다. 꼬리가 마지막에 머리를 따라잡아 획이 사라진다.
  `from = max(0, progress − tail, 2·progress − 1)` — 세 구간(자라남 / 이동 / 사라짐)이 한 식으로 이어지고, `tail = 1`이면 손글씨처럼 그려진 뒤 지워진다.
- **글로우**: 같은 획을 굵기·블러를 달리해 세 겹 쌓는다(선명한 심 + 퍼지는 빛 두 겹).
- **회전 테두리**: 도형보다 큰 `AngularGradient`를 선형으로 돌리고 테두리 모양으로 마스크한다. 끝없이 도는 것은 동작 줄이기에서 멈춘다.
  (HIG는 지속적인 진동·회전을 주의하라고 한다 — visionOS 기준 약 0.2Hz.)
- 진행 값 하나(`progress`)를 `Animatable`로 애니메이션하는 것이 핵심이다 — 획의 조각마다 따로 애니메이션하지 않는다.

```swift
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
```

## 20. 살아 있는 메시

메시 그라디언트가 숨 쉬듯 일렁이게 하는 법: 제어점·색을 **서로 다른 주기**의 `repeatForever(autoreverses: true)`로 따로 움직인다.
주기가 서로 약수 관계가 아니면 패턴이 좀처럼 반복되지 않아 유기적으로 보인다(1.5s, 1.8s, 2.2s처럼).
동작 줄이기에서는 움직이지 않고 정지한 메시만 남긴다.

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

## 21. 줌 전환 (iOS 18)

앱 아이콘이 열리듯 셀이 화면으로 커지는 전환. 출발 뷰에 `matchedTransitionSource`, 도착 뷰에 `.navigationTransition(.zoom)`을
같은 네임스페이스로 건다. 손으로 끌어 닫는 동안 속도를 이어받는 것까지 시스템이 한다(WWDC24) — 직접 만들지 않는다.

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

## 22. 컨트롤·베젤 규격과 최소 터치 영역

Apple은 컨트롤의 기본·최소 크기와, 눈에 보이는 배경(**베젤**)이 있을 때와 없을 때의 주변 여백을 정해 두었다 [HIG Accessibility].
눈에 보이는 아이콘이 작아도 **누르는 영역**은 규격을 채워야 한다 — 그래서 `contentShape`와 최소 프레임을 함께 쓴다.
글자 크기는 하드코딩하지 않고 `.font(.body)` 같은 **의미 있는 스타일**을 쓴다 — SwiftUI가 플랫폼별 크기(iOS body 17, macOS body 13)를 주고 Dynamic Type에 따라 커진다
(크기 표는 [metrics.md](metrics.md)). 글자에 묶인 치수는 `@ScaledMetric`.

```swift
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
```

## 23. 동심 모서리

중첩된 둥근 도형(카드 안의 카드, 화면 모서리 안의 패널)은 **반경이 같으면 어긋나 보인다.** 안쪽 반경을 `바깥 − 여백`으로 줄이면 모서리를 따라 간격이 일정해진다.
이 앱의 `NotchCardMetrics`가 같은 규칙이다(노치 아래 모서리와 동심이 되게 카드 반경을 잡음). iOS 26 / macOS 26에서는 `ConcentricRectangle`이
`containerShape`를 읽어 반경을 알아서 계산한다. 화면(기기) 모서리의 정확한 반경은 공개 API가 없으므로 숫자를 하드코딩하지 말고
`ContainerRelativeShape` / `ConcentricRectangle`에 맡긴다. 모서리는 항상 `style: .continuous`.

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

## 24. 포인터 효과 (iPadOS · macOS)

포인터가 있는 플랫폼에서는 **누르기 전에** "여기다"를 알려야 한다. iPadOS는 시스템이 세 가지 효과를 준다 [HIG Pointing devices]:
- **highlight** — 배경이 투명한 작은 요소(바 버튼, 탭, 세그먼트). 포인터가 둥근 사각형 배경으로 변한다.
- **lift** — 배경이 불투명한 작은 요소(앱 아이콘, 컨트롤 센터 버튼). 살짝 떠오르며 그림자·반사광이 생긴다.
- **hover** — 큰 요소. 포인터 모양은 그대로 두고 틴트·크기·그림자만 바꾼다. **표 행처럼 옆과 붙은 요소에는 크기를 키우지 않는다**(이웃과 겹친다).

highlight·lift는 포인터가 요소 모양으로 **변신**하므로 모서리 반경을 알려 줘야 이음매 없이 바뀐다(`contentShape(.hoverEffect, ...)`).
바 안의 버튼들은 터치 영역을 **이어 붙인다** — 사이에 틈이 있으면 포인터가 기본 모양으로 잠깐 돌아가며 깜빡인다.
macOS에는 이 효과가 없으므로 호버 밝기(P12의 `+0.08`)와 옅은 배경으로 대신한다. 커서 모양이 의미를 가질 때(링크, 끌기)는
macOS 15+의 `.pointerStyle(.link)` 등 시스템 커서를 쓰고 직접 그리지 않는다.

```swift
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
```

## 25. 의미로 고르는 햅틱

HIG는 시스템 햅틱을 **문서화된 의미대로만** 쓰라고 한다 — 성공 햅틱을 실패에 쓰면 사람이 배운 연결이 깨진다 [HIG Playing haptics].
그래서 "어떤 진동"이 아니라 "무슨 일이 일어났나"로 고른다. §13의 `Haptics.play(_:)`는 그대로 두고 의미 이름을 더한다.

| 의미 | iOS | macOS (Force Touch 트랙패드) |
| --- | --- | --- |
| `selection` 값이 한 칸 바뀜(피커·눈금) | `UISelectionFeedbackGenerator` | `.alignment` |
| `snap` 제자리에 딸깍 맞음 | `UIImpactFeedbackGenerator(.light)` | `.alignment` |
| `boundary` 처음·끝·최소·최대에 닿음 | `UIImpactFeedbackGenerator(.rigid)` | `.alignment` |
| `success` · `warning` · `failure` 작업의 결과 | `UINotificationFeedbackGenerator` | **없음** — 시각으로 |

macOS 햅틱은 HIG상 **드래그 중이거나 포스 클릭할 때**의 신호다(정렬·압력 단계·일반). 작업 결과를 진동으로 알리는 패턴이 없으므로
결과는 화면에서 보여 준다. 모든 햅틱은 **끌 수 있어야 하고**, 햅틱 없이도 앱이 온전히 쓰여야 한다.

```swift
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
```

## 26. 시스템 시트 — 만들지 말고 설정한다

시트를 끌어 올리고 내리는 움직임(속도 이어받기, 칸에 맞춰 멈춤, 러버밴딩, 끌어서 닫기)은 시스템이 이미 한다 — §11을 시트에 쓰지 않는다 (P8).
할 일은 HIG에 맞게 **설정**하는 것이다 [HIG Sheets]:
- iPhone에서는 **medium detent**로 먼저 보여 주고 필요하면 키운다(점진적 공개). 크기를 바꿀 수 있으면 **grabber**를 보인다 — VoiceOver로도 조작된다.
- **끌어서 닫기를 지원**한다. 저장하지 않은 변경이 있을 때만 막고(`interactiveDismissDisabled`), 닫으려 하면 확인을 받는다.
- **완료에는 항상 취소를 짝지운다.** 한 번에 시트 하나 — 시트를 닫았는데 다른 시트로 돌아가면 길을 잃는다.
- iPad는 page / form 시트(기본 크기, 뒤가 어두워짐). macOS 시트는 크기를 바꾸지 않는 게 보통이라 **내용에 맞는 기본 크기**를 준다.
  같은 입력을 반복하며 결과를 봐야 하면 시트가 아니라 패널(macOS)이나 비모달 시트(`presentationBackgroundInteraction`)를 쓴다.

```swift
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
```

## 27. 공간에 따라 흐르는 레이아웃

HIG: 레이아웃은 **기기 종류나 방향이 아니라 실제로 쓸 수 있는 공간**(size class, 창 크기)과 **글자 크기**로 정한다 [HIG Layout].
iPad 창은 자유롭게 크기가 바뀌고, iPhone 앱은 Mac의 iPhone 미러링에서 늘었다 줄었다 한다. 큰 글자에서는 옆으로 놓인 뷰가 세로로 쌓여야 글자가 잘리지 않는다.

여기서 모션이 끼어든다: `if`로 `HStack`과 `VStack`을 갈아 끼우면 뷰가 **새로 만들어져** 뚝 바뀐다(P5와 같은 문제).
`AnyLayout`은 뷰의 정체성을 유지한 채 배치만 바꾸므로 같은 스프링 하나로 **자리가 흐른다.**
macOS에는 size class가 없다 — 창 너비가 필요하면 `ViewThatFits`나 `GeometryReader`로 판단한다.

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
```

## 28. Liquid Glass 층 나누기 (iOS 26 / macOS 26)

HIG의 층 규칙 [HIG Materials · Layout · Toolbars · Scroll views]:
- **Liquid Glass는 기능 층에만**(툴바·탭 바·사이드바·떠 있는 컨트롤). 콘텐츠 층(배경, 카드)에는 쓰지 않고 표준 재질(`.regularMaterial` 등)을 쓴다.
  예외는 슬라이더·토글처럼 **만지는 동안만** 유리가 되는 컨트롤.
- 커스텀 컨트롤에는 **아껴서** — 가장 중요한 기능 요소에만.
- 툴바 아래에 단색·반투명 배경을 깔지 않는다. 콘텐츠가 유리 밑으로 흐르게 두고 **scroll edge effect**로 컨트롤을 띄운다(뷰 하나에 하나).
- **clear 유리는 사진·영상 위에서만.** 바탕이 밝으면 35% 검정 딤 층을 깐다.
- 전면 배경 이미지는 사이드바·툴바 밑까지 채운다 — 가려질 부분은 `backgroundExtensionEffect()`가 뒤집고 흐려서 이어 준다.
- 핵심 동작(완료·제출) **하나만** prominent로, 툴바 trailing 쪽에. 표준 버튼은 바 모서리와 이미 동심이다 — 커스텀도 동심으로(§23).

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
```

## 29. 거절 흔들림 — 안 된다는 표시

틀린 암호, 놓을 수 없는 자리, 잠긴 항목처럼 **입력이 거절됐을 때** 아무 반응이 없으면 앱이 멈춘 것으로 읽힌다 [HIG Gestures].
좌우로 **한 번** 잦아들며 흔든다 — §9의 종처럼 반복하지 않는다. 진폭은 작게(10pt에서 시작해 줄어듦), 전체 0.35초 안쪽.
`keyframeAnimator`는 trigger가 바뀔 때마다 처음부터 다시 돌고, 흔드는 도중에 또 바뀌어도 이어진다.
동작 줄이기에서는 흔들지 않는다 — 대신 테두리·글자 색 같은 정적인 표시를 함께 둔다(이 modifier는 이동만 끈다). iOS는 `Haptics.play(meaning: .failure)`를 같은 순간에.
흔들림의 모양은 [앱] 근사다 — Apple이 쓰는 곡선을 측정하지 않았다.

```swift
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
```
