import Foundation
import CoreFoundation

struct AccountQuota: Codable, Equatable {
    let remainingPercent: Double
    let windowDurationMins: Int
    let resetsAt: TimeInterval
    let observedAt: Date
    // Missing in older receipts and caches; a rounded percentage is not proof.
    var exhaustionConfirmed: Bool? = nil
    var creditBalance: Decimal? = nil
    var creditSpendDetected: Bool? = nil

    func isSamePeriod(as other: AccountQuota) -> Bool {
        // Response headers can move the reset timestamp by one second.
        windowDurationMins == other.windowDurationMins && abs(resetsAt - other.resetsAt) <= 2
    }

    func trackingCreditSpend(since previous: AccountQuota?) -> AccountQuota {
        guard let previous = previous, previous.observedAt <= observedAt,
              isSamePeriod(as: previous) else { return self }
        var result = self
        if result.creditBalance == nil { result.creditBalance = previous.creditBalance }
        let decreased: Bool
        if observedAt > previous.observedAt, let balance = creditBalance,
           let oldBalance = previous.creditBalance {
            decreased = balance < oldBalance
        } else { decreased = false }
        if creditSpendDetected == true || previous.creditSpendDetected == true || decreased {
            result.creditSpendDetected = true
        }
        return result
    }

    func isFresh(at now: Date) -> Bool {
        let age = now.timeIntervalSince(observedAt)
        return isUsable(at: now) && age < 900
    }

    func isUsable(at now: Date) -> Bool {
        remainingPercent.isFinite && (0...100).contains(remainingPercent)
            && [300, 10080].contains(windowDurationMins)
            && observedAt.timeIntervalSince1970.isFinite && observedAt <= now
            && resetsAt.isFinite && resetsAt > now.timeIntervalSince1970
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
                windowDurationMins: duration, resetsAt: reset, observedAt: observedAt,
                exhaustionConfirmed: limits["rate_limit_reached_type"] as? String == "rate_limit_reached" ? true : nil,
                creditBalance: creditBalance(in: limits))
        }
        return nil
    }

    private static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite else { return nil }
        return number.doubleValue
    }

    private static func creditBalance(in limits: [String: Any]) -> Decimal? {
        guard let credits = limits["credits"] as? [String: Any],
              credits["unlimited"] as? Bool == false,
              let text = credits["balance"] as? String,
              text.range(of: "^[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil,
              let balance = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")),
              !balance.isNaN, balance >= 0 else { return nil }
        return balance
    }
}
