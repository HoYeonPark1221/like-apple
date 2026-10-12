# Apple의 스프링 — 숫자를 외우지 말고 구조를 이해하기

근거 표기: **[SDK]** 이 맥의 SwiftUI에서 직접 측정 · **[WWDC]** Apple 세션 내용 · **[앱]** Live Peninsula에서 시각으로 수렴한 값(Apple 공개값 아님).

## 1. Apple의 스프링은 두 숫자로 말한다

| 표기 | 의미 | 쓰는 곳 |
| --- | --- | --- |
| `duration`, `bounce` | 체감 길이(초), 되튐의 양 | `.spring(duration:bounce:)`, `.smooth` `.snappy` `.bouncy` |
| `response`, `dampingRatio` | 위와 같은 것의 다른 이름 | `.spring(response:dampingFraction:)` |

**[SDK] 둘은 같은 스프링이다:** `duration = response`, `bounce = 1 − dampingRatio`
(예: ζ 0.85 ↔ bounce 0.15, ζ 0.72 ↔ bounce 0.28). 곡선을 비교하면 최대 차이가 0.0이다.
질량·강성·감쇠로 직접 만들어야 할 때(`interpolatingSpring`)는 **mass = 1, stiffness = (2π ÷ response)², damping = 2 · ζ · √stiffness**
— **[SDK]** 위 식으로 만든 스프링이 `Spring(response:dampingRatio:)`와 초기 속도를 줘도 완전히 일치함을 확인했다.

`duration`은 **체감 길이**이지 완전히 멈추는 시간이 아니다 — 스프링은 지수적으로 줄어드는 꼬리가 있다 **[WWDC]**.
화면 변화의 타이밍을 맞출 때는 시간을 짐작하지 말고 `completionCriteria: .logicallyComplete`를 쓴다(recipes §17).

## 2. Apple 프리셋 — SDK에서 읽은 값

| 프리셋 | bounce | 감쇠비 ζ | 오버슈트 | 1% 안에 정착 | 성격 |
| --- | --- | --- | --- | --- | --- |
| `.smooth` | 0 | 1.00 | 0% | 0.53s | 범용. 되튐 없음 |
| `.snappy` | 0.15 | 0.85 | 0.6% | 0.35s | 경쾌하되 튕기진 않음 |
| `.bouncy` | 0.30 | 0.70 | 4.6% | 0.52s | 눈에 띄게 출렁임 |

위는 세 프리셋의 기본 길이(0.5s)에서 측정했다 [SDK]. 길이를 바꿔도 감쇠비는 유지된다 — `.snappy(duration: 0.42)`는
`.spring(response: 0.42, dampingFraction: 0.85)`와 곡선이 **비트 단위로 같다** [SDK].

**Apple의 사용 지침 [WWDC23 "Animate with springs"]:** 기본은 bounce 0. 놀이감 있게 하고 싶을 때, 제스처 끝처럼 물리적으로
느껴져야 할 때, 에너지를 더하고 싶을 때만 bounce를 올린다. 큰 bounce는 UI에서 과장되기 쉬우니 조심하라고 한다
(정확한 임계는 세션 영상으로 다시 확인할 것). 앱의 성격(진지함/장난기)에 맞춰 일관되게 쓴다.

## 3. 이 앱의 어휘 ↔ Apple 프리셋

이 앱이 시행착오 끝에 도달한 값이 Apple의 프리셋 이름과 겹친다 [SDK/앱]. 그래서 `Motion` enum은 Apple 이름으로 쓰여 있다.

| `Motion` | Apple 대응 | response | ζ | bounce | 오버슈트 | 1% 정착 |
| --- | --- | --- | --- | --- | --- | --- |
| `settle` | `.smooth(duration: 0.30)` | 0.30 | 1.00 | 0 | 0.0% | 0.32s |
| `present` | `.smooth(duration: 0.38)` | 0.38 | 1.00 | 0 | 0.0% | 0.40s |
| `pressRelease` | `.smooth(duration: 0.26)` | 0.26 | 1.00 | 0 | 0.0% | 0.27s |
| `morph` | `.snappy(duration: 0.42)` | 0.42 | 0.85 | 0.15 | 0.6% | 0.30s |
| flick 착지 | `.spring(duration: 0.42, bounce: 0.18)` | 0.42 | 0.82 | 0.18 | 1.1% | 0.40s |
| `lift` | `.bouncy`보다 살짝 조용 | 0.35 | 0.72 | 0.28 | 3.8% | 0.37s |

참고로 문제였던 값들 [SDK 측정]:

| 값 | 오버슈트 | 결과 |
| --- | --- | --- |
| response 0.42, ζ **0.68** (예전 노치) | **5.4%** | 열림/닫힘(높이 38↔175)에서 "확 튄다"로 읽힘 |
| response 0.50, ζ **0.50** (엉성한 시트) | **16.3%** | 장난감처럼 출렁임, 연타하면 흔들림이 겹침 |
| response 0.18, ζ 0.50 (종 "맞는 순간") | 16.3% | 짧아서(0.25s) 괜찮음 — 크지만 순간이라 흔들림으로 안 읽힘 |
| response 0.40, ζ 0.80 (이 코드베이스의 옛 기본값) | 1.5% | 무난하지만 의도 없는 숫자 |

**오버슈트를 눈으로 읽는 법 [앱]:** 1% 아래는 "튕김 없음, 감속감만", 3~5%는 "눈에 띄는 탄성", 10% 이상은 "장난감".

## 4. 어떤 스프링을 고를까

1. 손이 운동량을 줬는가(던졌다, 끌고 와서 닿았다)? **아니오** → 되튐 없는 `.smooth`.
2. 사용자가 직접 일으킨 모양 변화(펼침, 크기, 모서리)인가? → `.snappy`(0.85) — 감속감은 있고 튕김은 없다.
3. 운동량이 있고 놀이감이 어울리는가? → bounce 0.2~0.3 (`.bouncy`보다 조용하게).
4. 시간이 흐르는 값(초 카운트다운)인가? → 스프링이 아니라 linear.
5. 차오르는 면(유리)인가? → ease.

## 5. 속도·끊기

- **[WWDC23]** 스프링은 제스처 끝의 속도를 이어받고, 애니메이션이 끝나기 전에 새 애니메이션이 시작되면 현재 속도에서 새 목표로 이어진다.
  그래서 목표만 바꿔 주는 것(상태 구동)이 끊을 수 있는 애니메이션의 기본이다.
- **[WWDC24]** 제스처가 값을 계속 바꿀 때는 `.interactiveSpring`을 쓰면 각 변화가 이전 애니메이션을 이어받아 속도가 끊기지 않는다.
- 손을 뗀 속도를 *직접* 넘겨야 하면 `.interpolatingSpring(…, initialVelocity:)` — 값은 **남은 거리 대비 상대 속도**다 (recipes §11).

## 6. 직접 재 보기

값을 정하기 전에 곡선을 측정한다. 추측으로 0.68을 쓰면 5%가 튀는 것처럼, 숫자는 눈으로 짐작하기 어렵다.

```bash
scripts/spring_probe.sh 0.42 0.85        # response, dampingRatio → 오버슈트·정착 시간·Apple 표기
scripts/spring_probe.sh 0.42 0.82 1.5    # 세 번째 인자: 시작 속도(남은 거리 대비)
```
