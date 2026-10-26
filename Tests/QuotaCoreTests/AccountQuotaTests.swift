import Foundation

final class AccountQuotaTests {
    private func legacy(_ used: Any, duration: Int = 10080, reset: Double = 2000) -> [String: Any] {
        ["rateLimits": ["limitId": "codex", "primary": ["usedPercent": used,
            "windowDurationMins": duration, "resetsAt": reset]]]
    }

    func testWeeklyOnlyAndServerCorrectionsRemainAuthoritative() {
        let now = Date(timeIntervalSince1970: 1000)
        precondition(AccountQuota.parse(legacy(40), at: now)?.remainingPercent == 60)
        let corrected = AccountQuota.parse(legacy(29.25), at: now)
        precondition(corrected?.remainingPercent == 70.75)
        precondition(corrected?.windowDurationMins == 10080)
    }

    func testRejectsMissingCodexBucketEvenWhenLegacyExists() {
        var result = legacy(10)
        result["rateLimitsByLimitId"] = ["spark": ["primary": ["usedPercent": 1]]]
        precondition(AccountQuota.parse(result, at: Date(timeIntervalSince1970: 1000)) == nil)
    }

    func testRejectsInvalidExpiredAndUnsupportedWindows() {
        let now = Date(timeIntervalSince1970: 1000)
        for used: Any in [true, "29", Double.nan, Double.infinity, -1] {
            precondition(AccountQuota.parse(legacy(used), at: now) == nil)
        }
        precondition(AccountQuota.parse(legacy(20, reset: 1000), at: now) == nil)
        precondition(AccountQuota.parse(legacy(20, duration: 15), at: now) == nil)
        precondition(AccountQuota.parse([:], at: now) == nil)
        precondition(AccountQuota.parse(legacy(120), at: now)?.remainingPercent == 0)
    }
    func testFreshnessExpiresAtResetOrAfterOneMinute() {
        let value = AccountQuota(remainingPercent: 71, windowDurationMins: 10080,
            resetsAt: 2000, observedAt: Date(timeIntervalSince1970: 1000))
        precondition(value.isFresh(at: Date(timeIntervalSince1970: 1059)))
        precondition(!value.isFresh(at: Date(timeIntervalSince1970: 1060)), "Old snapshots must not pretend to be current")
        let resetting = AccountQuota(remainingPercent: 0, windowDurationMins: 300,
            resetsAt: 1010, observedAt: Date(timeIntervalSince1970: 1000))
        precondition(!resetting.isFresh(at: Date(timeIntervalSince1970: 1010)))
    }
    func testUsesCodexBucketAndWindowDurationRatherThanPrimaryPosition() {
        let window: (Double, Int) -> [String: Any] = { used, minutes in
            ["usedPercent": used, "windowDurationMins": minutes, "resetsAt": 2000]
        }
        let result: [String: Any] = ["rateLimitsByLimitId": [
            "codex": ["primary": window(10, 10080), "secondary": window(29, 300)],
            "spark": ["primary": window(99, 300)]]]
        let value = AccountQuota.parse(result, at: Date(timeIntervalSince1970: 1000))
        precondition(value?.remainingPercent == 71, "Use the codex five-hour window, not primary position or Spark")
        precondition(value?.windowDurationMins == 300)
    }
}
