# Platforms — how motion and feel differ on iOS · iPadOS · macOS

Motion that's right on one platform can feel wrong on another: a Mac button with no hover, an iPad control that ignores the pointer.
This collects only the HIG guidance that changes **how things move or feel** on each platform. Code: [recipes.md](recipes.md). Sizes: [metrics.md](metrics.md).

Grades: **[HIG]** Apple Human Interface Guidelines (page named) · **[SDK]** typechecked on the SDK.
Scope: iOS, iPadOS and macOS.

---

## 1. Three platforms, three hands [HIG Designing for iOS · iPadOS · macOS]

| | iOS | iPadOS | macOS |
| --- | --- | --- | --- |
| Input | Multi-Touch, direct | touch + keyboard + pointer + Apple Pencil, **mixed** | keyboard + mouse/trackpad |
| Window | fixed screen | resizes freely (multitasking) | resizable windows, multiple displays |
| What motion must respect | one-handed gestures (edge-swipe back, row swipes) | pointer effects; window size changes constantly — never assume fixed points | hover before click; smooth active/inactive window transitions |

**Liquid Glass responds differently by input** [HIG Motion]: strongly to direct touch, to feel tactile, and more calmly to a trackpad.
Custom motion follows the same idea — a clear press response where a finger touches the screen directly, one step calmer where a pointer clicks.

---

## 2. Rules by input

### Touch (iOS · iPadOS) [HIG Gestures]
- **Standard gestures keep standard meanings.** Tap activates or selects, swipe reveals or dismisses or scrolls, drag moves, long-press reveals more. Don't attach app-specific actions to familiar gestures.
- **Don't collide with system gestures.** No custom drags that start at a screen edge (back, Home, Notification Center, Control Center).
- **Respond during the gesture**, and show what will happen (how far is left to go). → P7, recipes §11
- **Show when a gesture isn't available.** Dragging a locked object should visibly resist; no response at all reads as a frozen app. → catalog 19
- A custom gesture must **never be the only way** — the same action works from a button, a menu or the keyboard.

### Pointer (iPadOS · macOS) [HIG Pointing devices]
- **iPadOS pointer effects:** small element on a transparent background → highlight; small opaque element → lift; large element → hover (tint, scale, shadow you choose).
  Highlight and lift have **magnetism** that pulls the pointer to the center; hover doesn't — a pointer that keeps its shape and still gets pulled feels like losing control. → recipes §24
- **Don't scale elements that touch their neighbors** (table rows) — tint only. Shadow without scale doesn't look lifted.
- Give non-standard shapes that receive lift **their corner radius** so the pointer morphs into them seamlessly (`contentShape(.hoverEffect, ...)`).
- Controls that auto-hide (full-screen video controls, a minimized toolbar) **reappear when the pointer moves to them.**
- No decorative pointer effects; no instructional text on the pointer.
- **macOS cursors have fixed meanings:** arrow, open hand (can drag), closed hand (dragging), I-beam (text), pointing hand (link), resize arrows, not-allowed (can't drop here), copy (Option-drag).
  Use system cursors (`.pointerStyle` on macOS 15+, `NSCursor` below), never draw your own.
- **Don't redefine macOS trackpad system gestures** — swipe between pages, Mission Control, App Exposé, swipe between full-screen apps, Notification Center.
  Two-finger horizontal swipes are *scroll events* and never reach `DragGesture` → P8, recipes §12.

### Keyboard (all platforms)
- While a held key keeps changing a value, the element appears once and only the value flows → P4.

---

## 3. Haptics — each platform has different patterns [HIG Playing haptics]

Shared rules: use patterns **for their documented meaning**, consistently (same pattern = same cause), **matching intensity and sharpness** to the visual,
sparingly (unnoticed until it's gone), short for discrete events, and **optional**. Don't disturb moments that use the camera, gyroscope or microphone.

| | What exists | When |
| --- | --- | --- |
| **iOS** | standard controls (toggles, sliders, pickers) already play haptics · `notification` (outcome: success, warning, failure) · `impact` (physical metaphor: snap into place, heavy collision) · `selection` (value changing) | don't add your own on top of standard controls |
| **iPadOS** | most have no haptic engine; some trackpads and Apple Pencil Pro do | don't rely on haptics; visuals first |
| **macOS** | Force Touch trackpad, **only during a drag or force click**: `alignment` (aligned, preferred position, reached start/end/min/max) · `levelChange` (pressure levels) · `generic` | no pattern for outcomes → show them on screen |

Code: recipes §13 (`Haptics.play`) · §25 (`Haptics.play(meaning:)`). `.sensoryFeedback` is mostly silent on macOS.

---

## 4. Layout changes [HIG Layout]

- **Decide by size class (actual space) and text size, not device type or orientation.** iPad windows resize freely; iPhone apps resize in iPhone Mirroring on the Mac.
- **Keep functionality the same as space changes**; change only how much is visible.
- At **large text sizes**, side-by-side views stack vertically and rows grow. → recipes §27 (`AnyLayout` so positions flow instead of snapping)
- Respect **safe areas** — the Dynamic Island, status bar, toolbars and tab bars.
- Separate controls from content with Liquid Glass and a scroll edge effect, **not a background color**; extend full-screen backgrounds under sidebars, toolbars and tab bars.

---

## 5. Materials — Liquid Glass vs standard materials [HIG Materials]

| | Liquid Glass | Standard materials |
| --- | --- | --- |
| Layer | **functional layer**: toolbars, tab bars, sidebars, floating controls | **content layer**: app backgrounds, cards, structure within content |
| Variants | regular (most cases; text-heavy alerts, sidebars, popovers) · clear (only over photos and video; 35% dim on bright content) | iOS: ultraThin · thin · regular · thick / macOS: purpose-specific `NSVisualEffectView.Material` |
| Rules | not in the content layer (exception: sliders and toggles that turn glass while touched); **sparingly** on custom controls | choose **by meaning, not apparent color** (settings change their look); use vibrant colors on top |

- Thicker materials give better contrast for fine text; thinner ones keep more context visible behind.
- Glass changes with Reduce Transparency, Increase Contrast and the user's Liquid Glass appearance setting — never assume one fixed look. → P11
- Code: recipes §14 (merging glass), §28 (layering).

---

## 6. System components — configure them, don't rebuild their motion

System components already move correctly. **The job is to configure them per HIG, not rebuild them** (P8).

### Sheets [HIG Sheets] → recipes §26
- iPhone: start at the **medium detent**, show a **grabber** when resizable, **support swipe-to-dismiss** — confirm only when there are unsaved changes.
- One sheet at a time. iPad uses page/form sheets. macOS sheets get a fixed size that fits their content; for repeated input, use a panel.

### Tab bars and navigation [HIG Tab bars · Toolbars]
- Keep the tab bar **visible** across sections; don't hide or disable tabs when a section is empty — the interface looks unstable.
- No custom slide or fade between tabs — it's a frequent interaction.
- iOS large titles shrink into standard titles as content scrolls; use the system transition.
- Push/pop is interruptible by the edge swipe; a custom transition loses that. → catalog 23

### Popovers [HIG Popovers]
- **Animate size changes** — an instant jump looks like a different popover replaced it. (`Motion.morph`)
- On iPhone (compact), use a sheet or full screen instead of a popover.

### Lists [HIG Lists and tables]
- A drill-down list keeps the selected row **highlighted** when you come back; a toggling row highlights briefly, then shows a checkmark.
- Insert, delete and reorder through the system (`withAnimation` on the data, `onDelete`, `onMove`), not per-row transitions.

### Progress, loading, launch [HIG Progress indicators · Loading · Launching]
- Prefer **determinate**, advancing evenly — 90% in five seconds and the last 10% in five minutes destroys trust.
- Indicators **keep moving**; a stopped indicator reads as a stalled app.
- Indeterminate → determinate is fine; **spinner ↔ bar is not.**
- **Show something as soon as possible** (placeholders); let people do other things while waiting.
- The launch screen **matches the first screen** so nothing flashes at the hand-off. Restore previous state, including scroll position.

### Toggles and sliders [HIG Toggles · Sliders]
- State differences can't rely on **color alone** — change fill, shape or add a checkmark too.
- On macOS, show results **live** while a slider moves (like the Dock size slider).

### Buttons [HIG Buttons]
- **A custom button always has a pressed state** — without one, people wonder whether it registered. → P12, recipes §3
- An action that doesn't finish instantly shows a **progress indicator inside the button** (iOS, iPadOS).

### Windows and panels (iPadOS · macOS) [HIG Windows · Panels]
- Don't imitate system window frames or controls — slightly off looks broken.
- **HUD-style panels stay small** and don't cover the content they adjust.

---

## 7. Accessibility that touches motion [HIG Accessibility]

- **Reduce Motion:** see P11. HIG also warns that fast-moving or blinking animation can cause dizziness and, in severe cases, seizures.
- **Minimize time-boxed elements:** views that dismiss themselves are a problem for people who need more time and for assistive technology users.
  Don't put important information or the only path to an action in a self-dismissing HUD or toast; keep it longer or make it dismissible under VoiceOver.
- Common interactions use **the simplest gesture**, with an on-screen alternative. Pair sound cues with haptics and visuals.
