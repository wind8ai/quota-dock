import CoreGraphics

final class BadgeLayoutTests {
    func testAccountBarOffsetsOnTranslatedWindows() {
        for window in [CGRect(x: 100, y: 200, width: 1200, height: 800),
                       CGRect(x: -1600, y: -900, width: 1000, height: 700)] {
            let point = BadgeLayout.quartzTopLeft(in: window)
            precondition(point.x - window.minX == 96)
            precondition(window.maxY - (point.y + BadgeLayout.size.height) == 8)
            precondition(BadgeLayout.size == CGSize(width: 64, height: 30))
        }
    }
}
