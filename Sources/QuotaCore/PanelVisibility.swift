import CoreGraphics
import Foundation

enum PanelVisibility {
    static func needsRestore(appKitVisible: Bool, windowInfo: [String: Any]?) -> Bool {
        return !appKitVisible || windowInfo?[kCGWindowIsOnscreen as String] as? Bool != true
    }
}
