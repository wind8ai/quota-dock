import CoreGraphics

enum BadgeLayout {
    static let size = CGSize(width: 64, height: 30)

    /// Quartz coordinates have a downward-pointing y axis.
    static func quartzTopLeft(in window: CGRect) -> CGPoint {
        CGPoint(x: window.minX + 96, y: window.maxY - size.height - 8)
    }
}
