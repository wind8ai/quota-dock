import Foundation

struct QuotaRefreshSchedule {
    private var lastStartedAt: TimeInterval?
    private var inFlight = false

    mutating func beginIfDue(at now: TimeInterval, targetVisible: Bool) -> Bool {
        guard !inFlight else { return false }
        let interval: TimeInterval = targetVisible ? 5 : 30
        if let last = lastStartedAt, now - last < interval { return false }
        lastStartedAt = now
        inFlight = true
        return true
    }

    mutating func completed() {
        inFlight = false
    }

    mutating func woke() {
        lastStartedAt = nil
    }
}
