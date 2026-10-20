import CoreGraphics
import Foundation

enum WindowDiagnostics {
    /// Read-only, no titles, account data or session contents.
    static func run() -> Int32 {
        guard let windows = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], 0)
            as? [[String: Any]] else {
            print("WindowServer query unavailable")
            return 3
        }
        let main = AccountWindowSelector.select(in: windows)
        let panels = windows.filter { $0[kCGWindowOwnerName as String] as? String == "QuotaDock" }
        let expected = main.map { CGRect(origin: BadgeLayout.quartzTopLeft(in: $0.bounds), size: BadgeLayout.size) }
        let matching = panels.contains { panel in
            guard panel[kCGWindowIsOnscreen as String] as? Bool == true,
                  let dictionary = panel[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: dictionary),
                  let expected = expected else { return false }
            return abs(bounds.minX - expected.minX) < 1 && abs(bounds.minY - expected.minY) < 1
                && bounds.size == expected.size
        }
        let report: [String: Any] = [
            "status": main == nil ? "no_visible_main_window" : (matching ? "visible_at_expected_position" : "panel_missing_or_misplaced"),
            "expectedPanelBounds": expected.map(rectJSON) ?? [:],
            "windows": windows.filter {
                let owner = $0[kCGWindowOwnerName as String] as? String
                return owner == "ChatGPT" || owner == "Codex" || owner == "QuotaDock"
            }.map { window -> [String: Any] in
                return ["owner": window[kCGWindowOwnerName as String] ?? "",
                        "id": window[kCGWindowNumber as String] ?? 0,
                        "pid": window[kCGWindowOwnerPID as String] ?? 0,
                        "onscreen": window[kCGWindowIsOnscreen as String] as? Bool ?? false,
                        "layer": window[kCGWindowLayer as String] ?? 0,
                        "bounds": window[kCGWindowBounds as String] ?? [:]]
            }
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return 3 }
        print(text)
        return main == nil ? 2 : (matching ? 0 : 1)
    }

    private static func rectJSON(_ rect: CGRect) -> [String: CGFloat] {
        ["X": rect.minX, "Y": rect.minY, "Width": rect.width, "Height": rect.height]
    }
}
