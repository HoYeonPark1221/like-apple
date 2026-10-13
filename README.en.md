# Like Apple — Claude Skill

```
/like-apple build it using this
```

[한국어](README.md) · **English**

**A Claude skill that makes iOS, iPadOS and macOS apps look, move and feel like Apple made them.**
It tunes SwiftUI animation, sizing (bezels, rounded corners, type) and platform conventions, all grounded in Apple's Human Interface Guidelines.

> Claude answers in whatever language you use.

## 1. Where it came from — Live Peninsula

[**Live Peninsula**](https://www.live-peninsula.com) turns the Mac's notch into a home for music, timers, a file tray and volume/brightness indicators.
I built it alone, and from day one there was a single bar to clear: **it should look like Apple made it.**

That bar turned out to live in very small numbers. Change the second decimal place of a spring and "premium" becomes "cheap".
So no value was left to guesswork, and every change left a comment in the code saying **why**. What follows is real Live Peninsula code.

### 1.1 The notch that "jumped" when it opened — 0.68 → 0.85

The notch's open/close spring (height 38pt ↔ 175pt) started with a damping of `0.68`. It was meant to feel lively;
instead it shot **5.4%** past its target and bounced back, and the whole notch felt wobbly. I measured the curve step by step and landed on `0.85`.

```swift
// Before: overshoots its target by 5.4% on every open and close
.animation(.spring(response: 0.42, dampingFraction: 0.68), value: calculateNotchHeight())

// After: 0.6% overshoot — the bounce is gone, only a soft deceleration remains
.animation(.spring(response: 0.42, dampingFraction: 0.85), value: calculateNotchHeight())
```

Width, height and corner radius all ride **one shared spring**. Let them move separately and the shape visibly warps.

### 1.2 Opening and closing keep different time

The glass behind the notch uses **different curves** in and out. It fills in slowly (0.55s) and drains faster (0.4s).
Leaving quickly is what keeps a closing view from lingering.

```swift
vm.notchState == .on ? .easeOut(duration: 0.55) : .easeIn(duration: 0.4)
```

It's an ease rather than a spring on purpose: glass isn't an object you push, it's a **surface that fills**. When it bounced, it didn't look like water settling — it looked like a panel wobbling.

The timer banner follows the same idea. On the way in, the notch opens first and the content settles in **0.08s later**; on the way out, the content clears in **0.13s**, before the notch starts folding.
Done the other way around, the text got clipped by the closing corners.

```swift
insertion: .opacity.combined(with: .offset(y: -10)).animation(.spring(response: 0.42, dampingFraction: 0.84).delay(0.08)),
removal:   .opacity.combined(with: .offset(y: -6)).animation(.easeIn(duration: 0.13))
```

### 1.3 The moment you press, and the moment you let go

Buttons react within **0.07s** of a press and return without bouncing when released. The first version bounced on release (0.62),
but pressing those buttons also starts folding the notch — two motions on two different beats, and the whole screen seemed to shake.

```swift
configuration.isPressed ? .easeOut(duration: 0.07) : .spring(response: 0.22, dampingFraction: 1.0)
```

A press is shown with **brightness**, not opacity. Fade a filled button and it doesn't look pressed — it looks switched off.

---

Notes like "it used to be this; here's why it changed" piled up all over the Live Peninsula codebase.
**like-apple takes that record, re-checks it against Apple's Human Interface Guidelines and measurements in Xcode, and generalizes it for any iOS, iPadOS or macOS app.**
Now Claude picks values by the same standard when it builds your animations.

## 2. Install (Claude Code)

Pick one of two ways.

### 2.1 Simple install — `/like-apple`

```bash
git clone https://github.com/HoYeonPark1221/like-apple.git
cp -R like-apple/skills/like-apple ~/.claude/skills/
```

Usage:

```
/like-apple build it using this
```

To update, run `git pull` in the `like-apple` folder and repeat the `cp` command.

### 2.2 Plugin install — easier updates

```bash
claude plugin marketplace add HoYeonPark1221/like-apple
claude plugin install like-apple@like-apple
```

Usage:

```
/like-apple:like-apple build it using this
```

Plugin skills are prefixed with the plugin name. Updating takes one line:

```bash
claude plugin update like-apple@like-apple
```

## 3. What's inside

### 3.1 15 principles — the rules Claude follows when it animates

These are what Claude checks every time it builds or fixes an animation. Most of them were learned the hard way in Live Peninsula. A few, in plain words:

- **Don't bounce by default.** Bounce is for moments with real momentum, like when the user flings something.
- **Press instantly, release gently.** Entrances and exits keep different time, too.
- **Everything can be interrupted.** Tapping repeatedly or grabbing something mid-motion must never break it.
- **Carry the finger's speed.** Let go of a drag and it continues at the same speed before settling naturally.
- **Don't rebuild what Apple already built.** Use the system's own motion for sheets, paging and the like.
- **Every device has a different hand.** Fingers on iPhone, fingers and a pointer on iPad, mouse and keyboard on Mac.

### 3.2 A 25-entry motion catalog — answers to "make it like ___"

Motions you see all the time on Apple devices, broken down into **what they're made of**. Ask for "like the Dynamic Island" and
Claude starts from the breakdown — "grow width, height and corners together on one spring, and clear the content before the container" — plus the code.

Some of what's in it:
- The **Dynamic Island** growing and shrinking at the top of the iPhone
- The **small pill-shaped indicator** that appears when you change the volume
- iOS 26 **Liquid Glass** buttons merging and splitting like droplets
- A photo that **grows into a full screen** from where you tapped it
- Numbers that **roll** as they change, a **timer ring** that shrinks with the time left
- **Sheets** sliding up from the bottom, and how things react when an iPad pointer hovers over them
- A **side-to-side shake** that says "no", like entering a wrong password

Each entry is marked with **how far you can trust it**: whether Apple provides it officially, whether it's written in Apple's design guidelines,
or whether it's an approximation tuned by eye in Live Peninsula. For motions where Apple hasn't published the values, Claude says it's building an approximation.

### 3.3 29 code recipes — SwiftUI code, ready to use

Pre-built code for button presses, drag-and-release, haptics, sheet setup and more.
Every recipe was **actually built** on iOS 17 and 26 and macOS 14 and 26, in both Swift 5 and Swift 6.
Nothing gets dropped into your project as a whole file — **only the parts you need go in, written to match your code style.**

### 3.4 Per-device rules — iPhone, iPad and Mac are touched differently

The same button is expected to respond differently on each device. These rules follow Apple's Human Interface Guidelines (HIG).
- **iPhone** — you press directly with a finger, so the response must be clear, and vibration (haptics) is used for what it means.
- **iPad** — fingers and a pointer share the screen, so things should respond to the pointer too. Window sizes change all the time.
- **Mac** — things respond when the mouse hovers, before you click, and every feature is reachable from the menu bar and keyboard shortcuts.

It also covers how to use sheets, tab bars, toolbars, popovers, alerts, lists and loading indicators the Apple way.

### 3.5 Sizes — type, buttons, rounded corners

Great motion still looks off when the sizes are wrong.
- **Type sizes** — the standard size per device, such as 17pt body text on iPhone and 13pt on Mac (read directly from Xcode)
- **Button sizes** — the minimum size that's comfortable to press (44pt on iPhone, 28pt on Mac) and the space around it
- **Rounded corners** — an inner corner should be smaller than the outer one by exactly the gap between them, or they look misaligned (concentric corners)

### 3.6 Measurement tools — measuring motion with numbers, not eyes

Tools for matching "exactly like this" without guessing.
Take a screen recording from an Apple device, **unroll it frame by frame**, **track** where things move, and **calculate the spring values** that produce that motion.
There's also a script that tells you how much a given spring overshoots and when it settles. (Requires macOS + Xcode)

## 4. Platforms and roadmap

- **Supported now:** iOS, iPadOS and macOS apps
- **Coming next:** support for more Apple platforms, including visionOS and watchOS.
- Runs in Claude Code. The measurement and verification tools in `scripts/` need macOS and Xcode.

## 5. Disclaimer

This is an independent personal project, not affiliated with or endorsed by Apple Inc.
Apple, iOS, iPadOS, macOS, Liquid Glass, Dynamic Island and SF Symbols are trademarks of Apple Inc.
HIG content is summarized with its source named; for the latest rules see the [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines).

## 6. License

MIT © HoYeon Park
