import Foundation

final class QuotaCacheTests {
    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let suite = "quota-cache-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        body(defaults)
    }

    private func reading(_ value: Double = 58, observed: Double = 1000, reset: Double = 10000) -> AccountQuota {
        AccountQuota(remainingPercent: value, windowDurationMins: 10080,
            resetsAt: reset, observedAt: Date(timeIntervalSince1970: observed))
    }

    func testPersistsAcrossRestartAndSeparatesDirectories() {
        withDefaults { defaults in
            QuotaCache(defaults: defaults, namespace: "first").update(reading(), at: Date(timeIntervalSince1970: 1000))
            let reopened = QuotaCache(defaults: defaults, namespace: "first")
            precondition(reopened.current(at: Date(timeIntervalSince1970: 2500))?.remainingPercent == 58)
            precondition(QuotaCache(defaults: defaults, namespace: "other").current(at: Date(timeIntervalSince1970: 2500)) == nil)
        }
    }

    func testMissingAndOlderObservationsDoNotRefreshCacheAge() {
        withDefaults { defaults in
            let cache = QuotaCache(defaults: defaults, namespace: "test")
            cache.update(reading(), at: Date(timeIntervalSince1970: 1000))
            cache.update(nil, at: Date(timeIntervalSince1970: 2500))
            cache.update(reading(90, observed: 900), at: Date(timeIntervalSince1970: 2500))
            precondition(cache.current(at: Date(timeIntervalSince1970: 2500))?.observedAt == Date(timeIntervalSince1970: 1000))
            cache.update(reading(72, observed: 2600), at: Date(timeIntervalSince1970: 2600))
            precondition(cache.current(at: Date(timeIntervalSince1970: 2600))?.remainingPercent == 72)
            precondition(cache.current(at: Date(timeIntervalSince1970: 2600))?.isFresh(at: Date(timeIntervalSince1970: 2600)) == true)
        }
    }

    func testEndpointConfirmationSurvivesRestartAndLegacyCacheStaysUncertain() {
        withDefaults { defaults in
            let cache = QuotaCache(defaults: defaults, namespace: "endpoint")
            let now = Date(timeIntervalSince1970: 1000)
            let legacy = reading(0)
            let encoded = try! JSONEncoder().encode(legacy)
            var object = try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]
            object.removeValue(forKey: "exhaustionConfirmed")
            let decoded = try! JSONDecoder().decode(AccountQuota.self,
                from: JSONSerialization.data(withJSONObject: object))
            precondition(decoded.exhaustionConfirmed == nil)
            cache.update(decoded, at: now)
            var confirmed = decoded
            confirmed.exhaustionConfirmed = true
            cache.update(confirmed, at: now)
            let reopened = QuotaCache(defaults: defaults, namespace: "endpoint")
            precondition(reopened.current(at: now)?.exhaustionConfirmed == true)
        }
    }

    func testResetDoesNotInventARefill() {
        withDefaults { defaults in
            let cache = QuotaCache(defaults: defaults, namespace: "test")
            cache.update(reading(reset: 3000), at: Date(timeIntervalSince1970: 1000))
            precondition(cache.current(at: Date(timeIntervalSince1970: 2999))?.remainingPercent == 58)
            precondition(cache.current(at: Date(timeIntervalSince1970: 3000)) == nil)
            cache.update(nil, at: Date(timeIntervalSince1970: 3000))
            precondition(QuotaCache(defaults: defaults, namespace: "test").current(at: Date(timeIntervalSince1970: 3001)) == nil)
        }
    }

    func testInvalidReadingsAreRejected() {
        withDefaults { defaults in
            let cache = QuotaCache(defaults: defaults, namespace: "test")
            for invalid in [reading(-1), reading(101), reading(.nan), reading(observed: 2000), reading(reset: 900)] {
                cache.update(invalid, at: Date(timeIntervalSince1970: 1000))
                precondition(cache.current(at: Date(timeIntervalSince1970: 1000)) == nil)
            }
        }
    }

    func testDiagnosticPreviewDoesNotPersist() {
        withDefaults { defaults in
            let cache = QuotaCache(defaults: defaults, namespace: "test")
            precondition(cache.preview(reading(), at: Date(timeIntervalSince1970: 1000))?.remainingPercent == 58)
            precondition(QuotaCache(defaults: defaults, namespace: "test").current(at: Date(timeIntervalSince1970: 1000)) == nil)
        }
    }
    func testIdleKeepsLastReadingWithStaleStatus() {
        let suite = "quota-cache-tests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let cache = QuotaCache(defaults: defaults, namespace: "test")
        cache.update(AccountQuota(remainingPercent: 58, windowDurationMins: 10080,
            resetsAt: 10000, observedAt: Date(timeIntervalSince1970: 1000)),
            at: Date(timeIntervalSince1970: 1000))
        let idle = cache.current(at: Date(timeIntervalSince1970: 2500))
        precondition(idle?.remainingPercent == 58, "Idle time must not erase the last known quota")
        precondition(idle?.isFresh(at: Date(timeIntervalSince1970: 2500)) == false)
    }
}
