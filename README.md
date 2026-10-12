# Like Apple — Claude Skill

**한국어** · [English](README.en.md)

**iOS · iPadOS · macOS 앱을 "Apple이 만든 것처럼" 움직이고 느껴지게 만드는 Claude 스킬.**
SwiftUI 애니메이션, 크기(베젤·둥근 모서리·글자), 플랫폼 관례를 Apple Human Interface Guidelines를 근거로 맞춥니다.

> A Claude skill that makes native iOS, iPadOS and macOS apps look, move and feel like Apple made them —
> Apple-style SwiftUI animation, sizing and platform behavior grounded in the Human Interface Guidelines.
>
> Written in Korean; Claude reads it fine in any language you talk to it in.

## 만든 배경 — Live Peninsula

이 스킬은 macOS 노치 앱 **Live Peninsula**를 혼자 개발하며 쌓은 결과물입니다.
애플스러운 애니메이션, 둥근 베젤과 동심 모서리, 시스템처럼 조용히 정확한 움직임이라는 철학을 지키려고
노치가 열리고 닫히는 스프링, 키 입력 HUD, 트레이로 끌어 온 파일, 잠금 화면 음악 카드, 타이머 눈금 같은 기능을 만들고 고치며
"예전엔 이랬는데 이래서 고쳤다"를 반복했습니다. 그 규칙들을 Apple HIG와 SDK 측정으로 검증하고 일반화한 것이 이 스킬입니다.

## 설치 (Claude Code)

두 가지 방법 중 하나를 고르세요.

### 방법 1. 간단 설치 — `/like-apple`

```bash
git clone https://github.com/HoYeonPark1221/like-apple.git
cp -R like-apple/skills/like-apple ~/.claude/skills/
```

사용법:

```
/like-apple 참고해서 만들어줘
```

업데이트는 `like-apple` 폴더에서 `git pull` 한 뒤 위의 `cp` 명령을 다시 실행합니다.

### 방법 2. 플러그인 설치 — 업데이트가 편함

```bash
claude plugin marketplace add HoYeonPark1221/like-apple
claude plugin install like-apple@like-apple
```

사용법:

```
/like-apple:like-apple 참고해서 만들어줘
```

플러그인으로 설치한 스킬은 이름 앞에 플러그인 이름이 붙습니다. 업데이트는 한 줄이면 됩니다.

```bash
claude plugin update like-apple@like-apple
```

## 들어 있는 것

| | 내용 |
| --- | --- |
| **원칙 15개** | 감쇠 1.0이 기본, 시작과 끝의 박자는 다르다, 끊을 수 있어야 한다, 손의 속도를 이어받는다, 재질은 층을 가른다, 플랫폼의 손에 맞춘다 … |
| **동작 카탈로그 25개** | Dynamic Island, 알약 HUD, genie, Liquid Glass 합쳐짐, Siri 글로우, 줌 전환, 숫자 굴러감, 타이머 링, 시트, 포인터 효과, 거절 흔들림 … — 근거 등급([Apple] · [HIG] · [SDK] · [앱])과 함께 |
| **코드 레시피 29개** | 바로 쓸 수 있는 SwiftUI 코드. iOS 17/26 · macOS 14/26 × Swift 5/6에서 컴파일 검증. 프로젝트에는 필요한 부분만, 그 코드 스타일에 맞춰 들어갑니다 |
| **플랫폼 HIG** | iPhone(터치)·iPad(터치+포인터)·Mac(포인터+키보드)의 입력·햅틱·레이아웃·재질 차이, 시트·탭 바·툴바·팝오버·알림·목록·진행 표시 규칙 |
| **치수** | Apple 글자 크기(SDK 검증), 컨트롤·베젤 규격, 동심 모서리 |
| **측정 도구** | 레퍼런스 녹화를 프레임으로 펼치고, 움직임을 추적해 스프링 값을 맞추는 스크립트 |

## 요구 사항

- Claude Code (스킬 자체는 어떤 환경에서도 읽힘)
- `scripts/`의 측정·검증 도구는 **macOS + Xcode**가 필요합니다.
- 범위는 iOS · iPadOS · macOS 앱입니다. 웹사이트, watchOS, visionOS, tvOS는 다루지 않습니다.

## 고지

Apple과 관계없는 개인 프로젝트입니다. Apple, iOS, iPadOS, macOS, Liquid Glass, Dynamic Island, SF Symbols는 Apple Inc.의 상표입니다.
HIG 내용은 원문을 요약·인용 출처와 함께 정리한 것이며, 최신 규칙은 [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)를 확인하세요.

## 라이선스

MIT © HoYeon Park
