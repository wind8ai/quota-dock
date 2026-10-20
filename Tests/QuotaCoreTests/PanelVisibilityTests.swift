import CoreGraphics
import Foundation

final class PanelVisibilityTests {
    func testRecoveryCooldownAndSuccessfulDisplayReset() {
        var recovery = PanelVisibility()
        precondition(recovery.action(at: 0, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 0.05, targetVisible: true, appKitVisible: true, windowInfo: nil) == .none)
        precondition(recovery.action(at: 1, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 2, targetVisible: true, appKitVisible: true, windowInfo: nil) == .recreate)
        for tick in 3..<12 {
            precondition(recovery.action(at: Double(tick), targetVisible: true, appKitVisible: true, windowInfo: nil) == .none)
        }
        let visible: [String: Any] = [kCGWindowIsOnscreen as String: true]
        precondition(recovery.action(at: 12, targetVisible: true, appKitVisible: true, windowInfo: visible) == .none)
        precondition(recovery.action(at: 13, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 14, targetVisible: true, appKitVisible: true, windowInfo: visible) == .none)
        precondition(recovery.action(at: 15, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 16, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
    }

    func testHiddenTargetDoesNotRecoverOrAccumulateFailures() {
        var recovery = PanelVisibility()
        precondition(recovery.action(at: 0, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 1, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        for tick in 2..<30 {
            precondition(recovery.action(at: Double(tick), targetVisible: false, appKitVisible: false, windowInfo: nil) == .none)
        }
        precondition(recovery.action(at: 30, targetVisible: true, appKitVisible: false, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 31, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
    }
    func testRepeatedFailedReorderRecreatesPanel() {
        var recovery = PanelVisibility()
        precondition(recovery.action(at: 0, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 1, targetVisible: true, appKitVisible: true, windowInfo: nil) == .reorder)
        precondition(recovery.action(at: 2, targetVisible: true, appKitVisible: true, windowInfo: nil) == .recreate,
                     "Repeated ordering must not leave an invisible panel stuck forever")
    }
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
