import CoreGraphics

final class BadgeLayoutTests {
    func testAccountBarOffsetsOnTranslatedWindows() {
        for window in [CGRect(x: 100, y: 200, width: 1200, height: 800),
                       CGRect(x: -1600, y: -900, width: 1000, height: 700)] {
            let point = BadgeLayout.quartzTopLeft(in: window)
            precondition(point.x + BadgeLayout.size.width / 2 == window.minX + 26)
            let bottom = point.y + BadgeLayout.size.height
            let avatarTop = window.maxY - 37
            precondition(avatarTop - bottom == 6)
            precondition(BadgeLayout.size == CGSize(width: 32, height: 96))
        }
    }
}
