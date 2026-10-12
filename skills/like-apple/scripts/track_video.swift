// 영상의 한 영역이 시간에 따라 어떻게 변하는지 프레임마다 수치로 뽑는다 (CSV를 stdout으로).
// "Apple 동작을 눈대중으로 흉내 내지 않고 측정한다"의 첫 단계 — 다음 단계는 fit_spring.py.
//
//   scripts/track_video.sh <video> <x> <y> <w> <h> <tBg> <t0> <t1> [threshold=8] [bgGray]
//
//   x y w h  영상 픽셀 좌표의 관찰 영역 (왼쪽 위가 원점)
//   tBg      배경 프레임의 시각(초). 관찰하는 요소가 아직 없을 때(또는 완전히 사라진 뒤)의 한 프레임
//   t0 t1    분석할 구간(초)
//   threshold  배경과 이 값(0~255) 넘게 다른 픽셀만 "요소가 있는 곳"으로 본다
//   bgGray   (선택) 배경이 고른 색일 때 그 밝기(0~255). 주면 tBg를 쓰지 않고 "이 색과 다른 픽셀"을 요소로 본다 —
//            요소가 화면에 항상 있어서 빈 배경 프레임을 못 잡는 경우(Dynamic Island처럼 크기만 바뀌는 것)에 쓴다
//
// 열: t, mean, count, bx, by, bw, bh
//   mean   영역의 평균 밝기 차이(0~255). 블러는 평균을 보존하므로 mean은 대체로 "투명도 × 면적"에 비례한다
//   count  배경과 달라진 픽셀 수      bx by bw bh  그 픽셀들의 바운딩 박스 (이동·크기 변화 추적용)
import AVFoundation
import CoreVideo
import Foundation

let a = CommandLine.arguments
guard a.count >= 9,
      let rx = Int(a[2]), let ry = Int(a[3]), let rw = Int(a[4]), let rh = Int(a[5]),
      let tBg = Double(a[6]), let t0 = Double(a[7]), let t1 = Double(a[8]) else {
    FileHandle.standardError.write(Data("usage: track_video <video> x y w h tBg t0 t1 [threshold]\n".utf8)); exit(2)
}
let threshold = a.count >= 10 ? (Int(a[9]) ?? 8) : 8
let constantBg: Int? = a.count >= 11 ? Int(a[10]) : nil

let asset = AVURLAsset(url: URL(fileURLWithPath: a[1]))
guard let track = asset.tracks(withMediaType: .video).first,
      let reader = try? AVAssetReader(asset: asset) else { FileHandle.standardError.write(Data("영상을 열지 못했다\n".utf8)); exit(1) }
let out = AVAssetReaderTrackOutput(track: track, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
reader.add(out)
reader.startReading()

func gray(_ base: UnsafePointer<UInt8>, _ stride: Int, _ x: Int, _ y: Int) -> Int {
    let p = base + y * stride + x * 4        // BGRA
    return (Int(p[0]) * 29 + Int(p[1]) * 150 + Int(p[2]) * 77) >> 8
}

var background: [Int]? = constantBg.map { [Int](repeating: $0, count: rw * rh) }
print("t,mean,count,bx,by,bw,bh")
while let sample = out.copyNextSampleBuffer() {
    let t = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample))
    if t > t1 { break }
    guard let px = CMSampleBufferGetImageBuffer(sample) else { continue }
    CVPixelBufferLockBaseAddress(px, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(px, .readOnly) }
    guard let raw = CVPixelBufferGetBaseAddress(px) else { continue }
    let base = raw.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRow(px)
    let W = CVPixelBufferGetWidth(px), H = CVPixelBufferGetHeight(px)
    guard rx >= 0, ry >= 0, rx + rw <= W, ry + rh <= H else {
        FileHandle.standardError.write(Data("영역이 영상(\(W)x\(H)) 밖이다\n".utf8)); exit(1)
    }

    var snap = [Int](repeating: 0, count: rw * rh)
    for y in 0..<rh { for x in 0..<rw { snap[y * rw + x] = gray(base, stride, rx + x, ry + y) } }

    if background == nil, t >= tBg { background = snap }
    guard let bg = background, t >= t0 else { continue }

    var sum = 0, count = 0, minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
    for y in 0..<rh {
        for x in 0..<rw {
            let d = abs(snap[y * rw + x] - bg[y * rw + x])
            sum += d
            if d > threshold {
                count += 1
                if x < minX { minX = x }; if x > maxX { maxX = x }
                if y < minY { minY = y }; if y > maxY { maxY = y }
            }
        }
    }
    let mean = Double(sum) / Double(rw * rh)
    if count > 0 {
        print(String(format: "%.4f,%.4f,%d,%d,%d,%d,%d", t, mean, count, minX, minY, maxX - minX + 1, maxY - minY + 1))
    } else {
        print(String(format: "%.4f,%.4f,0,0,0,0,0", t, mean))
    }
}
