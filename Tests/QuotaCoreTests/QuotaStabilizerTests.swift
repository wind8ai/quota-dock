import Foundation

final class QuotaStabilizerTests {
    private var suite: String!
    private var defaults: UserDefaults!

    func setUp() {
        suite = "QuotaDockTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    private func snapshot(_ percent: Double, reset: Double = 1000) -> QuotaSnapshot {
        QuotaSnapshot(remainingPercent: percent, observedAt: Date(timeIntervalSince1970: 500), resetsAt: reset)
    }

    func testEmptyCacheShowsUnknown() {
        precondition(QuotaStabilizer(defaults: defaults).displayPercent(for: nil) == nil)
    }

    func testSameCycleDecreasesButDoesNotIncrease() {
        let subject = QuotaStabilizer(defaults: defaults)
        precondition(subject.displayPercent(for: snapshot(80)) == 80)
        precondition(subject.displayPercent(for: snapshot(75)) == 75)
        precondition(subject.displayPercent(for: snapshot(90)) == 75)
    }

    func testJitterBoundaryDoesNotResetCache() {
        let subject = QuotaStabilizer(defaults: defaults)
        precondition(subject.displayPercent(for: snapshot(20)) == 20)
        precondition(subject.displayPercent(for: snapshot(90, reset: 1120)) == 20)
        precondition(subject.displayPercent(for: snapshot(90, reset: 880)) == 20)
    }

    func testNewCycleCanIncreaseQuotaAndOldCycleCannotReplaceIt() {
        let subject = QuotaStabilizer(defaults: defaults)
        precondition(subject.displayPercent(for: snapshot(20)) == 20)
        precondition(subject.displayPercent(for: snapshot(95, reset: 1121)) == 95)
        precondition(subject.displayPercent(for: snapshot(10, reset: 1000)) == 95)
    }

    func testCacheSurvivesRecreationAndMissingRead() {
        _ = QuotaStabilizer(defaults: defaults).displayPercent(for: snapshot(37))
        let restarted = QuotaStabilizer(defaults: UserDefaults(suiteName: suite)!)
        precondition(restarted.displayPercent(for: nil) == 37)
        precondition(restarted.displayPercent(for: snapshot(70)) == 37)
    }

    func testReadsLegacyV2CacheSchema() throws {
        // JSONEncoder's Date representation is seconds since 2001-01-01.
        defaults.set(Data("[{\"remainingPercent\":42,\"observedAt\":0,\"resetsAt\":1000}]".utf8),
                     forKey: "quota-history-v2")
        precondition(QuotaStabilizer(defaults: defaults).displayPercent(for: nil) == 42)
    }

    func testCorruptOrInvalidCacheIsIgnored() throws {
        defaults.set(Data("broken".utf8), forKey: "quota-history-v2")
        precondition(QuotaStabilizer(defaults: defaults).displayPercent(for: nil) == nil)
        defaults.set(try JSONEncoder().encode([snapshot(101), snapshot(25, reset: -1)]),
                     forKey: "quota-history-v2")
        precondition(QuotaStabilizer(defaults: defaults).displayPercent(for: nil) == nil)
    }

    func testHistoryIsBoundedAndEqualObservationDoesNotAppend() throws {
        let subject = QuotaStabilizer(defaults: defaults)
        for value in (20...30).reversed() { _ = subject.displayPercent(for: snapshot(Double(value))) }
        _ = subject.displayPercent(for: snapshot(20))
        let history = try JSONDecoder().decode([QuotaSnapshot].self,
                                               from: defaults.data(forKey: "quota-history-v2")!)
        precondition(history.map(\.remainingPercent) == [24, 23, 22, 21, 20])
    }

    func testFractionalCacheSurvivesRestartAndOnlyDecreases() {
        _ = QuotaStabilizer(defaults: defaults).displayPercent(for: snapshot(64.3))
        let restarted = QuotaStabilizer(defaults: UserDefaults(suiteName: suite)!)
        precondition(restarted.displayPercent(for: nil) == 64.3)
        precondition(restarted.displayPercent(for: snapshot(64.4)) == 64.3)
        precondition(restarted.displayPercent(for: snapshot(64.2)) == 64.2)
    }

    func testLegacyRoundingCanBeCorrectedOnceWithinHalfPoint() {
        defaults.set(Data("[{\"remainingPercent\":64,\"observedAt\":0,\"resetsAt\":1000}]".utf8),
                     forKey: "quota-history-v2")
        let subject = QuotaStabilizer(defaults: defaults)
        precondition(subject.displayPercent(for: snapshot(64.5)) == 64)
        precondition(subject.displayPercent(for: snapshot(64.4)) == 64.4)
        let restarted = QuotaStabilizer(defaults: UserDefaults(suiteName: suite)!)
        precondition(restarted.displayPercent(for: snapshot(64.45)) == 64.4)
    }
}
