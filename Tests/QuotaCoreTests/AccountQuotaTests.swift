import Foundation

final class AccountQuotaTests {
    private func legacy(_ used: Any, duration: Int = 10080, reset: Double = 2000) -> [String: Any] {
        ["limit_id": "codex", "primary": ["used_percent": used,
            "window_minutes": duration, "resets_at": reset]]
    }

    func testWeeklyOnlyAndServerCorrectionsRemainAuthoritative() {
        let now = Date(timeIntervalSince1970: 1000)
        precondition(AccountQuota.parseLimits(legacy(40), observedAt: now)?.remainingPercent == 60)
        let corrected = AccountQuota.parseLimits(legacy(29.25), observedAt: now)
        precondition(corrected?.remainingPercent == 70.75)
        precondition(corrected?.windowDurationMins == 10080)
    }

    func testRejectsNonCodexBucket() {
        var result = legacy(10)
        result["limit_id"] = "spark"
        precondition(AccountQuota.parseLimits(result, observedAt: Date(timeIntervalSince1970: 1000)) == nil)
    }

    func testOnlyExplicitPlanLimitConfirmsExhaustion() {
        let now = Date(timeIntervalSince1970: 1000)
        var limits = legacy(100)
        precondition(AccountQuota.parseLimits(limits, observedAt: now)?.exhaustionConfirmed != true)
        limits["rate_limit_reached_type"] = NSNull()
        precondition(AccountQuota.parseLimits(limits, observedAt: now)?.exhaustionConfirmed != true)
        limits["rate_limit_reached_type"] = "workspace_member_usage_limit_reached"
        precondition(AccountQuota.parseLimits(limits, observedAt: now)?.exhaustionConfirmed != true)
        limits["rate_limit_reached_type"] = "rate_limit_reached"
        precondition(AccountQuota.parseLimits(limits, observedAt: now)?.exhaustionConfirmed == true)
    }

    func testRejectsInvalidExpiredAndUnsupportedWindows() {
        let now = Date(timeIntervalSince1970: 1000)
        for used: Any in [true, "29", Double.nan, Double.infinity, -1] {
            precondition(AccountQuota.parseLimits(legacy(used), observedAt: now) == nil)
        }
        precondition(AccountQuota.parseLimits(legacy(20, reset: 1000), observedAt: now) == nil)
        precondition(AccountQuota.parseLimits(legacy(20, duration: 15), observedAt: now) == nil)
        precondition(AccountQuota.parseLimits([:], observedAt: now) == nil)
        precondition(AccountQuota.parseLimits(legacy(120), observedAt: now)?.remainingPercent == 0)
    }
    func testFreshnessExpiresAtResetOrAfterFifteenMinutes() {
        let value = AccountQuota(remainingPercent: 71, windowDurationMins: 10080,
            resetsAt: 2000, observedAt: Date(timeIntervalSince1970: 1000))
        precondition(value.isFresh(at: Date(timeIntervalSince1970: 1899)))
        precondition(!value.isFresh(at: Date(timeIntervalSince1970: 1900)), "Old snapshots must not pretend to be current")
        let resetting = AccountQuota(remainingPercent: 0, windowDurationMins: 300,
            resetsAt: 1010, observedAt: Date(timeIntervalSince1970: 1000))
        precondition(!resetting.isFresh(at: Date(timeIntervalSince1970: 1010)))
    }
    func testUsesCodexBucketAndWindowDurationRatherThanPrimaryPosition() {
        let window: (Double, Int) -> [String: Any] = { used, minutes in
            ["used_percent": used, "window_minutes": minutes, "resets_at": 2000]
        }
        let result: [String: Any] = ["limit_id": "codex",
            "primary": window(10, 10080), "secondary": window(29, 300)]
        let value = AccountQuota.parseLimits(result, observedAt: Date(timeIntervalSince1970: 1000))
        precondition(value?.remainingPercent == 71, "Use the codex five-hour window, not primary position or Spark")
        precondition(value?.windowDurationMins == 300)
    }
}
