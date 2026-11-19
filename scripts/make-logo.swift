// Draws Line Apps' lockup, the curl beside the words "line apps", as SVG for the README.
//
//   swift scripts/make-logo.swift    writes design/logo/line-apps-lockup-horizontal.svg, in ink, and
//                                    line-apps-lockup-horizontal-reversed.svg, in white for dark backgrounds
//
// Drawn as Tuck's, Pulse's, Hum's and Glow's lockups are, on the 256 grid they share: the symbol and a
// lower-case wordmark, all one 24-unit line with round caps and joins. The letters are Glow's and Pulse's:
// bowls of radius 40 centred on y 128, stems from y 76, the baseline at 180, an ascender from 32 and a
// descender to 228, and 50 units between letters' lines. The i's dot is the line at no length, a round cap
// on the ascender line. The symbol is the curl from the website's assets/line.svg, the one the icon and the
// menu bar draw, scaled to span x 28-228 as Pulse's and Hum's lines do; at that size the website's 4.5 stroke
// is the family's 24. It is centred on the middle of the x-height, as Glow's spark is, and carries the icon's
// gradient, Tuck blue through Pulse violet and Hum crimson to Glow coral.
import Foundation

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let folder = root.appendingPathComponent("design/logo")

/// A number as SVG wants it: at most two decimals, no trailing zeros.
func n(_ value: Double) -> String {
    var text = String(format: "%.2f", value)
    while text.hasSuffix("0") { text.removeLast() }
    if text.hasSuffix(".") { text.removeLast() }
    return text
}

// MARK: Symbol

/// The curl in the website's units, y down: a start and six curves. Its curves span x 3-41 and y 4-21.
let curl: [(Double, Double)] = [
    (3, 20), (9, 24), (10, 14), (13, 9), (17, 2), (28, 3), (33, 8), (38, 13), (34, 21), (27, 21),
    (22, 21), (19, 18), (20, 14), (21, 11), (25, 10), (28, 12), (31, 14), (32, 20), (41, 19),
]

let symbol: String = {
    let scale = 200.0 / 38
    let points = curl.map { "\(n(28 + ($0.0 - 3) * scale)) \(n(128 + ($0.1 - 12.5) * scale))" }
    var path = "M\(points[0])"
    for start in stride(from: 1, to: points.count - 2, by: 3) {
        path += " C\(points[start]) \(points[start + 1]) \(points[start + 2])"
    }
    return path
}()

// MARK: Wordmark

/// A letter drawn from `x`, its leftmost line, `width` across to its rightmost.
struct Letter {
    let width: Double
    let path: (Double) -> String
}

let letters: [Character: Letter] = [
    "l": Letter(width: 0) { x in "M\(n(x)) 32 V180" },
    "i": Letter(width: 0) { x in "M\(n(x)) 76 V180 M\(n(x)) 32 V32" },
    "n": Letter(width: 80) { x in "M\(n(x)) 76 V180 M\(n(x)) 128 A40 40 0 0 1 \(n(x + 80)) 128 V180" },
    "e": Letter(width: 80) { x in "M\(n(x)) 128 H\(n(x + 80)) A40 40 0 1 0 \(n(x + 70.6)) 153.7" },
    "a": Letter(width: 80) { x in
        "M\(n(x + 80)) 76 V180 M\(n(x)) 128 A40 40 0 1 1 \(n(x + 80)) 128 A40 40 0 1 1 \(n(x)) 128"
    },
    "p": Letter(width: 80) { x in
        "M\(n(x)) 76 V228 M\(n(x)) 128 A40 40 0 1 1 \(n(x + 80)) 128 A40 40 0 1 1 \(n(x)) 128"
    },
    "s": Letter(width: 52) { x in "M\(n(x + 48.5)) 89 A26 26 0 1 0 \(n(x + 26)) 128 A26 26 0 1 1 \(n(x + 3.5)) 167" },
]

/// Between letters' lines, and between the two words' facing lines.
let letterGap = 50.0
let wordGap = 110.0

/// One path per letter, and where the last line ends.
let (wordmark, wordmarkEnd): ([String], Double) = {
    var paths: [String] = []
    var x = 24.0
    for (index, character) in "line apps".enumerated() {
        if character == " " {
            x += wordGap - letterGap
            continue
        }
        if index > 0 { x += letterGap }
        let letter = letters[character]!
        paths.append(letter.path(x))
        x += letter.width
    }
    return (paths, x)
}()

// MARK: Lockup

/// The wordmark starts 268 in, as in the family's lockups, 40 from the symbol's ink; the right margin
/// matches the symbol's on the left, 16.
let offset = 268.0
let width = Int((offset + wordmarkEnd + 12 + 16).rounded(.up))

func lockup(title: String, ink: String) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 \(width) 256" width="\(width)" height="256" role="img" aria-labelledby="title">
      <title id="title">\(title)</title>
      <!-- Made by scripts/make-logo.swift. The curl spans x 28-228, centred on the middle of the x-height (y 128); the wordmark starts 268 in, 40 from it. -->
      <defs>
        <linearGradient id="family" gradientUnits="userSpaceOnUse" x1="16" y1="0" x2="240" y2="0">
          <stop offset="0" stop-color="#7299C5"/>
          <stop offset="0.36" stop-color="#5B4FE6"/>
          <stop offset="0.7" stop-color="#B81D45"/>
          <stop offset="1" stop-color="#DE8B6D"/>
        </linearGradient>
      </defs>
      <g fill="none" stroke="\(ink)" stroke-width="24" stroke-linecap="round" stroke-linejoin="round">
        <path d="\(symbol)" stroke="url(#family)"/>
        <g transform="translate(\(n(offset)) 0)">
    \(wordmark.map { "      <path d=\"\($0)\"/>" }.joined(separator: "\n"))
        </g>
      </g>
    </svg>

    """
}

try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
for (name, title, ink) in [("line-apps-lockup-horizontal.svg", "Line Apps logo", "#111316"),
                           ("line-apps-lockup-horizontal-reversed.svg", "Line Apps logo, reversed", "#FFFFFF")] {
    let url = folder.appendingPathComponent(name)
    try lockup(title: title, ink: ink).write(to: url, atomically: true, encoding: .utf8)
    print("Wrote \(url.path)")
}
