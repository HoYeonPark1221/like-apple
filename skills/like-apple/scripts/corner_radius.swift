// Measures which SwiftUI `RoundedRectangle(style: .continuous)` radius (pt) matches the top-left corner of a rounded rectangle in a screenshot.
//
//   scripts/corner_radius.sh <png> <x> <y> [scale=3] [S=90] [kContinuous]
//
//   x y   approximate position of the card's top-left corner (pixels). Within ±20px is fine.
//   scale screen scale (3 on iPhone). S = side of the corner sampling square (pixels).
//
// Method: find the two straight edges (left, top) to subpixel precision including anti-aliasing, then within the corner square (S×S)
// sum the area D where the card is "missing". A corner of radius r has D = k·r², where k depends on the corner type (circular / continuous).
//   circular:    k = 1 − π/4 ≈ 0.2146
//   continuous:  obtained by drawing a known radius with SwiftUI .continuous and measuring it the same way (calibration) — pass it as kContinuous.
// The smaller the brightness difference between background and card (e.g. a white card on #F2F2F7), the noisier it gets, so measure an area, not a point.
import CoreGraphics
import Foundation
import ImageIO

let a = CommandLine.arguments
guard a.count >= 4, let ax = Int(a[2]), let ay = Int(a[3]) else {
    print("usage: corner_radius <png> <x> <y> [scale=3] [S=90] [kContinuous]"); exit(2)
}
let scale = a.count > 4 ? (Double(a[4]) ?? 3) : 3
let S = a.count > 5 ? (Int(a[5]) ?? 90) : 90
let kCont: Double? = a.count > 6 ? Double(a[6]) : nil

guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("could not open the PNG"); exit(1) }
let W = img.width, H = img.height
var raw = [UInt8](repeating: 0, count: W * H * 4)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: &raw, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))
func L(_ x: Int, _ y: Int) -> Double {
    let i = (y * W + x) * 4
    return 0.2126 * Double(raw[i]) + 0.7152 * Double(raw[i + 1]) + 0.0722 * Double(raw[i + 2])
}
func patch(_ x: Int, _ y: Int) -> Double {      // 5×5 average
    var s = 0.0
    for dy in -2...2 { for dx in -2...2 { s += L(x + dx, y + dy) } }
    return s / 25
}

let bg = patch(ax - 12, ay - 12)               // outside the corner
let card = patch(ax + S + 14, ay + S + 14)     // inside the card (a flat spot outside the corner region)
let contrast = card - bg
guard abs(contrast) > 3 else { print("background and card brightness are too similar (\(contrast))"); exit(1) }
func cov(_ x: Int, _ y: Int) -> Double { min(max((L(x, y) - bg) / contrast, 0), 1) }

// left edge: subpixel position on a row in the straight run below the corner
let yScan = ay + S + 24
let xe = Double(ax - 24) + (0..<48).reduce(0.0) { $0 + (1 - cov(ax - 24 + $1, yScan)) }
// top edge: a column in the straight run to the right of the corner
let xScan = ax + S + 24
let ye = Double(ay - 24) + (0..<48).reduce(0.0) { $0 + (1 - cov(xScan, ay - 24 + $1)) }

let X0 = Int(floor(xe)), Y0 = Int(floor(ye))
let fx = xe - Double(X0), fy = ye - Double(Y0)
var R = 0.0
for y in Y0..<(Y0 + S) { for x in X0..<(X0 + S) { R += 1 - cov(x, y) } }
let D = R - fx * Double(S) - fy * Double(S) + fx * fy      // area cut away by the corner (px²)

let rCircPx = (D / (1 - Double.pi / 4)).squareRoot()
print(String(format: "edge x=%.2f y=%.2f px | cut area D=%.1f px² | radius assuming circular %.1f px = %.1f pt", xe, ye, D, rCircPx, rCircPx / scale))
if let k = kCont {
    let r = (D / k).squareRoot()
    print(String(format: "SwiftUI cornerRadius as continuous curvature ≈ %.1f pt  (k=%.4f)", r / scale, k))
} else {
    print(String(format: "to calibrate k (continuous): compute D/(r·scale)² for a known r and pass it. This measurement's D/scale² = %.2f pt²", D / (scale * scale)))
}
