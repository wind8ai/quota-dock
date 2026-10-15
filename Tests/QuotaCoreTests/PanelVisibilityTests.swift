import CoreGraphics
import Foundation

final class PanelVisibilityTests {
    func testRestoresPanelMissingFromScreenEvenWhenAppKitSaysVisible() {
        // Captured symptom: the panel retains bounds and alpha but has no
        // kCGWindowIsOnscreen entry after a Space transition.
        let offscreen: [String: Any] = [kCGWindowAlpha as String: 1]
        precondition(PanelVisibility.needsRestore(appKitVisible: true, windowInfo: offscreen))
        precondition(PanelVisibility.needsRestore(appKitVisible: true, windowInfo: nil))
        precondition(!PanelVisibility.needsRestore(appKitVisible: true,
            windowInfo: [kCGWindowIsOnscreen as String: true]))
    }
}
