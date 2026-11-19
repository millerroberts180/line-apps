#if DEBUG
import AppKit

/// `--snapshot-mark <folder>` draws the bend off screen, black on white and white on the dark menu bar:
/// `bend-*.png`, the README's picture, three moments of it large enough to read at the README's 820
/// points; and `bend-steps-*.png`, the bend at eleven steps, eight times over, so the shapes between can
/// be checked by eye.
enum MarkSnapshots {
    static func folder(in arguments: [String]) -> URL? {
        guard let index = arguments.firstIndex(of: "--snapshot-mark"), index + 1 < arguments.count else { return nil }
        return URL(fileURLWithPath: arguments[index + 1], isDirectory: true)
    }

    /// The README's moments: the line, the bend two thirds of the way, where the curl's loop has formed,
    /// and the curl.
    static let moments: [(progress: CGFloat, caption: String)] = [
        (0, "Apps showing"), (0.65, "Bending"), (1, "Apps collapsed"),
    ]

    static func render(to folder: URL) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, ink, paper) in [("light", NSColor.black, NSColor(white: 0.93, alpha: 1)),
                                   ("dark", NSColor.white, NSColor(white: 0.16, alpha: 1))] {
            write(hero(ink: ink, paper: paper), to: folder.appendingPathComponent("bend-\(name).png"))
            write(steps(ink: ink, paper: paper), to: folder.appendingPathComponent("bend-steps-\(name).png"))
        }
    }

    /// 820 × 260 points at 2×: the three moments on a rounded card, the mark 14 times its menu-bar size,
    /// an arrow between each and a caption under each.
    static func hero(ink: NSColor, paper: NSColor) -> NSBitmapImageRep {
        let size = CGSize(width: 1640, height: 520), scale: CGFloat = 14
        let cell = size.width / CGFloat(moments.count), markMiddle = size.height - 197
        return bitmap(size) {
            paper.setFill()
            NSBezierPath(roundedRect: CGRect(origin: .zero, size: size), xRadius: 32, yRadius: 32).fill()
            let caption: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 30, weight: .medium), .foregroundColor: ink.withAlphaComponent(0.6),
            ]
            for (index, moment) in moments.enumerated() {
                let middle = (CGFloat(index) + 0.5) * cell
                let image = tinted(LineMark.image(at: moment.progress), ink)
                let width = image.size.width * scale, height = image.size.height * scale
                image.draw(in: CGRect(x: middle - width / 2, y: markMiddle - height / 2, width: width, height: height))
                let text = NSAttributedString(string: moment.caption, attributes: caption)
                text.draw(at: CGPoint(x: middle - text.size().width / 2, y: 112))
                guard index > 0 else { continue }
                let arrow = NSBezierPath()
                arrow.move(to: CGPoint(x: CGFloat(index) * cell - 9, y: markMiddle + 18))
                arrow.line(to: CGPoint(x: CGFloat(index) * cell + 9, y: markMiddle))
                arrow.line(to: CGPoint(x: CGFloat(index) * cell - 9, y: markMiddle - 18))
                arrow.lineWidth = 5
                arrow.lineCapStyle = .round
                arrow.lineJoinStyle = .round
                ink.withAlphaComponent(0.35).setStroke()
                arrow.stroke()
            }
        }
    }

    /// The bend at eleven steps, from the line to the curl, in a row.
    static func steps(ink: NSColor, paper: NSColor) -> NSBitmapImageRep {
        let scale: CGFloat = 8, cell = CGSize(width: 40, height: 24)
        let steps = (0...10).map { CGFloat($0) / 10 }
        let size = CGSize(width: cell.width * CGFloat(steps.count) * scale, height: cell.height * scale)
        return bitmap(size) {
            paper.setFill()
            CGRect(origin: .zero, size: size).fill()
            for (index, progress) in steps.enumerated() {
                let image = tinted(LineMark.image(at: progress), ink)
                let width = image.size.width * scale, height = image.size.height * scale
                let x = (CGFloat(index) * cell.width + (cell.width - image.size.width) / 2) * scale
                image.draw(in: CGRect(x: x, y: (size.height - height) / 2, width: width, height: height))
            }
        }
    }

    /// The template image in one colour, as the menu bar draws it.
    static func tinted(_ image: NSImage, _ ink: NSColor) -> NSImage {
        NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            ink.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }

    static func bitmap(_ size: CGSize, _ draw: () -> Void) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        draw()
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    static func write(_ rep: NSBitmapImageRep, to url: URL) {
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}
#endif
