---
name: like-apple
description: Make native APPS feel like Apple made them — Apple-style animation, sizing and platform behavior in SwiftUI for iOS, iPadOS and macOS, grounded in Apple's Human Interface Guidelines and distilled from building the Live Peninsula macOS notch app. Includes a catalog of Apple motion behaviors (Dynamic Island, pill HUD, genie, Liquid Glass morph, Siri glow, zoom transition, SF Symbol effects, number roll, sheet snapping, button press, countdown ring, reject shake) plus app-structure behavior (sheets, tab/navigation transitions, list insert/delete, loading, popover resize, iPad pointer effects); per-platform HIG rules (touch vs pointer vs keyboard, haptic patterns, size classes, Liquid Glass vs standard materials, component rules); Apple's spring system measured against the SDK; HIG-verified type sizes, control/bezel sizes and concentric corners; 29 code recipes compile-checked on iOS 17/26 and macOS 14/26 (written into the user's code only as needed, never dropped in as a whole file); and tools to MEASURE a reference recording. Use whenever the user builds or reviews a Swift/SwiftUI app UI and wants it to look, move or feel "like Apple" — "애플처럼/애플스럽게", "Dynamic Island처럼", "시스템 HUD처럼", "알람/타이머", "Liquid Glass", "스프링", "쫀득하게", "튕김", "전환", "햅틱", "동작 줄이기", "글자 크기", "베젤", "둥근 모서리", "여백", "아이패드 포인터", "맥에서 어색해", "HIG" — or says it feels cheap/janky/"구리다", even without naming Apple. Covers native apps on iOS, iPadOS and macOS for now; watchOS, visionOS and tvOS are not covered yet.
---

# Like Apple — Apple의 애니메이션을 쉽게 만들기 (iOS · iPadOS · macOS)

"Dynamic Island처럼", "시스템 HUD처럼" 같은 요청을 받으면, 그 움직임이 **무엇으로 이루어졌는지** 분해해서 SwiftUI로 정확하게 옮긴다.
애플스러운 움직임은 화려한 것이 아니라 **조용히 정확한 것**이고, 네 문장으로 줄어든다.

1. 손이 만든 속도를 이어받는다.
2. 언제든 끊고 되돌릴 수 있다.
3. 움직임이 정보를 실어 나른다 (장식이 아니다).
4. 과장하지 않는다 — 튕김은 운동량이 있을 때만.

**범위: 앱.** iOS · iPadOS · macOS의 네이티브 앱(SwiftUI 중심, UIKit/AppKit 보조)만 다룬다. watchOS · visionOS · tvOS는 아직 다루지 않는다(앞으로 넓힐 예정).
움직임만이 아니라 **크기(베젤·둥근 모서리·글자)와 플랫폼 관례(입력 수단, 햅틱, 재질, 시스템 컴포넌트)**까지 Apple HIG를 근거로 맞춘다 —
움직임이 Apple다워도 iPad에서 포인터에 반응이 없거나 Mac에서 호버가 없으면 애플스럽지 않다.

**만든 배경: Live Peninsula.** 이 스킬은 macOS 노치 앱 **Live Peninsula**를 혼자 개발하며 쌓은 결과물이다. 그 앱의 철학 — 애플스러운 애니메이션,
둥근 베젤과 동심 모서리, 시스템처럼 조용히 정확한 움직임 — 을 지키려고 노치가 열리고 닫히는 스프링, 키 입력 HUD, 트레이로 끌어 온 파일,
잠금 화면 음악 카드, 스튜디오 타이머의 눈금 같은 기능을 직접 만들고 고치며 "예전엔 이랬는데 이래서 고쳤다"를 반복했다.
§3의 원칙(P1–P13)과 [앱] 등급의 값은 모두 그 과정에서 나왔고, 규칙마다 출처 파일은 [evidence.md](references/evidence.md)에 있다.
그 위에 Apple HIG와 SDK 측정을 더해, Live Peninsula 밖의 iOS · iPadOS · macOS 앱에서도 같은 감각을 낼 수 있게 일반화했다.

## 0. 무엇이 어디 있나

| | 내용 | 파일 |
| --- | --- | --- |
| **카탈로그** | Apple 동작 25개(앱 구조 포함)를 재료로 분해 + 구현 + 근거 등급. 먼저 여기서 찾는다 | [references/catalog.md](references/catalog.md) |
| **코드 레시피** | 바로 쓸 수 있는 레시피 29개. 참고해서 필요한 부분만 쓴다 | [references/recipes.md](references/recipes.md) (검사용 묶음: `assets/AppleMotion.swift` — macOS 14/26 · iOS 17/26 × Swift 5/6 컴파일 검증, 사용자 프로젝트에 복사하지 않는다) |
| **스프링 이해** | Apple 프리셋, 감쇠비 ↔ bounce, 오버슈트·정착 시간 | [references/springs.md](references/springs.md), `scripts/spring_probe.sh` |
| **플랫폼·앱 구조 (HIG)** | iOS · iPadOS · macOS의 입력·햅틱·레이아웃·재질 차이, 시트·탭 바·툴바·팝오버·알림·목록·진행 표시의 HIG 규칙 | [references/platforms.md](references/platforms.md) |
| **크기·글자·베젤** | Apple 글자 크기(iOS/macOS 22개 SDK 검증), 컨트롤·베젤 규격, 동심 모서리, Live Peninsula의 현재 크기 감사 | [references/metrics.md](references/metrics.md) |
| **레퍼런스 측정** | Apple 기기 녹화 → 프레임 보기 → 수치 → 스프링 맞춤(범위와 함께). 정확도를 검증해 둠 | [references/measurement.md](references/measurement.md), `scripts/filmstrip.sh` `track_video.sh` `fit_spring.py` |
| **근거** | 이 규칙이 Live Peninsula의 어느 파일·버그에서 나왔나 | [references/evidence.md](references/evidence.md) |

**근거 등급** — 섞어서 말하지 않는다. **[Apple]** 공식 API·세션·HIG가 보장하는 것 · **[SDK]** 이 맥의 SDK에서 측정한 것 ·
**[HIG]** Apple Human Interface Guidelines 본문 · **[앱]** Live Peninsula에서 시각 검증으로 수렴한 근사. Dynamic Island·genie·Siri 글로우처럼 Apple이 곡선을 공개하지 않은 동작은
"비슷하게 재현한 것"이라고 말하고, Apple의 값을 아는 척하지 않는다.


---

## 1. Apple 동작을 요청받으면

0. **정확히 같아야 하는 Apple 동작이면 레퍼런스부터.** 알람·타이머·볼륨 HUD처럼 기능마다 움직임이 다른 것은 기억으로 만들지 않는다 —
   카탈로그 맨 아래 "기능별" 표에 *미측정*으로 올라 있으면 사용자에게 녹화를 요청하고 [measurement.md](references/measurement.md)의 방법으로 잰다.
   (첫 버전의 "시스템 HUD"는 추측으로 만들어 "애플스럽지 못하다"는 평가를 받았다.)
1. **이름 붙이고 분해한다.** [catalog.md](references/catalog.md) 맨 위 표에서 찾는다. 없으면 재료로 쪼갠다 — 스프링 하나로 움직이는가?
   들어올 때와 나갈 때 박자가 다른가? 출발한 자리(앵커)가 있는가? 값이 흐르는가(이름 교체가 아니라)? 운동량이 있는가?
2. **Apple이 이미 해 주는지 먼저 본다.** 시스템 API가 있으면 그것을 쓴다 — 시트 detent, `glassEffectID`, `.navigationTransition(.zoom)`,
   `symbolEffect`, `numericText`, 스크롤 페이징. 직접 만든 것은 시스템과 박자가 어긋나는 순간 "구리다"가 된다 (P8).
   시트·탭 바·내비게이션·목록·팝오버·진행 표시처럼 **앱 구조 컴포넌트**는 [platforms.md §6](references/platforms.md)의 HIG 설정 규칙을 따른다.
   **어느 플랫폼인지** 먼저 정한다 — 같은 동작도 iPhone(터치), iPad(터치+포인터), Mac(포인터+키보드)에서 기대가 다르다 (P15).
3. **스프링을 고른다.** [springs.md §4](references/springs.md)의 질문 순서로 `Motion` 어휘를 고른다. 값이 의심되면 숫자를 짐작하지 말고
   `scripts/spring_probe.sh <response> <ζ>`로 오버슈트를 잰다.
   글자·컨트롤·여백·모서리 **크기**도 Apple 규격으로 정한다 — [metrics.md](references/metrics.md) (`.font(.body)` 같은 스타일, `.appleHitTarget()`, 동심 모서리).
4. **코드를 쓴다.** [recipes.md](references/recipes.md)에서 맞는 레시피를 찾아 출발점으로 삼고, **그 프로젝트의 코드 스타일·이름·구조에 맞게 필요한 부분만** 직접 쓴다.
   `assets/AppleMotion.swift`를 통째로 복사하지 않는다 — 그 파일은 레시피가 컴파일되는지 검사하는 용도다. 통째로 넣는 건 사용자가 원할 때만.
   프로젝트에 이미 비슷한 것(`Motion` 같은 이름표, 버튼 스타일)이 있으면 새로 만들지 말고 그것을 쓰거나 고친다.
   있으면 그것을 쓴다. 레시피 코드를 바꿀 때는 `recipes.md`를 고치고 `python3 scripts/build_asset.py --check`로 파일을 다시 만든다(문서와 파일이 어긋나지 않게).
5. **솔직하게 말한다.** 등급이 [앱]인 동작은 근사라고 밝힌다. 사용자가 "Apple 값"을 물으면 [SDK]로 측정한 값과 [앱] 근사를 구분해서 답한다.
6. **눈으로 확인한다.** 컴파일 통과는 보이는 모양을 보장하지 않는다. 시뮬레이터에서 녹화해 `filmstrip.sh`로 프레임을 펼쳐 보고,
   레퍼런스가 있으면 같은 도구로 재서 비교한다 — 이 스킬의 `Materialize`도 녹화해 보고서야 나갈 때 0.3초씩 번지는 결함을 찾았다.
7. **마감한다.** 동작 줄이기 대체, 연타·도중 잡기, 슬로모션 확인, §8 체크리스트. 연타해서 깨지는 것이 가장 흔한 결함이다.

---

## 2. Apple 공식 모션 원칙 (HIG)

[developer.apple.com/design/human-interface-guidelines/motion](https://developer.apple.com/design/human-interface-guidelines/motion) 내용을 요약한 것이다.

- **목적이 있어야 한다.** 모션은 경험을 돕되 가리지 않는다. 모션 자체가 목적이면 산만하고 불편을 준다.
- **선택 사항이어야 한다.** 중요한 정보를 모션만으로 전하지 않는다. 햅틱·소리로 보완한다.
- **현실적이어야 한다.** 제스처와 기대를 따라 움직인다. 비현실적인 움직임은 방향감각을 잃게 한다.
- **짧고 정확하게.** 가볍고 눈에 띄지 않는 애니메이션이 더 효과적이다.
- **잦은 상호작용에는 모션을 더하지 않는다.** 표준 요소는 시스템이 이미 은근한 움직임을 준다. 사람이 취소할 수 있게 하고, 반복되는 상호작용에서 기다리게 하지 않는다.
- **동작 줄이기를 켠 사람에게 [HIG Accessibility]:** 자동·반복 애니메이션(확대·축소·주변부 움직임)을 줄이고, **스프링의 되튐을 줄이고**, 애니메이션이 제스처를 직접 따라가게 하고,
  z축 깊이 변화를 애니메이션하지 않고, **x·y·z 이동 전환을 페이드로 바꾸고, 블러가 들어오고 나가는 애니메이션을 피한다.**
- **끊을 수 있게.** 애니메이션이 끝날 때까지 기다리게 하지 않는다 — 여러 번 겪는 애니메이션이면 더욱. (→ P4)
- **움직이는 심볼을 쓸 만한 곳에 쓴다.** SF Symbols 5+의 심볼 애니메이션(`symbolEffect`)이 직접 만든 회전·확대보다 먼저다.
- **입력에 따라 강도가 다르다.** Liquid Glass는 직접 터치하면 촉감을 살려 더 크게, 트랙패드로 조작하면 더 차분하게 반응한다. (→ P15)
- **빠르게 움직이거나 깜빡이는 애니메이션을 조심한다** [HIG Accessibility] — 어지럼증, 심하면 발작을 일으킬 수 있다. 끝없이 도는 글로우·메시는 느리고 옅게, 동작 줄이기에선 멈춘다.
- **시간 제한이 있는 요소를 줄인다** [HIG Accessibility] — 저절로 사라지는 HUD·토스트에 중요한 정보나 유일한 동작을 넣지 않는다.

---

## 3. 원칙 — Live Peninsula에서 굳은 규칙

### P1. 감쇠 1.0이 기본값. 탄성은 운동량이 있을 때만

`dampingFraction: 1.0`(오버슈트 없음)에서 시작한다. 되튐은 *손이 운동량을 만들었을 때*만 — 던졌다, 끌고 와서 닿았다.
- 상태가 바뀌었다는 **사실 자체**는 튀지 않아야 한다 → `settle`(1.0).
- **관성 없는 입력**(키 입력, 탭)에 오버슈트를 주면 과장돼 보인다 → `present`(1.0).
- 사용자가 직접 일으킨 모양 변화는 아주 옅게(0.82–0.86) — 0.68은 열림/닫힘(높이 38↔175)에서 오버슈트 5%대로 확 튀었고,
  0.85로 올리자 1% 아래로 떨어져 감속감만 남았다.
- 끌고 온 파일이 대상 위에 닿는 순간만 0.72처럼 되튄다 — 그 운동량이 실제로 있었기 때문이다.

### P2. 시작과 끝의 박자는 다르다

같은 곡선을 양쪽에 쓰면 어딘가가 굼뜨다.
- **누름 / 놓음**: 누르는 건 사용자가 방금 한 일이라 기다릴 이유가 없다 → `easeOut 0.07`. 돌아오는 건 손을 뗀 뒤의 일 → 스프링.
- **들어옴 / 나감**: 나갈 때를 빠르게(0.13) 잡으면 미련이 안 남는다. 컨테이너가 접히기 전에 내용이 이미 비어 있어야
  "빈 껍데기가 천천히 닫히거나 글자가 모서리에 깎이는" 일이 없다. 들어올 때는 반대 — 컨테이너가 먼저 벌어지고 내용이 `delay(0.08)`로 내려앉는다.
- **차오름 / 빠짐**(유리 같은 면): 차오를 땐 `easeOut 0.55`, 빠질 땐 `easeIn 0.4`.

### P3. 함께 움직이는 속성은 스프링 하나. 같은 일을 두 곳에서 애니메이션하지 않는다

너비·높이·모서리는 같은 `morph` 스프링을 쓴다 — 셋이 한 덩어리로 움직여야 모양이 따로 놀지 않는다.
한 움직임에 서로 다른 박자의 애니메이션 두 개가 겹치면 화면이 흔들려 보인다:
- 누르는 순간 컨테이너가 접히는데 버튼도 제자리에서 튕기면 → 버튼의 되튐을 뺀다(1.0).
- 네이티브 페이징 위에 수동 "도착 스프링"을 얹으면 → 하나만 남긴다. ("애니메이션이 구리다"의 정체였다.)

### P4. 끊을 수 있어야 한다 — 상태로 구동하고, 보이는 값에서 출발한다

`if isOpen { View().transition(...) }`는 삽입/제거 애니메이션이라 도중에 끊을 수 없다. 끝나기 전에 다시 누르면 제거와 삽입이
쌓이고, 큰 블러가 얹히면 메인 스레드가 밀려 멈춘다. 끊길 수 있는 곳(탭, 토글, 연타 대상)은:
- 뷰를 **항상 두고** `progress`/`isOn` 값으로 그린다. 스프링은 현재 값에서 목표만 바꿔 잡으므로 연타해도 이어진다.
- 키를 누르고 있어 새 목표가 계속 들어와도, 스프링은 현재 값·속도를 이어받아 끊김이 없다.
- 도중에 *잡을* 수 있다면 `@State`의 목표값이 아니라 **화면에 그려진 값**에서 출발한다(그렇지 않으면 순간이동).
- `.transition`은 끊길 일이 없는 곳에서만, 그리고 `asymmetric`으로 방향을 명시해서 쓴다.

### P5. 이름을 갈아 끼우지 말고 값을 흘려라

구간마다 심볼 이름을 바꾸면(`wave.1 → .2 → .3`) 바뀌는 순간 뚝 끊기고, 값이 경계에 머물면 깜빡인다.
`Image(systemName:variableValue:)`로 값에 따라 켜지게 하거나, 지원이 없으면 `Animatable` 값 하나를 애니메이션해
매 프레임 조각별 밝기를 계산한다(조각마다 `opacity`를 따로 걸면 전부 동시에 켜진다). 이때 스프링은 **감쇠 1.0** —
조각이 문턱을 넘나드는 순간 켜지고 꺼지므로 되튀면 문턱에서 깜빡인다.

### P6. 곡선은 *무엇이 움직이는가*로 고른다

| 움직이는 것 | 곡선 | 왜 |
| --- | --- | --- |
| 손으로 미는 물체 | spring | 물체는 관성이 있다 |
| 차오르는 **면**(유리, 물) | ease | 되튀면 물이 출렁이는 게 아니라 판이 튕긴 것처럼 보인다 |
| 시간이 흐르는 값(초 카운트다운) | **linear**(주기와 같은 길이) | 스프링은 초마다 출렁인다 |
| 텍스트/이미지 교체 | easeInOut 0.25–0.35 + `.opacity` | 움직이지 않고 밝기만 — 좁은 열에서 글자가 미끄러지면 잘린 것처럼 보인다 |

### P7. 손의 속도를 이어받는다 (드래그 → 애니메이션)

드래그와 애니메이션 사이에 이음매가 없어야 "손에 붙어 있다"가 된다. (코드: recipes §11)
1. 잡는 순간 **보이던 값**에서 출발 → 2. 끄는 동안 `Transaction(animation: nil)`로 1:1 →
3. 경계 밖은 러버밴딩 → 4. 속도는 `DragGesture`의 `velocity`가 아니라 **놓는 순간 직전 0.1초**로 직접 계산
(손이 멈춘 뒤에도 마지막 속도를 들고 있어서, 끌다 멈추고 한참 있다 놓아도 튕겨 나간다) →
5. 멈출 자리를 `현재 + (v/1000)·d/(1−d)`로 **투영**해 가장 가까운 목표로 →
6. `interpolatingSpring(initialVelocity:)`에 **남은 거리 대비 상대 속도**(`v ÷ (목표−현재)`)를 넘긴다 →
7. **튕겨 던졌을 때만** 감쇠 ~0.82, 살살 놓았으면 1.0.

### P8. 시스템이 하는 걸 다시 만들지 않는다

가로 페이지는 `ScrollView` + `.scrollTargetBehavior(.paging)` + `.scrollTransition(.interactive)`. 모멘텀 투영, 끝에서의
러버밴딩, 도중에 잡아 되돌리기를 시스템이 이미 한다. 특히 **macOS의 스와이프는 트랙패드 두 손가락 스크롤 이벤트라
`DragGesture`에 아예 안 잡힌다.** 숫자는 `.numericText`, 아이콘 교체는 `.symbolEffect(.replace)`.
직접 만든 것은 시스템 것과 박자가 어긋나는 순간 "구리다"가 된다.

### P9. 재질은 '도착'한다

단순 페이드는 "켜졌다"로 읽힌다. **출발한 자리(anchor)** 에서 블러 + 확대 + 이동 + 투명도를 함께 움직이면 "재질이 도착했다"로 읽힌다.
- 블러는 매 프레임 비용이다. 280pt 이미지의 블러가 연타에서 프레임을 먹었다 → 반경 6→3, 절반 지나면 끈다.
- SwiftUI `.blur`는 AppKit/UIKit이 그리는 재질(`NSVisualEffectView`, `NSGlassEffectView`, `UIVisualEffectView`)에는 걸리지 않는다 — 내용에만 건다.
- 글래스 위의 글자는 흐린 회색 대신 굵기·대비로 물러나게 한다 (바탕이 비칠 수 있다).

### P10. 움직임에 의미를 싣는다

- 멈춤은 오므라듦으로: 재생이 멈추면 앨범아트가 0.94로 오므라든다 — 글자 없이 상태가 읽히고 '멈춤'이 정보가 아니라 물체의 상태가 된다.
- 시간은 모양으로: 줄어드는 링(남은 양이 호의 길이로 보인다), 숫자를 읽지 않아도 된다.
- 종은 꼭대기에 매달려(`anchor: .top`) **진폭이 줄며** 흔들리고, 한 번 울린 뒤 **쉰다**. 같은 폭으로 계속 흔들면 기계가 떠는 것, 쉬지 않으면 소음.
- 상태가 뒤집히는 아이콘은 같은 자리에서 `symbolEffect(.replace)`, "여기가 맞다"는 `.bounce.down`.
- 비활성/일시정지는 `opacity 0.5`로 숨 참듯 어둡게 — 얼어붙은 것이 고장으로 읽히지 않게.

### P11. 동작 줄이기는 '끄기'가 아니라 '대체'

정보는 남기고 *움직임*만 바꾼다. 모션마다 대체를 설계한다.
- 스프링 → `easeOut 0.12–0.25` 페이드(`Motion.reduced`). 이동·확대·회전·블러 → 제거하고 투명도/밝기만.
- 회전하는 종 → 크기가 숨 쉬는 펄스. 알림 자체를 없애지 않는다.
- `symbolEffect(.bounce, value: reduceMotion ? 0 : count)`처럼 trigger 값을 고정해 끈다.
- HIG가 따로 짚는 것: **블러가 들어오고 나가는 애니메이션**, **x·y·z 이동 전환**(→ 페이드), **스프링 되튐**(→ 줄이기). `Materialize`는 동작 줄이기에서 블러·이동·확대를 모두 고정한다.
- `@Environment(\.accessibilityReduceMotion)`을 뷰마다 읽는다. 한 곳에서 처리하려면 recipes §2의 `.motion(_:value:)`.
- 함께: `\.accessibilityReduceTransparency`(반투명 → 불투명, 블러 제거), `\.colorSchemeContrast`(경계선 강화).

### P12. 입력 피드백은 즉시·연속·의미 있는 순간에만

- 누르는 **순간**에 반응한다(`isPressed`), 놓을 때가 아니다. 눌림은 `opacity`가 아니라 `brightness(-0.07)` + `scale(0.94–0.96)` —
  채운 알약에 투명도를 걸면 눌린 게 아니라 꺼진 것처럼 보인다.
- 포인터가 있는 플랫폼(macOS, 포인터 연결된 iPadOS)에서는 호버로 "여기다"를 먼저 알려 준다(`brightness +0.08`).
- 햅틱은 **눈금(detent)을 지날 때만** — 잡거나 놓는 순간엔 울리지 않는다. 큰 단위(5분)는 한 단계 굵게. 시각 변화와 같은 프레임에.
- 비활성 컨트롤은 `opacity 0.35`로 흐리게 — 눌러도 아무 일이 안 일어나는 것보다 낫다.
- 클릭 대상이 아닌 장식(후광 등)은 `allowsHitTesting(false)`.

### P13. 값은 한 곳에, 이유와 함께

같은 의도(상태 전환)에 response 0.3~0.6, damping 0.6~1.0이 흩어져 있으면 그게 곧 "일관성 없는 앱"이다. `Motion` 같은
enum에 *종류별 이름*으로 모으고, 상수마다 **왜 그 값인지** 한 줄을 단다. 기능 안에서만 쓰는 값도 `static let`으로
이름을 붙인다(`phaseSpring`, `LevelIconMotion.spring`). 새 애니메이션은 숫자를 고르는 게 아니라 이름을 고른다.

### P14. 재질은 층을 가른다 — 유리는 기능 층에만

Liquid Glass는 **콘텐츠 위에 떠 있는 기능 층**(툴바, 탭 바, 사이드바, 떠 있는 컨트롤)의 재질이다 [HIG Materials].
- 콘텐츠 층(배경, 카드, 목록)에는 유리 대신 **표준 재질**(`.regularMaterial` 등)을. 예외는 만지는 동안만 유리가 되는 슬라이더·토글.
- 커스텀 컨트롤에 유리는 **아껴서**. 여러 개가 다 유리면 콘텐츠를 보라는 유리의 목적이 사라진다.
- 바 아래에 단색·반투명 배경을 깔지 않는다 — 콘텐츠가 밑으로 흐르게 두고 **scroll edge effect**로 띄운다.
- **clear 유리는 사진·영상 위에서만**, 밝은 바탕이면 35% 딤. 글자가 많은 면(알림, 사이드바, 팝오버)은 regular.
- 재질은 **보이는 색이 아니라 의미로** 고른다 — 투명도 줄이기·대비 높이기·사용자의 유리 모양 설정에 따라 모습이 바뀐다.
코드: recipes §14 · §28. 상세: [platforms.md §5](references/platforms.md).

### P15. 플랫폼의 손에 맞춘다 — 같은 동작, 다른 입력

모션 곡선은 세 플랫폼에서 같다. 달라지는 것은 **무엇으로 만지느냐**이고, 그에 따라 피드백의 종류와 세기가 바뀐다 [HIG Pointing devices · Gestures · Playing haptics].
- **iPhone**: 손가락이 직접 누른다 → 눌림이 분명하게, 햅틱(iOS 패턴의 의미대로). 시스템 가장자리 제스처와 겹치는 드래그를 만들지 않는다.
- **iPad**: 터치 + **포인터** + 키보드를 섞어 쓴다 → 포인터 효과(highlight·lift·hover)를 단다. 대부분 햅틱 엔진이 없으니 시각이 먼저. 창 크기가 수시로 바뀐다.
- **Mac**: 포인터 + 키보드 → **호버로 먼저** 알리고 눌림은 한 단계 얌전하게. 의미가 정해진 시스템 커서. 햅틱은 드래그·포스 클릭 때만. 모든 명령은 메뉴 막대에도.
- 레이아웃은 기기 종류가 아니라 **실제 공간(size class)과 글자 크기**로 정한다. 바뀔 때는 뷰를 갈아 끼우지 말고 `AnyLayout`으로 자리를 흘린다 (P5와 같은 이유).
코드: recipes §24(포인터) · §25(햅틱 의미) · §27(레이아웃). 상세: [platforms.md §1–4](references/platforms.md).

---

## 4. 모션 어휘

recipes §1의 `Motion` enum과 같은 표다. **Apple 프리셋 이름**으로 쓰고, 각 값의 오버슈트·정착 시간은
[springs.md](references/springs.md)에 측정해 두었다. (`.snappy(duration: 0.42)`는 `.spring(response: 0.42, dampingFraction: 0.85)`와 곡선이 비트 단위로 같다 [SDK].)

| 이름 | Apple 표기 | 쓰임 |
| --- | --- | --- |
| `settle` | `.smooth(duration: 0.30)` | 상태 전환: 토글, 면 나타남/사라짐, 호버, 드롭 상태 |
| `present` | `.smooth(duration: 0.38)` | 관성 없는 입력으로 뜨는 HUD·카드 |
| `morph` | `.snappy(duration: 0.42)` | 사용자가 일으킨 크기·모서리·펼침 (여러 속성이 같은 스프링) |
| `lift` | `.spring(duration: 0.35, bounce: 0.28)` | 끌고 온 운동량이 남은 것: 드롭 대상 위 도착 |
| `flick` | `interpolatingSpring` + 초기 속도, ζ 0.82 (bounce 0.18) | 던진 뒤 내려앉음 (살살 놓으면 ζ 1.0) |
| `pressDown` | `.easeOut(duration: 0.07)` | 누르는 순간 |
| `pressRelease` | `.smooth(duration: 0.26)` | 놓은 뒤 복귀 (탄성이 필요하면 bounce 0.38까지 — 겹치는 움직임이 없을 때만) |
| `exit` | `.easeIn(duration: 0.13)` · `.linear(0.05–0.20)` | 나감. 컨테이너보다 빠르게 |
| `enterAfter` | `.spring(duration: 0.42, bounce: 0.16)` + `.delay(0.08)` | 컨테이너가 벌어진 뒤 내용이 내려앉음 (`contentDrop`) |
| `swap` | `.easeInOut(duration: 0.28)` | 텍스트·이미지 교체 (`.contentTransition(.opacity)`) |
| `roll` | `.smooth(duration: 0.30)` | 숫자 굴러감 (`.numericText`) |
| `tick` | `.linear(duration: 1)` (갱신 주기와 같은 길이) | 초 단위로 갱신되는 값 |
| `fill` | `.easeOut(0.55)` 들어올 때 / `.easeIn(0.40)` 나갈 때 | 차오르는 면 (유리) |
| `reduced` | `.easeOut(duration: 0.2)` | 모든 모션의 동작 줄이기 대체 |

> 이 코드베이스의 오래된 부분엔 0.7~0.8 감쇠가 흔하다(P1 이전에 쓴 값). 규칙은 *나중에 이유를 달아 고친* 쪽을 따른다.
> 기존 코드를 고칠 때 전부 갈아엎지 말고, 손대는 애니메이션만 어휘로 옮긴다.

---

## 5. 도구 고르기

| 하고 싶은 것 | 쓸 것 | 메모 |
| --- | --- | --- |
| 값이 바뀔 때 부드럽게 | `.animation(curve, value:)` | **그 modifier 위쪽**에 붙은 속성에 적용된다. 애니메이션할 것 *뒤*에 둔다 |
| 이벤트 핸들러에서 여러 상태를 한꺼번에 | `withAnimation(curve) { ... }` | |
| 타이머 콜백처럼 `withAnimation` 밖에서 바뀌는 값 | 보는 쪽에 `.animation(curve, value:)` | 값을 바꾸는 쪽이 아니라 보는 쪽에서 걸어야 전환이 돈다 |
| 드래그 중 즉시 반영 | `withTransaction(Transaction(animation: nil))` | 1:1 |
| 한 자리만 다른 곡선 | `.transaction(value:) { $0.animation = ... }` | 잠금 상태에서만 linear, 그 외엔 건드리지 않기 등 |
| 숫자 | `.contentTransition(.numericText(countsDown:))` + `.monospacedDigit()` | 자릿수 변화에서 좌우로 떨리지 않게 |
| 아이콘 상태 뒤집기 | `.contentTransition(.symbolEffect(.replace))` | iOS 18 / macOS 15는 `.replace.magic(fallback:)` — `#available` 가드 |
| 일회성 강조 | `.symbolEffect(.bounce.down, value: count)` | 동작 줄이기에선 value 고정 |
| 연속 값 → 여러 조각 | `Animatable` + `Canvas` | recipes §7 |
| 등장/접힘 진행도 | `Animatable` `ViewModifier`(progress 0→1), 뷰는 항상 마운트 | recipes §6 |
| 페이지 넘김 | `.scrollTargetBehavior(.paging)` + `.scrollTransition(.interactive)` | recipes §12 |
| 손 속도를 이은 착지 | `.interpolatingSpring(mass:stiffness:damping:initialVelocity:)` | `.spring()`에는 시작 속도 인자가 없다 |
| 뷰 삽입/제거 | `.transition(.asymmetric(...))` | 끊길 일 없는 곳에서만 |
| 매 프레임 갱신 | `TimelineView(.animation(minimumInterval:))` | 진행바는 30fps로도 충분했다 |
| 반복/지연 작업 | `.task { while !Task.isCancelled { ... } }` | `DispatchQueue` 재귀는 뷰가 사라져도 계속 돈다 |
| 매 프레임 바뀌는 값을 관찰 | 관찰 범위를 modifier **안으로** 가둔다 | 바깥에서 관찰하면 프레임마다 카드 전체가 다시 그려진다 |
| Liquid Glass가 합쳐지고 갈라짐 | `GlassEffectContainer` + `.glassEffectID(_:in:)` + `withAnimation(Motion.morph)` | recipes §14. 가까운 유리는 반드시 컨테이너로 묶는다 |
| 앱이 열리듯 커지는 전환 | `.matchedTransitionSource` + `.navigationTransition(.zoom(sourceID:in:))` | recipes §21. iOS 18 |
| 한 번 "톡" | `keyframeAnimator(initialValue:trigger:)` + `SpringKeyframe` | recipes §16 |
| 애니메이션이 끝난 시점에 뭔가 하기 | `withAnimation(_, completionCriteria: .logicallyComplete) { } completion: { }` | `asyncAfter`로 시간을 짐작하지 않는다. 체감 시간이 끝난 시점 |
| 내용이 바뀔 때 흐림과 함께 교체 | `.transition(.blurReplace)` | recipes §17 |
| 아이콘이 톡·깜빡·흔들 | `.symbolEffect(.bounce / .pulse / .variableColor / .wiggle …)` | recipes §15. 직접 회전시키기 전에 먼저 찾는다 |
| 끝없이 도는 빛·메시 | `repeatForever`를 **서로 다른 주기**로, `reduceMotion`이면 정지 | recipes §19·§20 |
| iPad 포인터가 올라옴 | `.hoverEffect(.highlight / .lift)` + `.contentShape(.hoverEffect, 모양)` | recipes §24. macOS는 `.onHover` 밝기 |
| 시트 크기·닫기 | `.presentationDetents` · `.presentationDragIndicator(.visible)` · `.interactiveDismissDisabled(변경 있음)` | recipes §26. 시트 드래그를 직접 만들지 않는다 |
| 큰 글자·좁은 창에서 배치 전환 | `AnyLayout(HStackLayout / VStackLayout)` + `.motion(Motion.settle, value:)` | recipes §27. `if`로 스택을 갈아 끼우지 않는다 |
| 툴바 아래 콘텐츠 구분 | `.scrollEdgeEffectStyle(.soft, for: .top)` (iOS 26 / macOS 26) | recipes §28. 배경색을 깔지 않는다 |
| 핵심 동작 하나를 강조 | `.buttonStyle(.glassProminent)` (26) · 그 아래는 `.borderedProminent` | 하나만, trailing |
| 입력 거절 | `.rejectShake(trigger:)` (`keyframeAnimator`) + `Haptics.play(meaning: .failure)` | recipes §29 |
| 목록 삽입·삭제·이동 | 데이터를 `withAnimation`으로 바꾸고 `onDelete`·`onMove` | 행마다 `.transition`을 달지 않는다 |

---

## 6. 플랫폼 차이

모션 규칙은 세 플랫폼에서 같다. 다른 건 **입력 수단**과 **햅틱**, **공간**, 그리고 최소 OS 버전이다 (P15). HIG 근거와 컴포넌트별 규칙은 [platforms.md](references/platforms.md).

| | iOS | iPadOS | macOS |
| --- | --- | --- | --- |
| 입력 | 손가락, 직접 조작 | 손가락 + 포인터 + 키보드 | 포인터·트랙패드 |
| 호버 | 없음 (`.onHover`는 호출 안 될 뿐 해롭지 않다) | 포인터 연결 시 `.onHover` / `.hoverEffect` | **필수** — 누르기 전에 "여기다"를 알려야 한다 |
| 가로 스와이프 | `DragGesture`·스크롤 모두 | 같음 | 두 손가락 스와이프는 *스크롤 이벤트* → `DragGesture`에 안 잡힘. `ScrollView` 페이징을 쓴다 |
| 햅틱 | `.sensoryFeedback`(17+) 또는 `UIFeedbackGenerator` | 대부분 햅틱 엔진 없음 — 보조 수단으로만 | `.sensoryFeedback`은 컴파일되지만 대부분 **무음**(이 프로젝트에서 확인). `NSHapticFeedbackManager` (recipes §13) |
| 크기 | 화면 고정 | Split View·Stage Manager로 가변 — 고정 pt 가정 금지 | 창 리사이즈 |
| 누름 스케일 | 0.94–0.97 | 같음 | 같음 + 호버 밝기 |
| 포인터 효과 | — | highlight(투명 배경 작은 요소) · lift(불투명 작은 요소) · hover(큰 요소, 크기 대신 틴트) — recipes §24 | 호버 밝기 + 시스템 커서(`.pointerStyle`, macOS 15+) |
| 햅틱 의미 | notification(결과) · impact(딸깍·충돌) · selection(값 변화) | 대부분 없음 | alignment · levelChange · generic, **드래그·포스 클릭 때만** — recipes §25 |
| 레이아웃 판단 | size class + 글자 크기 | size class(창이 수시로 바뀜) + 글자 크기 | size class 없음 — 창 너비(`ViewThatFits`) + 글자 크기 |
| 모달 | 시트 medium detent + grabber, 스와이프로 닫기 | page/form 시트, 모달·전체 화면 전환을 줄인다 | 고정 크기 시트, 반복 입력은 패널. 다른 창은 계속 쓸 수 있게 |
| 팝오버 | compact에선 쓰지 않음 → 시트 | 넓을 때만 | 패널로 떼어 낼 수 있게 |
| 배치 주의 | 자주 쓰는 컨트롤은 손이 닿는 아래·가운데 | 창 컨트롤이 leading 툴바 버튼을 가리지 않게 | 창 맨 아래·노치 뒤에 중요한 것 금지. 모든 명령은 메뉴 막대에도 |
| Liquid Glass 반응 | 직접 터치 — 강하게 | 터치는 강하게, 포인터는 차분하게 | 트랙패드 — 차분하게 |

**최소 OS**(레시피 타입체크로 확인한 하한): `.numericText`, `.smooth`, `.symbolEffect`, `scrollTransition`, `.transaction(value:)`,
`scrollTargetBehavior` → **iOS 17 / macOS 14**. `Image(systemName:variableValue:)` → iOS 16 / macOS 13.
`.replace.magic` → iOS 18 / macOS 15 (`#available`로 가드). 그 아래를 지원해야 하면 해당 modifier만 `#available`로 감싸고
`.opacity` 전환으로 떨어뜨린다.

공통 코드는 `#if os(macOS)` / `#elseif canImport(UIKit)`로 가른다 (`Haptics` 참고). 모션 곡선과 `Motion` enum은 갈릴 일이 없다.

---

## 7. 증상 → 원인 → 고침

| 증상 | 원인 | 고침 |
| --- | --- | --- |
| 열고 닫을 때 확 튄다 | 감쇠 0.68 → 오버슈트 5% | 0.85 (오버슈트 <1%) |
| 키를 누르고 있으면 아이콘이 깜빡인다 | 값 구간마다 심볼 이름 교체 | `variableValue` / `Animatable` + 감쇠 1.0 |
| 컨테이너가 접히는데 글자가 모서리에 깎인다 | 내용이 컨테이너보다 늦게 사라짐 | 나가는 쪽을 컨테이너보다 빠르게(0.13) |
| 스와이프 애니메이션이 구리다 | 네이티브 페이징 + 수동 settle 스프링이 다른 박자로 겹침 | 하나만 남긴다 |
| 한참 멈췄다 놓았는데 튕겨 나간다 | `DragGesture.velocity`가 마지막 이동 속도를 유지 | 놓는 순간 직전 0.1초로 직접 계산 |
| 한창 움직이는 눈금을 잡으면 순간이동 | 목표값에서 출발 | 그려지는 값을 기록해 거기서 출발 |
| 연타하면 UI가 멈춘다 | `.transition` 삽입/제거 겹침 + 큰 블러 | 상태 구동(항상 마운트) + 블러 얕게 |
| 초마다 눈금/링이 출렁인다 | 카운트다운에 스프링 | `linear(1)` |
| 눌러도 반응이 굼뜨다 | 누름/놓음에 같은 곡선 | 누름 `easeOut 0.07` / 놓음 스프링 |
| 눌린 버튼이 눌린 게 아니라 꺼진 것 같다 | `opacity`로 눌림 표현 | `brightness(-0.07)` |
| 두 자리로 넘어갈 때 숫자가 떨린다 | 고정폭 아님 | `.monospacedDigit()` |
| 좁은 열에서 글자가 슬라이드하며 잘린다 | `move` 전환 | `.contentTransition(.opacity)` |
| 투명하게 숨긴 뷰가 호버·드롭을 계속 가로챈다 | `opacity 0`은 hit-test를 끄지 않는다 | `allowsHitTesting(!hidden)`을 함께 건다 |
| 뷰가 사라졌는데 애니메이션이 계속 돈다 | `DispatchQueue.asyncAfter` 자기 호출 | `.task` (자동 취소) |
| 프레임마다 카드 전체가 다시 그려진다 | 바깥에서 매 프레임 값을 관찰 | 관찰을 modifier 안으로 |
| macOS에서 햅틱이 안 느껴진다 | `.sensoryFeedback`이 맥에서 무음 | `NSHapticFeedbackManager` |
| 동작 줄이기를 켰는데 여전히 움직인다 | 곡선만 바꾸고 변환(offset/scale)은 그대로 | 변환 값 자체를 0/1로 고정 |
| iPad에서 포인터를 올려도 아무 반응이 없다 | 커스텀 버튼에 포인터 효과가 없음 | `.hoverEffect(.highlight / .lift)` (recipes §24) |
| 바 버튼 사이를 지날 때 포인터가 깜빡인다 | 터치 영역 사이에 틈 | 터치 영역을 이어 붙인다 |
| 표 행에 호버하면 옆 행과 겹친다 | 붙은 요소에 크기 키우기 | 틴트만 (`.hover`) |
| 글자를 키우면 줄이 잘리거나 겹친다 | 고정 높이·가로 배치 | `AnyLayout`으로 세로 전환, 행 높이 자동 (recipes §27) |
| 레이아웃이 바뀔 때 뚝 끊긴다 | `if`로 HStack/VStack 교체 | `AnyLayout` + 같은 스프링 |
| 툴바 밑이 탁하고 무겁다 | 툴바에 배경색·블러를 직접 깔았다 | 배경을 빼고 scroll edge effect (recipes §28) |
| 화면이 온통 유리라 산만하다 | 콘텐츠 층·여러 커스텀 컨트롤에 유리 | 유리는 기능 층에만, 콘텐츠는 표준 재질 (P14) |
| 시트를 끌어 닫았더니 작성 중이던 게 날아갔다 | 저장 안 한 변경을 보호하지 않음 | `interactiveDismissDisabled(변경 있음)` + 확인 (recipes §26) |
| 시트 드래그가 시스템과 미묘하게 다르다 | 시트를 직접 만들었다 | `presentationDetents`로 시스템 시트 (P8) |
| 팝오버 크기가 바뀌는 순간 다른 창처럼 보인다 | 크기를 애니메이션하지 않음 | `Motion.morph`로 크기 변화 (catalog 25) |
| 눌렀는데 아무 일이 없어 고장 난 것 같다 | 거절·비활성을 보여 주지 않음 | 비활성은 처음부터 흐리게, 거절은 `rejectShake` (recipes §29) |
| 로딩 중 멈춘 것 같다 | 표시기가 멈춰 있거나 스피너↔막대 전환 | 계속 움직이는 표시기, 확정형으로 (catalog 24) |
| HUD가 읽기 전에 사라진다 | 시간 제한 요소에 중요한 정보 | 중요한 건 화면에 남기고, VoiceOver 땐 더 오래 (platforms §7) |

---

## 8. 마감 체크리스트

코드를 쓰거나 리뷰할 때 이것만 훑어도 대부분 걸러진다.

- [ ] 이 움직임이 전하는 정보를 한 줄로 말할 수 있다.
- [ ] 곡선이 §4 어휘에서 왔고, 새 숫자라면 이유가 주석으로 있다.
- [ ] 상태 전환·관성 없는 입력은 감쇠 1.0. 탄성이 있다면 *운동량의 출처*가 있다.
- [ ] 누름/놓음, 들어옴/나감의 박자가 다르다.
- [ ] 함께 움직이는 속성이 같은 스프링 하나를 쓴다. 같은 일을 애니메이션하는 곳이 두 곳이 아니다.
- [ ] 연타해도, 도중에 잡아도 깨지지 않는다 (상태 구동, 보이는 값에서 출발).
- [ ] 값이 구간으로 끊기지 않고 흐른다 (`variableValue`/`Animatable`/`numericText`).
- [ ] 드래그는 1:1, 놓는 속도를 이어받고, 경계는 러버밴딩.
- [ ] 시스템이 하는 것(시트 detent·페이징·numericText·symbolEffect·glassEffectID·zoom 전환)을 다시 만들지 않았다.
- [ ] 잦은 상호작용(키를 누르고 있음)에는 모션을 더하지 않았다 — 값만 흐르고 등장은 한 번.
- [ ] [Apple]과 [앱] 근사를 구분해서 말했다. 비공개 구현을 아는 척하지 않았다.
- [ ] 동작 줄이기에서 정보가 남는다 (변환 제거, 페이드/밝기 대체). 반투명·대비 설정도 봤다.
- [ ] 햅틱은 의미 있는 순간(눈금)만, 시각 변화와 같은 프레임. macOS는 `NSHapticFeedbackManager`.
- [ ] 큰 블러는 짧고 얕다. 매 프레임 값의 관찰 범위를 좁혔다.
- [ ] 글자는 의미 있는 스타일(`.font(.body)` 등)이거나 Apple 스타일 크기에 맞췄고, 글자에 최소 크기(iOS 11 / macOS 10pt) 이하를 쓰지 않았다.
- [ ] 컨트롤의 터치 영역이 규격(iOS 44 / macOS 28pt, 최소 28 / 20)을 채운다. 중첩된 둥근 도형은 동심(`바깥 − 여백`)이다.
- [ ] 반복 작업은 `.task`. 장식은 `allowsHitTesting(false)`. 접근성 라벨/값이 붙었다.
- [ ] **대상 플랫폼마다** 확인했다: iPhone은 터치·햅틱, iPad는 포인터 효과·가변 창, Mac은 호버·커서·메뉴 막대 (P15).
- [ ] 시스템 컴포넌트(시트·탭 바·내비게이션·목록·팝오버)는 직접 만들지 않고 HIG대로 설정했다 ([platforms.md §6](references/platforms.md)).
- [ ] Liquid Glass는 기능 층에만, 아껴서. 콘텐츠 층은 표준 재질. 바 밑에 배경색을 깔지 않았다 (P14).
- [ ] 햅틱은 HIG 패턴의 **의미대로** 썼고, 표준 컨트롤에 겹쳐 울리지 않는다. 끌 수 있고, 없어도 앱이 온전하다.
- [ ] 가장 큰 글자 크기와 가장 작은·가장 큰 창에서 레이아웃이 깨지지 않고, 바뀔 때 자리가 흐른다.
- [ ] 안 되는 동작은 안 된다고 보인다(비활성 흐림, 거절 흔들림). 저절로 사라지는 요소에 중요한 정보가 없다.

### 기존 코드 감사

```bash
# 쓰인 곡선 종류와 빈도 — 같은 의도에 값이 흩어져 있는지 본다
grep -rhoE '\.(spring|smooth|snappy|easeInOut|easeOut|easeIn|linear)\([^)]*\)' --include='*.swift' . | sort | uniq -c | sort -rn | head -30

# 애니메이션은 있는데 동작 줄이기를 한 번도 안 읽는 파일
comm -23 <(grep -rlE --include='*.swift' 'withAnimation|\.animation\(' . | sort) <(grep -rl --include='*.swift' 'accessibilityReduceMotion' . | sort)
```
