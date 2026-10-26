import Foundation
import CoreFoundation

struct AccountQuota {
    let remainingPercent: Double
    let windowDurationMins: Int
    let resetsAt: TimeInterval
    let observedAt: Date

    func isFresh(at now: Date) -> Bool {
        let age = now.timeIntervalSince(observedAt)
        return age >= 0 && age < 60 && now.timeIntervalSince1970 < resetsAt
    }

    static func parse(_ result: [String: Any], at now: Date) -> AccountQuota? {
        let bucket: [String: Any]?
        if let buckets = result["rateLimitsByLimitId"] as? [String: Any] {
            bucket = buckets["codex"] as? [String: Any]
        } else if let legacy = result["rateLimits"] as? [String: Any],
                  legacy["limitId"] as? String == "codex" {
            bucket = legacy
        } else { bucket = nil }
        guard let limits = bucket,
              limits["limitId"] == nil || limits["limitId"] as? String == "codex" else { return nil }
        let windows = ["primary", "secondary"].compactMap { limits[$0] as? [String: Any] }
        // Match the native indicator's semantic periods, not the slot order.
        for duration in [300, 10080] {
            guard let window = windows.first(where: { number($0["windowDurationMins"]) == Double(duration) }) else { continue }
            guard let used = number(window["usedPercent"]), used >= 0,
                  let reset = number(window["resetsAt"]), reset > now.timeIntervalSince1970 else { return nil }
            return AccountQuota(remainingPercent: max(0, min(100, 100 - used)),
                windowDurationMins: duration, resetsAt: reset, observedAt: now)
        }
        return nil
    }

    private static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite else { return nil }
        return number.doubleValue
    }
}
