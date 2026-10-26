import Foundation
import CoreFoundation

struct AccountQuota {
    let remainingPercent: Double
    let windowDurationMins: Int
    let resetsAt: TimeInterval
    let observedAt: Date

    func isFresh(at now: Date) -> Bool {
        let age = now.timeIntervalSince(observedAt)
        return age >= 0 && age < 900 && now.timeIntervalSince1970 < resetsAt
    }

    static func parseLimits(_ limits: [String: Any], observedAt: Date) -> AccountQuota? {
        guard limits["limit_id"] as? String == "codex" else { return nil }
        let windows = ["primary", "secondary"].compactMap { limits[$0] as? [String: Any] }
        // Match the native indicator's semantic periods, not the slot order.
        for duration in [300, 10080] {
            guard let window = windows.first(where: { number($0["window_minutes"]) == Double(duration) }) else { continue }
            guard let used = number(window["used_percent"]), used >= 0,
                  let reset = number(window["resets_at"]), reset > observedAt.timeIntervalSince1970 else { return nil }
            return AccountQuota(remainingPercent: max(0, min(100, 100 - used)),
                windowDurationMins: duration, resetsAt: reset, observedAt: observedAt)
        }
        return nil
    }

    private static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite else { return nil }
        return number.doubleValue
    }
}
