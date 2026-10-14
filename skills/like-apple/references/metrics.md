# Sizes — type, controls (bezels), spacing and corners

Motion can be perfectly Apple-like and still feel off if **sizes drift from Apple's specs.** This collects the specs for type, controls, spacing and corners.
Code: recipes §22–23 (`AppleMetrics`, `.appleHitTarget()`, `ConcentricCardExample`).

Grades: **[HIG]** Apple Human Interface Guidelines text · **[SDK]** measured directly on the SDK.

## 1. Type

### Semantic text styles (default content size)

All 22 point sizes match between the HIG table and **SDK measurements** [HIG][SDK]. Leading values are from the HIG and weren't checked separately on the SDK.

| Style | iOS · iPadOS size / leading | macOS size / leading | Default weight → emphasized |
| --- | --- | --- | --- |
| Large Title | 34 / 41 | 26 / 32 | Regular → Bold |
| Title 1 | 28 / 34 | 22 / 26 | Regular → Bold |
| Title 2 | 22 / 28 | 17 / 22 | Regular → Bold |
| Title 3 | 20 / 25 | 15 / 20 | Regular → Semibold |
| Headline | 17 / 22 (Semibold) | 13 / 16 (Bold) | iOS Semibold → Semibold · macOS Bold → Heavy |
| Body | 17 / 22 | 13 / 16 | Regular → Semibold |
| Callout | 16 / 21 | 12 / 15 | Regular → Semibold |
| Subheadline | 15 / 20 | 11 / 14 | Regular → Semibold |
| Footnote | 13 / 18 | 10 / 13 | Regular → Semibold |
| Caption 1 | 12 / 16 | 10 / 13 | Regular → iOS Semibold · macOS Medium |
| Caption 2 | 11 / 13 | 10 / 13 (Medium) | Regular → Semibold |

**The same style name has different sizes on iOS and macOS** (body 17 vs 13). Semantic styles like `.font(.body)` give each platform the right size;
hard-coding `.system(size: 17)` is too large on the Mac. Styles also grow with Dynamic Type; hard-coded sizes don't.

### Default and minimum text size [HIG]

| Platform | Default | Minimum |
| --- | --- | --- |
| iOS · iPadOS | 17pt | 11pt |
| macOS | 13pt | 10pt |

### Weight, leading, tracking

- **Weight [HIG]:** avoid Ultralight, Thin and Light; use Regular, Medium, Semibold, Bold. Emphasize with weight (it costs less space than size).
- **Leading [HIG]:** looser for wide columns and long text, tighter in tight spaces (but not for three or more lines). Larger text gets proportionally tighter leading.
  Build hierarchy from **weight + size + leading together**, not size alone.
- **Tracking:** Apple's **system font adjusts tracking automatically at every size** [HIG]. Don't add `.tracking()` to the system font by default —
  it stacks on top of the built-in correction. Use it only for non-system fonts or a deliberate, justified adjustment.
- **System font by default** [HIG]: optical sizing, tracking tables and legibility tuning are built in.
- **Dynamic Type [HIG]:** let people enlarge text to **at least 200%**. Scale text-bound dimensions (icon widths etc.) with `@ScaledMetric`.
- **Contrast [HIG]:** 4.5:1 for text up to 17pt, 3:1 for 18pt or bold (WCAG AA).
- **Text on translucent materials:** raise contrast and step the weight up instead of using faint gray — faint gray disappears on glass. Recede with weight, not lightness.
  Put color on an opaque layer, not on the translucent face.
- **Larger surfaces get heavier treatment:** a large HUD or sheet gets a stronger shadow and material than a small chip.

## 2. Controls and bezels [HIG Accessibility]

A "bezel" is a control's **visible background or border**. Apple's control sizes and the space around them:

| Platform | Default control size | Minimum control size |
| --- | --- | --- |
| iOS · iPadOS | **44 × 44pt** | 28 × 28pt |
| macOS | **28 × 28pt** | 20 × 20pt |

- **Spacing:** about **12pt** around controls with a bezel; about **24pt** from the visible edge of bezel-less controls (text or icon only).
- Even when the visible icon is small, **the hit area meets the spec** — `.appleHitTarget()`. Growing the visual and growing the hit area are separate things.
- **iPad pointer:** make the hit areas of bar buttons **contiguous** — a gap makes the pointer flicker back to its default shape between them [HIG Pointing devices].

## 3. Corners, concentricity, safe areas

- **Continuous curvature:** rounded corners use `RoundedRectangle(cornerRadius:style: .continuous)` — Apple's smooth corner, not a circular arc. Every recipe here does.
- **Concentric corners:** for nested rounded shapes, inner radius = **outer radius − inset**. Equal radii open a wider gap at the corners and look misaligned.
  On iOS 26 / macOS 26, `ConcentricRectangle` reads the `containerShape` and computes the inner radius for you [SDK compile-checked] (recipes §23).
  Standard toolbar buttons, fields and headers are already concentric with the bar's corners; make custom ones concentric too [HIG Toolbars].
- **Screen (device) corner radius:** no public numeric API. Don't hard-code it; use `ContainerRelativeShape` / `ConcentricRectangle`.
- **Safe areas and the notch [HIG Layout]:** the safe area is what hardware (including the Dynamic Island) and system UI don't cover. Read notch and Island sizes at runtime instead of hard-coding them —
  on the Mac, `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea` and `safeAreaInsets`.
- **Clear Liquid Glass** over bright content gets a **35% black dimming layer** [HIG Materials].

## 4. Order for deciding sizes

1. **Start from semantic styles.** `.font(.body)` `.headline` `.footnote` — platform sizes and Dynamic Type come with them.
2. Where a fixed size is unavoidable (fixed-height chrome like a notch or HUD), snap to **the nearest whole Apple style size** (macOS: 10 · 11 · 12 · 13 · 15 · 17 · 22 · 26). Avoid half points.
3. **Never go below the minimum for text** (iOS 11 / macOS 10pt). This doesn't apply to icon sizes.
4. Icon-only controls fill their hit area with `.appleHitTarget()`. Leave 12 / 24pt around them depending on whether they have a bezel.
5. Nested rounded shapes use `outer − inset` (concentric). Device corners use `ContainerRelativeShape` / `ConcentricRectangle`.
6. Text on translucent surfaces gets more weight and contrast; check 4.5:1 for small text.
7. Check sizes at **large Dynamic Type and with Reduce Motion** too — layouts usually break where sizes are hard-coded.
