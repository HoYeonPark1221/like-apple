// Extracts, frame by frame, how one region of a video changes over time (CSV to stdout).
// Step one of "measure Apple motion instead of imitating it by eye" — the next step is fit_spring.py.
//
//   scripts/track_video.sh <video> <x> <y> <w> <h> <tBg> <t0> <t1> [threshold=8] [bgGray]
//
//   x y w h  observed region in video pixels (origin at top left)
//   tBg      time (s) of a background frame — one where the element isn't there yet (or is fully gone)
//   t0 t1    analysis window (s)
//   threshold  only pixels differing from the background by more than this (0–255) count as "the element"
//   bgGray   (optional) brightness (0–255) of a uniform background. If given, tBg is ignored and pixels differing from this color count as the element —
//            for elements that are always on screen so no empty background frame exists (like the Dynamic Island, which only changes size)
//
// columns: t, mean, count, bx, by, bw, bh
//   mean   mean brightness difference in the region (0–255). Blur preserves the mean, so mean is roughly proportional to "opacity × area"
//   count  number of pixels that differ from the background      bx by bw bh  their bounding box (for tracking movement and size)
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
      let reader = try? AVAssetReader(asset: asset) else { FileHandle.standardError.write(Data("could not open the video\n".utf8)); exit(1) }
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
        FileHandle.standardError.write(Data("region is outside the video (\(W)x\(H))\n".utf8)); exit(1)
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
