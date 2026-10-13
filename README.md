# Like Apple — Claude Skill

```
/like-apple 참고해서 만들어줘
```

**한국어** · [English](README.en.md)

**iOS · iPadOS · macOS 앱을 "Apple이 만든 것처럼" 움직이고 느껴지게 만드는 Claude 스킬.**
SwiftUI 애니메이션, 크기(베젤·둥근 모서리·글자), 플랫폼 관례를 Apple Human Interface Guidelines를 근거로 맞춥니다.

> A Claude skill that makes native iOS, iPadOS and macOS apps look, move and feel like Apple made them —
> Apple-style SwiftUI animation, sizing and platform behavior grounded in the Human Interface Guidelines.
>
> Works in any language you talk to Claude in.

## 1. 만든 배경 — Live Peninsula

[**Live Peninsula**](https://www.live-peninsula.com)는 Mac의 노치를 음악, 타이머, 파일 트레이, 볼륨·밝기 표시가 사는 공간으로 바꾸는 앱입니다.
혼자 만들면서 기준은 처음부터 하나였습니다. **"Apple이 만든 것처럼 보일 것."**

그 기준은 생각보다 훨씬 작은 숫자에서 갈렸습니다. 같은 스프링이라도 소수점 둘째 자리가 바뀌면 "고급스럽다"가 "싸 보인다"로 바뀝니다.
그래서 값 하나도 감으로 두지 않고, 바꿀 때마다 **왜 바꿨는지**를 코드 주석에 남겼습니다. 아래는 실제 Live Peninsula 코드입니다.

### 1.1 노치가 열릴 때 "확 튀던" 문제 — 0.68 → 0.85

처음에는 노치가 열리고 닫힐 때(높이 38pt ↔ 175pt) 스프링의 감쇠값을 `0.68`로 두었습니다. 탄력 있어 보일 줄 알았는데,
실제로는 목표보다 **5.4%** 더 튀어 올랐다가 돌아오면서 "출렁인다"는 느낌을 줬습니다. 값을 하나씩 올리며 곡선을 직접 측정했고, `0.85`에서 답을 찾았습니다.

```swift
// 이전: 열고 닫을 때마다 목표를 5.4% 넘었다가 돌아온다
.animation(.spring(response: 0.42, dampingFraction: 0.68), value: calculateNotchHeight())

// 지금: 넘치는 양이 0.6% — 튕김은 사라지고 부드럽게 멈추는 느낌만 남는다
.animation(.spring(response: 0.42, dampingFraction: 0.85), value: calculateNotchHeight())
```

폭·높이·모서리는 모두 **같은 스프링 하나**로 움직입니다. 셋이 따로 움직이면 모양이 찌그러져 보이기 때문입니다.

### 1.2 열릴 때와 닫힐 때는 박자가 다르다

노치 뒤의 유리 효과는 열릴 때와 닫힐 때 **다른 곡선**을 씁니다. 차오를 때는 천천히 퍼지고(0.55초), 빠질 때는 더 빨리 사라집니다(0.4초).
나갈 때를 빠르게 잡아야 화면에 미련이 남지 않습니다.

```swift
vm.notchState == .on ? .easeOut(duration: 0.55) : .easeIn(duration: 0.4)
```

여기서 스프링이 아니라 ease를 쓴 것도 이유가 있습니다. 유리는 손으로 미는 물체가 아니라 **차오르는 면**이라서, 튕기면 물이 출렁이는 게 아니라 판이 흔들리는 것처럼 보였습니다.

타이머 알림도 같은 원리입니다. 들어올 때는 노치가 먼저 벌어진 뒤 **0.08초 늦게** 내용이 내려앉고, 나갈 때는 노치가 접히기 전에 **0.13초 만에** 먼저 비웁니다.
반대로 하면 글자가 접히는 모서리에 깎여 보였습니다.

```swift
insertion: .opacity.combined(with: .offset(y: -10)).animation(.spring(response: 0.42, dampingFraction: 0.84).delay(0.08)),
removal:   .opacity.combined(with: .offset(y: -6)).animation(.easeIn(duration: 0.13))
```

### 1.3 누르는 순간과 손을 떼는 순간

버튼은 누르는 순간 **0.07초** 만에 반응하고, 손을 떼면 튕기지 않고 돌아옵니다. 처음에는 돌아올 때 튕김(0.62)을 넣었는데,
버튼을 누르는 순간 노치가 접히기 시작해서 두 움직임이 서로 다른 박자로 겹쳤고, 화면 전체가 흔들리는 것처럼 보였습니다.

```swift
configuration.isPressed ? .easeOut(duration: 0.07) : .spring(response: 0.22, dampingFraction: 1.0)
```

눌림은 투명도가 아니라 **밝기**로 표현합니다. 색이 채워진 버튼에 투명도를 걸면 눌린 게 아니라 꺼진 것처럼 보이기 때문입니다.

---

이런 "예전엔 이랬는데, 이래서 고쳤다"가 Live Peninsula 코드 곳곳에 쌓였습니다.
**like-apple은 그 기록을 Apple 디자인 가이드라인(HIG)과 Xcode에서의 실측으로 다시 검증하고, 다른 iOS · iPadOS · macOS 앱에도 쓸 수 있게 정리한 스킬입니다.**
이제 Claude가 애니메이션을 만들 때도 같은 기준으로 값을 고릅니다.

## 2. 설치 (Claude Code)

### 2.1 플러그인 설치 (추천) — 자동 업데이트

```bash
claude plugin marketplace add HoYeonPark1221/like-apple
claude plugin install like-apple@like-apple
```

**자동 업데이트 켜기** — 한 번만 하면 새 버전이 나올 때마다 알아서 받습니다.

1. Claude Code에서 `/plugin` 입력
2. **Marketplaces** → **like-apple** 선택
3. **Enable auto-update** 선택

사용법:

```
/like-apple:like-apple 참고해서 만들어줘
```

플러그인으로 설치한 스킬은 이름 앞에 플러그인 이름이 붙습니다. 자동 업데이트를 켜지 않았다면 이 명령으로 직접 받으면 됩니다.

```bash
claude plugin update like-apple@like-apple
```

### 2.2 간단 설치 — `/like-apple`

```bash
git clone https://github.com/HoYeonPark1221/like-apple.git
cp -R like-apple/skills/like-apple ~/.claude/skills/
```

사용법:

```
/like-apple 참고해서 만들어줘
```

이 방법은 자동 업데이트가 되지 않습니다. 새 버전은 `like-apple` 폴더에서 `git pull` 한 뒤 위의 `cp` 명령을 다시 실행해서 받습니다.

## 3. 들어 있는 것

### 3.1 원칙 15개 — Claude가 애니메이션을 만들 때 지키는 규칙

애니메이션을 만들거나 고칠 때마다 Claude가 확인하는 기준입니다. 대부분 Live Peninsula를 고치면서 얻은 것입니다. 몇 가지를 풀어 쓰면:

- **기본은 튕기지 않는다.** 튕김은 사용자가 무언가를 던졌을 때처럼 힘이 실렸을 때만 씁니다.
- **누를 때는 즉시, 놓을 때는 부드럽게.** 들어올 때와 나갈 때도 박자를 다르게 잡습니다.
- **언제든 멈출 수 있어야 한다.** 연타하거나 움직이는 도중에 잡아도 깨지지 않아야 합니다.
- **손의 속도를 이어받는다.** 드래그하다 놓으면 그 속도 그대로 이어서 자연스럽게 멈춥니다.
- **Apple이 이미 만든 건 다시 만들지 않는다.** 시트나 페이지 넘김처럼 시스템이 주는 움직임을 그대로 씁니다.
- **기기마다 손이 다르다.** iPhone은 손가락, iPad는 손가락과 포인터, Mac은 마우스와 키보드에 맞춥니다.

### 3.2 동작 카탈로그 25개 — "○○처럼 해줘"에 대한 답

Apple 기기에서 자주 보는 움직임을 **어떤 재료로 만드는지** 분해해 둔 목록입니다. 예를 들어 "Dynamic Island처럼"이라고 하면,
Claude는 "폭·높이·모서리를 스프링 하나로 함께 키우고, 안의 내용은 바깥보다 먼저 사라지게 한다"는 분해와 코드에서 출발합니다.

들어 있는 움직임의 예:
- iPhone 위쪽의 **Dynamic Island**가 커졌다 줄어드는 움직임
- 볼륨을 바꿀 때 뜨는 **작은 알약 모양 표시**
- iOS 26의 **Liquid Glass** 버튼들이 물방울처럼 합쳐지고 갈라지는 효과
- 사진을 누르면 그 자리에서 **커지며 열리는 화면**
- 숫자가 바뀔 때 **굴러가듯** 바뀌는 효과, 남은 시간이 줄어드는 **타이머 링**
- 아래에서 올라오는 **시트**, iPad에서 포인터를 올렸을 때의 반응
- 틀린 암호를 넣었을 때처럼 **좌우로 흔들리며 거절**하는 표시

각 항목에는 **얼마나 믿을 수 있는지**가 표시되어 있습니다. Apple이 공식으로 제공하는 기능인지, Apple 디자인 가이드라인에 적힌 내용인지,
Live Peninsula에서 눈으로 맞춘 근사치인지를 구분합니다. Apple이 값을 공개하지 않은 움직임은 Claude가 "근사치"라고 밝히고 만듭니다.

### 3.3 코드 레시피 29개 — 바로 쓸 수 있는 SwiftUI 코드

버튼 눌림, 드래그해서 놓기, 햅틱, 시트 설정 같은 코드를 미리 만들어 두었습니다.
모든 레시피는 iOS 17·26, macOS 14·26에서 Swift 5와 Swift 6 모두로 **실제로 빌드되는지 확인**했습니다.
사용자 프로젝트에는 파일을 통째로 넣지 않고, **필요한 부분만 그 프로젝트의 코드 스타일에 맞춰** 들어갑니다.

### 3.4 기기별 규칙 — iPhone, iPad, Mac은 다르게 만진다

같은 버튼도 기기마다 기대하는 반응이 다릅니다. Apple 디자인 가이드라인(HIG)을 기준으로 정리했습니다.
- **iPhone** — 손가락으로 직접 누르니 반응이 분명해야 하고, 진동(햅틱)을 의미에 맞게 씁니다.
- **iPad** — 손가락과 포인터를 같이 쓰니, 포인터를 올렸을 때도 반응해야 합니다. 창 크기도 수시로 바뀝니다.
- **Mac** — 누르기 전에 마우스를 올리면 먼저 반응하고, 모든 기능을 메뉴 막대와 단축키로도 쓸 수 있어야 합니다.

시트, 탭 바, 툴바, 팝오버, 알림, 목록, 로딩 표시를 Apple답게 쓰는 규칙도 들어 있습니다.

### 3.5 크기 규격 — 글자, 버튼, 둥근 모서리

움직임이 좋아도 크기가 어긋나면 Apple답지 않습니다.
- **글자 크기** — iPhone 본문 17pt, Mac 본문 13pt처럼 기기별 기준 크기(Xcode에서 직접 꺼내 확인)
- **버튼 크기** — 손가락으로 누르기 편한 최소 크기(iPhone 44pt, Mac 28pt)와 주변 여백
- **둥근 모서리** — 안쪽 모서리는 바깥 모서리에서 여백만큼 작게 해야 어긋나 보이지 않습니다(동심 모서리)

### 3.6 측정 도구 — 움직임을 눈이 아니라 숫자로 재기

"이 움직임과 똑같이"를 감으로 맞추지 않기 위한 도구입니다.
Apple 기기 화면을 녹화한 영상을 **프레임 단위로 펼쳐 보고**, 물체의 위치를 **추적해서**, 그 움직임을 만드는 **스프링 값을 계산**합니다.
스프링 값을 넣으면 얼마나 튕기고 언제 멈추는지 바로 알려 주는 스크립트도 있습니다. (macOS + Xcode 필요)

## 4. 지원 범위와 계획

- **지금 지원:** iOS · iPadOS · macOS 앱
- **앞으로:** visionOS, watchOS 등 다른 Apple 플랫폼으로 넓혀 갈 예정입니다.
- Claude Code에서 씁니다. `scripts/`의 측정·검증 도구는 macOS와 Xcode가 필요합니다.

## 5. 고지

Apple과 관계없는 개인 프로젝트입니다. Apple, iOS, iPadOS, macOS, Liquid Glass, Dynamic Island, SF Symbols는 Apple Inc.의 상표입니다.
HIG 내용은 원문을 요약·인용 출처와 함께 정리한 것이며, 최신 규칙은 [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)를 확인하세요.

## 6. 라이선스

MIT © HoYeon Park
