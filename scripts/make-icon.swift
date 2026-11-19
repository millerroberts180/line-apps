// Draws Line Apps' icon in code and builds Resources/AppIcon.icns.
//
//   swift scripts/make-icon.swift                  writes Resources/AppIcon.icns
//   swift scripts/make-icon.swift --png FILE       the 1024-px icon alone, to look at
//
// Built as Tuck's, Pulse's, Hum's and Glow's are: an 824-px body with continuous corners centred on
// the 1024-px macOS grid, a soft shadow, and the symbol as one round-capped white line. Line Apps is
// the family, so its body carries the family gradient, Tuck blue through Pulse violet and Hum crimson
// to Glow coral, the one place the design language gives all four colours together. The symbol is
// the Line Apps curl, from the website's assets/line.svg. Every size is drawn from the vectors.
import AppKit
import CoreGraphics
import Foundation

let canvas: CGFloat = 1024
let body = CGRect(x: 100, y: 100, width: 824, height: 824)

/// A rounded rectangle whose corners ease into the edges, as Apple's continuous corners do.
func continuousRect(_ rect: CGRect, extent: CGFloat, exponent: CGFloat = 3.26) -> CGPath {
    let path = CGMutablePath()
    let e = min(extent, rect.width / 2, rect.height / 2)
    let corners: [(CGPoint, CGFloat)] = [
        (CGPoint(x: rect.maxX - e, y: rect.minY + e), -.pi / 2),
        (CGPoint(x: rect.maxX - e, y: rect.maxY - e), 0),
        (CGPoint(x: rect.minX + e, y: rect.maxY - e), .pi / 2),
        (CGPoint(x: rect.minX + e, y: rect.minY + e), .pi),
    ]
    path.move(to: CGPoint(x: rect.minX + e, y: rect.minY))
    for (center, start) in corners {
        for step in 0...48 {
            let angle = start + CGFloat(step) / 48 * (.pi / 2)
            let c = cos(angle), s = sin(angle)
            path.addLine(to: CGPoint(x: center.x + copysign(pow(abs(c), 2 / exponent), c) * e,
                                     y: center.y + copysign(pow(abs(s), 2 / exponent), s) * e))
        }
    }
    path.closeSubpath()
    return path
}

func color(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// The curl in the SVG's units (viewBox -2 -10 48 48), y down.
let curl: [CGPoint] = [
    (3, 20), (9, 24), (10, 14), (13, 9), (17, 2), (28, 3), (33, 8), (38, 13), (34, 21), (27, 21),
    (22, 21), (19, 18), (20, 14), (21, 11), (25, 10), (28, 12), (31, 14), (32, 20), (41, 19),
].map { CGPoint(x: $0.0, y: $0.1) }

func draw(_ context: CGContext, side: CGFloat) {
    context.scaleBy(x: side / canvas, y: side / canvas)
    let outline = continuousRect(body, extent: 0.3435 * body.width)
    // A soft shadow under the body, as the family's other icons have.
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: CGColor(gray: 0, alpha: 0.28))
    context.addPath(outline)
    context.setFillColor(color(0x5B4FE6))
    context.fillPath()
    context.restoreGState()
    // The family gradient, top left to bottom right.
    context.saveGState()
    context.addPath(outline)
    context.clip()
    let colors = [color(0x7299C5), color(0x5B4FE6), color(0xB81D45), color(0xDE8B6D)] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 0.36, 0.7, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: body.minX, y: body.maxY), end: CGPoint(x: body.maxX, y: body.minY), options: [])
    context.restoreGState()
    // The curl, 560 px across, centred on the body; the SVG's y runs down, the context's up.
    let scale: CGFloat = 560 / 38
    let center = CGPoint(x: 22, y: 12.9)
    let points = curl.map { CGPoint(x: canvas / 2 + ($0.x - center.x) * scale, y: canvas / 2 - ($0.y - center.y) * scale) }
    let path = CGMutablePath()
    path.move(to: points[0])
    for start in stride(from: 1, to: points.count - 2, by: 3) {
        path.addCurve(to: points[start + 2], control1: points[start], control2: points[start + 1])
    }
    context.addPath(path)
    context.setStrokeColor(color(0xF4F6F5))
    context.setLineWidth(4.5 * scale)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.strokePath()
}

func png(side: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = graphics
    draw(graphics.cgContext, side: CGFloat(side))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let arguments = CommandLine.arguments
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
if let index = arguments.firstIndex(of: "--png"), index + 1 < arguments.count {
    try png(side: 1024).write(to: URL(fileURLWithPath: arguments[index + 1]))
    exit(0)
}
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("LineApps-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try png(side: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try png(side: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
let output = root.appendingPathComponent("Resources/AppIcon.icns")
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print("Wrote \(output.path)")
