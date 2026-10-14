// Extracts frames from a video into one filmstrip image (with time labels).
// A tool for checking animation by eye — so code that compiles isn't shipped without knowing how it actually moves.
//
//   scripts/filmstrip.sh <video> <out.png> <t0> <t1> <n> <cols> [x y w h]
//
//   t0, t1   window in seconds      n   frames to extract      cols   frames per row
//   x y w h  (optional) crop region in video pixels — to see a small element like a HUD up close
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
guard let first = frames.first else { print("could not extract frames"); exit(1) }

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
    let y = H - (pad + (row + 1) * (ch + label + pad) - pad) // laid out top to bottom
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
