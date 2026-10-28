import CoreGraphics

final class BadgeLayoutTests {
    func testAccountBarOffsetsOnTranslatedWindows() {
        for window in [CGRect(x: 100, y: 200, width: 1200, height: 800),
                       CGRect(x: -1600, y: -900, width: 1000, height: 700)] {
            let point = BadgeLayout.quartzTopLeft(in: window)
            precondition(point.x + BadgeLayout.size.width / 2 == window.minX + 26)
            let bottom = point.y + BadgeLayout.size.height
            let avatarTop = window.maxY - 37
            // The update tooltip reaches 127 pt above the window bottom.
            // Keep the gauge at least 12 pt above that occupied area.
            precondition(window.maxY - bottom >= 139,
                         "Quota gauge overlaps the update tooltip's reserved area")
            precondition(avatarTop - bottom == 102)
            precondition(BadgeLayout.size == CGSize(width: 36, height: 104))
        }
    }
}
