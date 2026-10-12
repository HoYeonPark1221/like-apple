// 스크린샷에서 둥근 사각형의 왼쪽 위 모서리가 SwiftUI `RoundedRectangle(style: .continuous)`의 몇 pt 반경과 같은지 잰다.
//
//   scripts/corner_radius.sh <png> <x> <y> [scale=3] [S=90] [kContinuous]
//
//   x y   카드 왼쪽 위 모서리의 대략적인 위치(픽셀). ±20px 안이면 된다.
//   scale 화면 배율(iPhone은 3). S 모서리 판독 영역 한 변(픽셀).
//
// 방법: 직선 가장자리 두 개(왼쪽·위쪽)의 위치를 안티앨리어싱까지 서브픽셀로 구한 뒤, 모서리 정사각형(S×S) 안에서
// 카드가 "비어 있는" 면적 D를 합산한다. 반경이 r인 모서리는 D = k·r² 이고, k는 모서리 종류(원호/연속 곡률)마다 다르다.
//   원호(circular):  k = 1 − π/4 ≈ 0.2146
//   연속 곡률:       SwiftUI .continuous 로 알려진 반경을 그려 같은 방식으로 재서 얻는다(보정) — 인자 kContinuous 로 넘긴다.
// 배경과 카드의 밝기 차이가 작을수록(예: #F2F2F7 위의 흰 카드) 노이즈가 커지므로 한 점이 아니라 면적으로 잰다.
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

guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: a[1]) as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("PNG를 열지 못했다"); exit(1) }
let W = img.width, H = img.height
var raw = [UInt8](repeating: 0, count: W * H * 4)
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: &raw, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))
func L(_ x: Int, _ y: Int) -> Double {
    let i = (y * W + x) * 4
    return 0.2126 * Double(raw[i]) + 0.7152 * Double(raw[i + 1]) + 0.0722 * Double(raw[i + 2])
}
func patch(_ x: Int, _ y: Int) -> Double {      // 5×5 평균
    var s = 0.0
    for dy in -2...2 { for dx in -2...2 { s += L(x + dx, y + dy) } }
    return s / 25
}

let bg = patch(ax - 12, ay - 12)               // 모서리 바깥쪽
let card = patch(ax + S + 14, ay + S + 14)     // 모서리 안쪽(모서리 영역 밖의 평평한 곳)
let contrast = card - bg
guard abs(contrast) > 3 else { print("배경과 카드의 밝기 차이가 너무 작다(\(contrast))"); exit(1) }
func cov(_ x: Int, _ y: Int) -> Double { min(max((L(x, y) - bg) / contrast, 0), 1) }

// 왼쪽 가장자리: 모서리 아래쪽 직선 구간의 한 행에서 서브픽셀 위치
let yScan = ay + S + 24
let xe = Double(ax - 24) + (0..<48).reduce(0.0) { $0 + (1 - cov(ax - 24 + $1, yScan)) }
// 위쪽 가장자리: 모서리 오른쪽 직선 구간의 한 열
let xScan = ax + S + 24
let ye = Double(ay - 24) + (0..<48).reduce(0.0) { $0 + (1 - cov(xScan, ay - 24 + $1)) }

let X0 = Int(floor(xe)), Y0 = Int(floor(ye))
let fx = xe - Double(X0), fy = ye - Double(Y0)
var R = 0.0
for y in Y0..<(Y0 + S) { for x in X0..<(X0 + S) { R += 1 - cov(x, y) } }
let D = R - fx * Double(S) - fy * Double(S) + fx * fy      // 모서리가 잘라 낸 면적(px²)

let rCircPx = (D / (1 - Double.pi / 4)).squareRoot()
print(String(format: "edge x=%.2f y=%.2f px | 잘린 면적 D=%.1f px² | 원호로 가정한 반경 %.1f px = %.1f pt", xe, ye, D, rCircPx, rCircPx / scale))
if let k = kCont {
    let r = (D / k).squareRoot()
    print(String(format: "연속 곡률로 환산한 SwiftUI cornerRadius ≈ %.1f pt  (k=%.4f)", r / scale, k))
} else {
    print(String(format: "k(연속 곡률) 보정용 값: D/(r·scale)² 를 알려진 r로 계산해 넘겨라. 이 측정의 D/scale² = %.2f pt²", D / (scale * scale)))
}
