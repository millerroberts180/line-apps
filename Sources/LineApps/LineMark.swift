import AppKit

/// What the menu-bar item draws: a short vertical line while the apps are out, and the Line Apps curl
/// while they are folded into it. Both are the same nineteen points, a start and six curves, so one
/// bends into the other point by point, the stroke deforming rather than one picture fading into another.
enum LineMark {
    /// The curl from the Line Apps logo (the website's assets/line.svg), in the SVG's own units.
    static let logoCurl: [CGPoint] = [
        CGPoint(x: 3, y: 20),
        CGPoint(x: 9, y: 24), CGPoint(x: 10, y: 14), CGPoint(x: 13, y: 9),
        CGPoint(x: 17, y: 2), CGPoint(x: 28, y: 3), CGPoint(x: 33, y: 8),
        CGPoint(x: 38, y: 13), CGPoint(x: 34, y: 21), CGPoint(x: 27, y: 21),
        CGPoint(x: 22, y: 21), CGPoint(x: 19, y: 18), CGPoint(x: 20, y: 14),
        CGPoint(x: 21, y: 11), CGPoint(x: 25, y: 10), CGPoint(x: 28, y: 12),
        CGPoint(x: 31, y: 14), CGPoint(x: 32, y: 20), CGPoint(x: 41, y: 19),
    ]

    /// The drawing's height, as other menu-bar marks are drawn, and its stroke.
    static let height: CGFloat = 18
    static let lineWidth: CGFloat = 2
    /// The curl's width; the line is the stroke and a point either side.
    static let curlWidth: CGFloat = 26
    static let barWidth: CGFloat = 6
    /// Room the item keeps either side of the drawing.
    static let padding: CGFloat = 3

    /// The curl fitted into the drawing: 22 pt across with 2 pt either side for its round ends,
    /// centred on the drawing's middle. Flipped, y down, as in the SVG.
    static let curl: [CGPoint] = {
        let box = bounds(of: logoCurl)
        let scale = (curlWidth - 4) / box.width
        return logoCurl.map {
            CGPoint(x: 2 + ($0.x - box.minX) * scale, y: height / 2 + ($0.y - box.midY) * scale)
        }
    }()

    /// The line: the same points stood on end down the middle, 13 pt long, the curl's start at the
    /// bottom and its end at the top, each where it falls along the curl.
    static let line: [CGPoint] = curl.indices.map { index in
        let along = CGFloat(index) / CGFloat(curl.count - 1)
        return CGPoint(x: curlWidth / 2, y: 15.5 - along * 13)
    }

    /// The points part way: 0 is the line, 1 the curl. Past either end a little, as an eased overshoot
    /// takes it, the stroke bends a touch beyond and settles back.
    static func points(at progress: CGFloat) -> [CGPoint] {
        zip(line, curl).map { a, b in
            CGPoint(x: a.x + (b.x - a.x) * progress, y: a.y + (b.y - a.y) * progress)
        }
    }

    /// How wide the drawing is part way, from the line's width to the curl's.
    static func width(at progress: CGFloat) -> CGFloat {
        let p = min(max(progress, 0), 1)
        return barWidth + (curlWidth - barWidth) * p
    }

    /// The status item's length part way.
    static func itemLength(at progress: CGFloat) -> CGFloat { width(at: progress) + padding * 2 }

    /// A start and six curves through the points.
    static func path(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for start in stride(from: 1, to: points.count - 2, by: 3) {
            path.addCurve(to: points[start + 2], control1: points[start], control2: points[start + 1])
        }
        return path
    }

    /// The drawing part way, as a template image so the menu bar colours it as it does every other
    /// item, light or dark, highlighted or not.
    static func image(at progress: CGFloat) -> NSImage {
        let width = width(at: progress)
        let shape = path(points(at: progress))
        let image = NSImage(size: NSSize(width: width, height: height), flipped: true) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            // The points are laid out across the curl's width; a narrower drawing keeps them centred.
            context.translateBy(x: (width - curlWidth) / 2, y: 0)
            context.addPath(shape)
            context.setStrokeColor(CGColor(gray: 0, alpha: 1))
            context.setLineWidth(lineWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.strokePath()
            return true
        }
        image.isTemplate = true
        return image
    }

    /// Eases out with a slight overshoot, about 4 %, so the stroke lands and settles.
    static func ease(_ t: CGFloat) -> CGFloat {
        let u = min(max(t, 0), 1) - 1
        return 1 + 2 * u * u * u + u * u
    }

    /// The bounds of the curves the points make, found by walking each curve.
    static func bounds(of points: [CGPoint]) -> CGRect {
        var minX = CGFloat.infinity, minY = CGFloat.infinity, maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for start in stride(from: 0, to: points.count - 3, by: 3) {
            let p0 = points[start], p1 = points[start + 1], p2 = points[start + 2], p3 = points[start + 3]
            for step in 0...100 {
                let t = CGFloat(step) / 100, s = 1 - t
                let a = s * s * s, b = 3 * s * s * t, c = 3 * s * t * t, d = t * t * t
                let x = a * p0.x + b * p1.x + c * p2.x + d * p3.x
                let y = a * p0.y + b * p1.y + c * p2.y + d * p3.y
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
