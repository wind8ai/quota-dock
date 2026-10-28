import CoreGraphics

enum BadgeLayout {
    static let size = CGSize(width: 36, height: 104)
    static let avatarCenterX: CGFloat = 26
    static let avatarTopFromBottom: CGFloat = 37
    static let avatarGap: CGFloat = 102 // Clear the native usage ring, update button and tooltip.

    /// Quartz coordinates have a downward-pointing y axis.
    static func quartzTopLeft(in window: CGRect) -> CGPoint {
        CGPoint(x: window.minX + avatarCenterX - size.width / 2,
                y: window.maxY - avatarTopFromBottom - avatarGap - size.height)
    }
}
