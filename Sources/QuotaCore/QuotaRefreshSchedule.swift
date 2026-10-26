import Foundation

struct QuotaRefreshSchedule {
    private var lastStartedAt: TimeInterval?
    private var inFlight = false
    private var failures = 0
    private var retryAt: TimeInterval = 0

    mutating func beginIfDue(at now: TimeInterval, targetVisible: Bool) -> Bool {
        guard !inFlight, now >= retryAt else { return false }
        let interval: TimeInterval = targetVisible ? 5 : 30
        if let last = lastStartedAt, now - last < interval { return false }
        lastStartedAt = now
        inFlight = true
        return true
    }

    mutating func completed(at now: TimeInterval, succeeded: Bool) {
        inFlight = false
        if succeeded {
            failures = 0
            retryAt = 0
        } else {
            failures = min(failures + 1, 5)
            retryAt = now + min(60, 5 * pow(2, Double(failures - 1)))
        }
    }

    mutating func woke() {
        lastStartedAt = nil
        failures = 0
        retryAt = 0
    }
}
