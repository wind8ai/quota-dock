import CoreGraphics
import Foundation

struct PanelVisibility {
    enum Action { case none, reorder, recreate }
    private var failures = 0
    private var nextActionAt: TimeInterval = 0

    mutating func action(at now: TimeInterval, targetVisible: Bool,
                         appKitVisible: Bool, windowInfo: [String: Any]?) -> Action {
        guard targetVisible,
              Self.needsRestore(appKitVisible: appKitVisible, windowInfo: windowInfo) else {
            failures = 0
            return .none
        }
        guard now >= nextActionAt else { return .none }
        failures += 1
        if failures >= 3 {
            failures = 0
            nextActionAt = now + 10
            return .recreate
        }
        nextActionAt = now + 1
        return .reorder
    }

    static func needsRestore(appKitVisible: Bool, windowInfo: [String: Any]?) -> Bool {
        return !appKitVisible || windowInfo?[kCGWindowIsOnscreen as String] as? Bool != true
    }
}
