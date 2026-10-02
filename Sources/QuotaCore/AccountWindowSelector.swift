import CoreGraphics
import Foundation

enum AccountWindowSelector {
    static func select(in windows: [[String: Any]]) -> (id: CGWindowID, bounds: CGRect)? {
        for window in windows {
            guard let bounds = bounds(from: window),
                  let number = window[kCGWindowNumber as String] as? NSNumber else { continue }
            return (CGWindowID(number.uint32Value), bounds)
        }
        return nil
    }

    static func bounds(from window: [String: Any]) -> CGRect? {
        guard let owner = window[kCGWindowOwnerName as String] as? String,
              owner == "ChatGPT" || owner == "Codex",
              window[kCGWindowIsOnscreen as String] as? Bool == true,
              let layer = window[kCGWindowLayer as String] as? NSNumber,
              // Mini/pet panels can have huge transparent bounds. Only a normal
              // application window has the account avatar used by BadgeLayout.
              layer.intValue == Int(CGWindowLevelForKey(.normalWindow)),
              let alpha = window[kCGWindowAlpha as String] as? NSNumber,
              alpha.doubleValue > 0.01,
              let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
              bounds.width >= 800,
              bounds.height >= 600 else { return nil }
        return bounds
    }
}
