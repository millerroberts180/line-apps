import CoreGraphics
import Testing
@testable import LineApps

struct LineMarkTests {
    @Test func lineAndCurlHaveTheSamePoints() {
        #expect(LineMark.line.count == 19)
        #expect(LineMark.curl.count == LineMark.logoCurl.count)
    }

    @Test func theLineStandsStraightDownTheMiddle() {
        #expect(LineMark.line.allSatisfy { $0.x == LineMark.curlWidth / 2 })
        #expect(LineMark.line.first?.y == 15.5)
        #expect(LineMark.line.last?.y == 2.5)
        #expect(zip(LineMark.line, LineMark.line.dropFirst()).allSatisfy { $0.y > $1.y })
    }

    @Test func theCurlFitsTheDrawing() {
        let box = LineMark.bounds(of: LineMark.curl)
        #expect(abs(box.minX - 2) < 0.001)
        #expect(abs(box.maxX - (LineMark.curlWidth - 2)) < 0.001)
        #expect(abs(box.midY - LineMark.height / 2) < 0.001)
        #expect(box.minY > 1 && box.maxY < LineMark.height - 1)
    }

    @Test func pointsRunFromTheLineToTheCurl() {
        #expect(LineMark.points(at: 0) == LineMark.line)
        #expect(LineMark.points(at: 1) == LineMark.curl)
    }

    @Test func theItemWidensWithTheBendAndNoFurther() {
        #expect(LineMark.width(at: 0) == LineMark.barWidth)
        #expect(LineMark.width(at: 1) == LineMark.curlWidth)
        #expect(LineMark.width(at: 1.04) == LineMark.curlWidth)
        #expect(LineMark.width(at: -0.04) == LineMark.barWidth)
        #expect(LineMark.itemLength(at: 0) == LineMark.barWidth + 2 * LineMark.padding)
    }

    @Test func theEaseLandsAndOvershootsALittle() {
        #expect(LineMark.ease(0) == 0)
        #expect(LineMark.ease(1) == 1)
        let peak = (0...100).map { LineMark.ease(CGFloat($0) / 100) }.max() ?? 0
        #expect(peak > 1 && peak < 1.05)
    }

    @Test func thePathHasSixCurves() {
        var curves = 0
        LineMark.path(LineMark.curl).applyWithBlock { element in
            if element.pointee.type == .addCurveToPoint { curves += 1 }
        }
        #expect(curves == 6)
    }
}
