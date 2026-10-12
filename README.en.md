# Like Apple — Claude Skill

[한국어](README.md) · **English**

**A Claude skill that makes iOS, iPadOS and macOS apps look, move and feel like Apple made them.**
It tunes SwiftUI animation, sizing (bezels, rounded corners, type) and platform conventions, all grounded in Apple's Human Interface Guidelines.

> The skill's own files are written in Korean. Claude reads them without trouble and answers in whatever language you use.

## Where it came from — Live Peninsula

This skill grew out of building **Live Peninsula**, a macOS notch app, as a solo developer.
The app's philosophy is Apple-like motion, rounded bezels with concentric corners, and movement that is quietly precise the way the system is.
Holding to that meant building and rebuilding the notch's open/close spring, the hotkey HUD, files dragged into the tray,
the lock-screen music card and the timer ruler — over and over, each time noting "it used to be like this; here's why it changed."
This skill is those rules, checked against Apple's HIG and measured against the SDK, then generalized for any iOS, iPadOS or macOS app.

## Install (Claude Code)

```bash
claude plugin marketplace add HoYeonPark1221/like-apple
claude plugin install like-apple@like-apple
```

Usage:

```
/like-apple build it using this
```

Update:

```bash
claude plugin update like-apple@like-apple
```

To use it without the plugin system, copy the `skills/like-apple` folder into `~/.claude/skills/`.

## What's inside

| | |
| --- | --- |
| **15 principles** | Critical damping by default, entrances and exits keep different time, everything is interruptible, hand off the finger's velocity, materials separate layers, fit the platform's input … |
| **25-entry motion catalog** | Dynamic Island, pill HUD, genie, Liquid Glass merge, Siri glow, zoom transition, rolling numbers, timer ring, sheets, pointer effects, reject shake … — each with an evidence grade ([Apple] · [HIG] · [SDK] · [App]) |
| **`AppleMotion.swift`** | One drop-in file with 29 recipes, compile-checked on iOS 17/26 and macOS 14/26 in both Swift 5 and Swift 6 modes |
| **Platform HIG** | How iPhone (touch), iPad (touch + pointer) and Mac (pointer + keyboard) differ in input, haptics, layout and materials; HIG rules for sheets, tab bars, toolbars, popovers, alerts, lists and progress indicators |
| **Metrics** | Apple type sizes (verified against the SDK), control and bezel sizes, concentric corners |
| **Measurement tools** | Scripts that unroll a reference recording into frames, track the motion and fit spring values to it |

Evidence grades keep claims honest: **[Apple]** is guaranteed by Apple's APIs or sessions, **[HIG]** comes from the guidelines text,
**[SDK]** was measured on a real SDK, and **[App]** is an approximation that converged by eye in Live Peninsula — never presented as Apple's own numbers.

## Requirements

- Claude Code (the skill itself can be read anywhere)
- The measurement and verification tools in `scripts/` need **macOS and Xcode**.
- Scope is iOS, iPadOS and macOS apps. Websites, watchOS, visionOS and tvOS are out of scope — for web, see the `apple-design` skill.

## Disclaimer

This is an independent personal project, not affiliated with or endorsed by Apple Inc.
Apple, iOS, iPadOS, macOS, Liquid Glass, Dynamic Island and SF Symbols are trademarks of Apple Inc.
HIG content is summarized with its source named; for the latest rules see the [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines).

## License

MIT © HoYeon Park
