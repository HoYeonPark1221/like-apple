// 영상에서 프레임을 뽑아 한 장의 필름스트립(시간 라벨 포함)으로 만든다.
// 애니메이션을 "눈으로" 확인하는 도구다 — 컴파일만 해 놓고 화면에서 어떻게 움직이는지 모르는 상태를 피하려고 만들었다.
//
//   scripts/filmstrip.sh <video> <out.png> <t0> <t1> <n> <cols> [x y w h]
//
//   t0, t1   초 단위 구간      n   뽑을 프레임 수      cols   한 줄에 놓을 프레임 수
//   x y w h  (선택) 영상 픽셀 좌표로 잘라 낼 영역 — HUD처럼 작은 요소를 크게 보고 싶을 때
import AVFoundation
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count >= 7, let t0 = Double(a[3]), let t1 = Double(a[4]), let n = Int(a[5]), let cols = Int(a[6]), n > 0, cols > 0 else {
    print("usage: filmstrip <video> <out.png> <t0> <t1> <n> <cols> [x y w h]"); exit(2)
}
let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero

var crop: CGRect?
if a.count >= 11, let x = Double(a[7]), let y = Double(a[8]), let w = Double(a[9]), let h = Double(a[10]) {
    crop = CGRect(x: x, y: y, width: w, height: h)
}

var frames: [(Double, CGImage)] = []
for i in 0..<n {
    let t = n == 1 ? t0 : t0 + (t1 - t0) * Double(i) / Double(n - 1)
    guard let img = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil) else { continue }
    let cut = crop.flatMap { img.cropping(to: $0) } ?? img
    frames.append((t, cut))
}
guard let first = frames.first else { print("프레임을 뽑지 못했다"); exit(1) }

let scale = min(1.0, 360.0 / Double(first.1.width))
let cw = Int(Double(first.1.width) * scale), ch = Int(Double(first.1.height) * scale)
let pad = 6, label = 22
let rows = (frames.count + cols - 1) / cols
let W = cols * (cw + pad) + pad, H = rows * (ch + label + pad) + pad
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setFillColor(CGColor(gray: 0.5, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
ctx.interpolationQuality = .high

for (i, f) in frames.enumerated() {
    let col = i % cols, row = i / cols
    let x = pad + col * (cw + pad)
    let y = H - (pad + (row + 1) * (ch + label + pad) - pad) // 위에서 아래로 배치
    ctx.draw(f.1, in: CGRect(x: x, y: y, width: cw, height: ch))
    let text = NSAttributedString(string: String(format: "%.3fs", f.0), attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Menlo" as CFString, 13, nil),
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0, alpha: 1),
    ])
    ctx.textPosition = CGPoint(x: x + 2, y: y - 16)
    CTLineDraw(CTLineCreateWithAttributedString(text), ctx)
}

let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[2]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("\(frames.count) frames → \(a[2])  (\(W)x\(H))")
