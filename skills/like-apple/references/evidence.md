# 근거 — 규칙이 어디서 나왔나

이 스킬은 Live Peninsula(macOS 노치 앱)를 개발하며 만들어졌다. `SKILL.md`의 규칙은 Live Peninsula의 실제 코드와, 그 코드 주석에 남은 "예전엔 이랬는데 이래서 고쳤다"에서
뽑았다. 아래 표는 규칙 → 출처 파일이다. 줄 번호는 코드가 바뀌면 어긋나므로 파일·심볼 이름만 적는다.
규칙의 수치가 의심스러우면 해당 파일의 주석을 먼저 읽는다 — 이유가 거기 있다.

| 규칙 | 출처 (Dynamic-Notch/Dynamic-Notch/…) | 거기 남은 이유 |
| --- | --- | --- |
| P1 감쇠 1.0 기본 | `ContentView.swift` (노치 폭·높이 스프링), `Views/Tray/TrayPlaceholder.swift` (`stateSpring` vs `liftSpring`), `Views/HUD/HotkeyStatusHUDView.swift` (`motion`), `Views/LockScreen/LockScreenMusicView.swift` (`presentMotion` vs `expandMotion`) | 0.68은 열림/닫힘에서 오버슈트 5%대로 튀었고 0.85에서 1% 아래. 키 입력엔 관성이 없다. 끌고 온 파일만 되튄다. 재생 시작엔 관성이 없지만 펼침은 사용자가 건드려 일으킨 변화라 옅게. |
| P2 비대칭 박자 | `ContentView.swift` (`NotchHUDButtonStyle`, `timerLiveActivity`, 유리 `.animation`), `Views/Studio/Timer/TimerView.swift` (`TimerControlButtonStyle`) | 누르는 건 방금 한 일이라 즉시. 나가는 줄을 노치보다 빠르게 비우지 않으면 빈 껍데기가 닫히고 글자가 깎임. 유리는 나갈 때를 빠르게 해야 미련이 없음. |
| P3 한 덩어리 · 두 박자 금지 | `ContentView.swift` (폭·높이·모서리 같은 스프링, `NotchHUDButtonStyle`의 되튐 제거), `Views/Studio/StudioPlaceholder.swift` (네이티브 페이징 주석) | 버튼이 튕기는 동안 노치가 접히면 서로 다른 박자가 겹쳐 화면이 흔들려 보임. 페이징 위의 수동 settle 스프링이 "구리다"의 정체였음. |
| P4 상태 구동 · 보이는 값에서 출발 | `Views/LockScreen/LockScreenMusicView.swift` (`GenieModifier`, `albumArt` 주석), `Views/Studio/Timer/TimerRuler.swift` (`Scrub.origin`, `ScrubRecorder.position`) | `.transition`은 도중에 끊을 수 없어 연타 시 삽입/제거가 쌓이고 280pt 블러와 겹쳐 멈춤. 한창일 때 눈금을 잡으면 목표에서 출발해 순간이동. |
| P5 값을 흘린다 | `System Features/SystemHUD/LevelIcons.swift` (`VolumeLevelIcon`, `SunGlyph`, `LevelIconMotion`) | 구간별 심볼 교체는 뚝 끊기고 키를 누르고 있으면 경계에서 깜빡임. 광선별 opacity는 8개가 동시에 켜짐 → `Animatable` 값 하나. 감쇠 1.0이어야 문턱에서 안 깜빡임. |
| P6 곡선은 움직이는 것으로 | `Views/Studio/Timer/TimerCountdownRing.swift`, `Views/Studio/Timer/TimerRuler.swift` (`.transaction(value:)`), `ContentView.swift` (유리 ease 주석), `Views/Studio/Calendar/SwipeableDateSelector.swift` (월 `.opacity`) | 초마다 스프링을 걸면 눈금이 출렁임. 유리는 물체가 아니라 차오르는 면이라 되튀면 판이 튕긴 것처럼 보임. 좁은 열에서 글자가 미끄러지면 잘려 보임. |
| P7 손의 속도 | `Views/Studio/Timer/TimerRuler.swift` (`scrubGesture`, `settle`, `Self.project`, `rubberBand`, `ScrubRecorder`) | `DragGesture.velocity`는 멈춘 뒤에도 마지막 속도를 들고 있음. `v²/2a`가 아니라 스크롤이 쓰는 지수 감쇠. 살살 놓은 것이 넘쳤다 돌아오면 흔들림. |
| P8 시스템에 맡긴다 | `Views/Studio/StudioPlaceholder.swift` (`.paging`, `PageDepth`), `Views/Studio/Calendar/SwipeableDateSelector.swift` (`tick` 주석) | macOS 스와이프는 스크롤 이벤트라 `DragGesture`에 안 잡힘. `sensoryFeedback`은 맥에서 대부분 무음. |
| P9 재질이 도착 | `Views/HUD/HotkeyStatusHUDView.swift`, `Views/LockScreen/LockScreenMusicView.swift` (`GenieModifier`의 블러 6→3) | 단순 페이드가 아니라 blur+scale을 같이 움직여야 "재질이 도착". 큰 블러는 프레임 드랍. AppKit이 그리는 재질에는 `.blur`가 안 걸림. |
| P10 의미를 싣는 움직임 | `Views/Studio/StudioPlaceholder.swift` (`artScale`, 멈추면 오므라듦), `Views/Studio/Timer/BellShakeView.swift`, `Views/Studio/Timer/TimerCountdownRing.swift`, `Views/Tray/TrayPlaceholder.swift` (`.bounce.down`) | 멈춤이 정보가 아니라 물체의 상태로 읽힘. 종은 꼭대기에 매달려 진폭이 줄며 흔들리고 쉼. 줄어드는 링은 읽지 않아도 남은 양이 보임. |
| P11 동작 줄이기 = 대체 | 거의 모든 뷰 (`reduceMotion` 54곳), 특히 `BellShakeView.swift` (`pulseOnce`), `LevelIcons.swift` (`LevelIconMotion.reduced`), `PageDepth` | 알림 자체를 없애지 않고 어지럽지 않은 방식으로 바꿈. |
| P12 입력 피드백 | `ContentView.swift` (`NotchHUDButtonStyle`), `Views/Studio/Timer/TimerView.swift`, `TimerRuler.swift` (`sensoryFeedback` 눈금), `SwipeableDateSelector.swift` (`NSHapticFeedbackManager`) | 채운 알약에 opacity를 걸면 꺼진 것처럼 보임 → brightness. 5분 눈금은 `levelChange`로 한 단계 굵게. |
| P13 값은 한 곳에 | `Models/Sizes/Size.swift` (`LiveActivityMetrics`, `NotchCardMetrics`), `LevelIcons.swift` (`LevelIconMotion`), `TimerView.swift` (`phaseSpring`) | 치수는 한 곳에서 모여 있고 상수마다 근거 주석이 있음. 반면 곡선은 아직 흩어져 있다(아래). |

## Apple 동작 재현의 출처 (카탈로그 14·15번)

| 레시피 | 출처 (Dynamic-Notch/Dynamic-Notch/…) | 거기서 가져온 것 |
| --- | --- | --- |
| `CometStroke` · `glow` | `Animation/Hello/HelloShape.swift` (`GlowingSnake`, `glow`) | 머리·꼬리를 `trim`으로 자르는 `Animatable` 진행 값 하나, 세 겹 블러 글로우. 원본의 구간식(`progress > 1 − delay` …)은 꼬리 > 0.5에서 끊겨서 `max(0, p − tail, 2p − 1)` 한 식으로 이었다 |
| `RotatingGlowBorder` | `Animation/GradientAnimation.swift` | 큰 그라디언트를 `linear(4s).repeatForever`로 돌리고 노치 테두리로 마스크. 원본은 동작 줄이기를 읽지 않고 고정 크기라서, 대각선 길이·`reduceMotion` 정지를 더했다 |
| `LivingMesh` | `Animation/ripple_mesh.swift` | `MeshGradient`의 점·색을 1.5s / 2.2s / 1.8s로 따로 `repeatForever` — 주기가 어긋나 유기적으로 보이는 요령 |
| 순서 연출(참고) | `Animation/firstLaunchView.swift` | 메시 3초 → 노치 확장 + hello 4.5초 → 복귀. 원본은 `DispatchQueue.asyncAfter` 연쇄라 뷰가 사라져도 계속 돈다 — 새로 만들 땐 `.task` 순차 `Task.sleep`이나 `completionCriteria`로 |

## Apple 공식 자료와 SDK 측정

| 내용 | 출처 | 신뢰 수준 |
| --- | --- | --- |
| 프리셋 smooth/snappy/bouncy와 "기본은 bounce 0, 놀이감·물리감일 때만 bounce", 속도 이어받기, 체감 시간 vs 정착 시간 | WWDC23 "Animate with springs" (developer.apple.com/videos/play/wwdc2023/10158) | 요약본을 읽음. 감쇠 변환식은 요약이 깨져 쓰지 않고 SDK로 대체. 큰 bounce의 임계(≈0.4)는 영상으로 재확인 필요 |
| 줌 전환, 제스처 중 `.interactiveSpring` 속도 이어받기 | WWDC24 "Enhance your UI animations and transitions" (…/wwdc2024/10145) | 요약본을 읽음. 요약이 준 API 이름 `navigationTransitionStyle`은 틀렸고, 실제 `.navigationTransition(.zoom)`은 컴파일로 확인 |
| `glassEffect`, `GlassEffectContainer`, `glassEffectID(_:in:)` | WWDC25 "Build a SwiftUI app with the new design" (…/wwdc2025/323) | 요약본 + 컴파일로 API 이름 확인(macOS 26 / iOS 26). `.interactive()`의 시각 효과는 확인 못 함 |
| 모션 HIG 5원칙 | developer.apple.com/design/human-interface-guidelines/motion | 데이터 엔드포인트로 본문을 읽음(처음 시도한 일반 페이지는 JS라 본문이 없어 버림) |
| 프리셋의 bounce·감쇠비, 길이 지정 시 감쇠비 유지, 변환식, 오버슈트·정착 시간 | 이 맥의 SwiftUI `Spring` 구조체로 직접 측정 (`scripts/spring_probe.sh`) | **[SDK]** 가장 믿을 만함 |

## 평가에서 알게 된 것 (1회차, 3케이스 × 스킬 유무)

- 스킬 없이도 시트 수정은 같은 구조(항상 마운트·offset·그려진 값 기록·상대 속도·러버밴딩)를 스스로 구현했다. 일반 원칙은 모델이 이미 알고 있다.
- 갈린 곳은 두 군데였다: HUD 등장에 탄성을 준 것, macOS 햅틱을 `sensoryFeedback`에만 맡긴 것. **이 스킬의 가치는 일반 원칙보다 Apple 동작의 구체적 재현과 플랫폼 함정에 있다** — 그래서 카탈로그·측정 도구 중심으로 다시 짰다.

## 아직 어휘로 안 옮겨진 곳

2026-10-07 기준 코드베이스의 곡선 리터럴을 세어 보면 `.spring(response: 0.4, dampingFraction: 0.8)`이 15번,
`0.3/0.7`이 10번, 그 밖에 0.2~0.62 × 0.6~1.0 조합이 수십 가지다. 이 값들은 대부분 P1의 근거 주석이 생기기 전에 쓴 것이다.
`SKILL.md` §7의 감사 명령으로 다시 세어 볼 수 있다. 같은 날 `accessibilityReduceMotion`을 읽지 않으면서 애니메이션을 쓰는
파일이 25개 나왔다(대부분 `*Manager`의 `withAnimation`이라 뷰 쪽에서 처리하면 되는 경우도 있어 전부 결함은 아니다).

기존 코드에서 손대는 애니메이션만 어휘로 옮기고, 한꺼번에 갈아엎지 않는다.

## 사용자 피드백과 측정으로 알게 된 것 (2회차)

- 사용자가 시뮬레이터에서 "시스템 HUD"를 보고 **"애플스럽지 못하다"**고 평가했다. 녹화·프레임 분석 결과: 흰 바탕에 안 보이는 연한 알약, 점선처럼 읽히는 16개의 점,
  들어올 때·나갈 때 같은 0.3초 블러 디졸브. **Apple의 실제 HUD를 본 적 없이 이 앱의 노치 HUD를 일반화해 "시스템 HUD"라고 불렀던 것이 원인**이다. 카탈로그 4번을 바로잡고 "기능별(미측정)" 표를 만들었다.
- `Materialize`가 P2("나갈 땐 더 빠르게")를 스스로 어기고 있었다 — 녹화로만 드러났다. 고치기 전 사라짐 10%→90% 0.172s → 고친 후 0.071s(같은 도구로 측정). 다만 세 프레임에 뚝 사라지는 것이 Apple다운지는 확인하지 못했다.
- 사용자는 알람·타이머처럼 **기능마다 다른 Apple 애니메이션**이 반영되길 원한다. 일반 모션 규칙으로는 이를 만들 수 없고, 기능별 레퍼런스 측정이 필요하다.
- 측정 도구(`scripts/`)는 정답을 아는 녹화로 검증했다 — 정확도와 한계는 [measurement.md](measurement.md).

## 치수 문서의 출처 (metrics.md)

| 내용 | 출처 | 확인 |
| --- | --- | --- |
| 텍스트 스타일 크기·줄 간격·강조 굵기, 기본·최소 글자 크기, 굵기 지침, "시스템 폰트가 자간을 자동 조정" | HIG Typography (데이터 엔드포인트로 본문 읽음) | **크기 22개는 SDK로 일치 확인**(macOS `NSFont`, iOS 시뮬레이터 `UIFont`). 줄 간격은 HIG 값만 |
| 컨트롤 기본·최소 크기, 베젤 있음/없음 여백(12 / 24pt), 대비 비율, Dynamic Type 200%, 동작 줄이기 세부 | HIG Accessibility | HIG 본문만(SDK로 확인할 수 없는 규격) |
| 안전 영역, macOS 카메라 하우징·창 아래쪽 주의 | HIG Layout | HIG 본문만 |
| `ConcentricRectangle`, `ContainerRelativeShape`, `containerShape` | SDK | 컴파일로 존재 확인(macOS 26 / iOS 26) |
| 이 앱의 글자 크기 감사 | `.font(.system(size:))` 정규식(주석 제외) | 휴리스틱. 처음엔 주석 처리된 코드를 세어 숫자가 틀렸고(20곳→14곳) 검산해 바로잡았다 |
| HIG에서 얻지 못한 것 | 트래킹 표(요약에 없음), 기기별 화면 크기·모서리 반경 숫자 | 기억으로 채우지 않았다 |

## 새 카탈로그 비교 평가 (2회차, 4케이스 × 스킬 유무, 시뮬레이터 녹화 포함)

- 통과율 41/41 대 38/41. 기준선이 놓친 건 ① 섬 카드에서 근사임을 밝히지 않음 ② 시계 타이머에서 실제 동작을 재현한 게 아님을 밝히지 않음 ③ 섬 카드 펼침의 큰 탄성(논란, 아래).
- **기준선이 이미 하던 것:** 동심 모서리(36→24→18), 44pt 터치 영역, 섬 카드의 "나갈 땐 빠르게·들어올 땐 지연", `TimelineView` 링, `GlassEffectContainer`+`glassEffectID`. 일반 원칙과 Apple 공식 API는 스킬이 없어도 안다.
- **스킬의 실제 변별점은 정직성**: "Apple이 곡선을 공개하지 않았다/시계 타이머는 측정한 적이 없다"고 밝히는 행동. 그리고 화면에서 위젯 크기·레이아웃이 깨지지 않은 정도(기준선 위젯은 카드가 화면 전체로 늘어남).
- 비용은 토큰 약 2배. 평가 기준에 Apple 실물 레퍼런스가 없어 "애플스러운가"는 이 비교로 알 수 없다 — 레퍼런스 녹화가 다음 단계다.

