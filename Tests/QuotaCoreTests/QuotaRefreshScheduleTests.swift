import Foundation

final class QuotaRefreshScheduleTests {
    func testHiddenWindowSlowsPollingAndRevealChecksImmediately() {
        var schedule = QuotaRefreshSchedule()
        precondition(schedule.beginIfDue(at: 0, targetVisible: false))
        schedule.completed(at: 1, succeeded: true)
        precondition(!schedule.beginIfDue(at: 29, targetVisible: false))
        precondition(schedule.beginIfDue(at: 30, targetVisible: false))
        schedule.completed(at: 31, succeeded: true)
        precondition(schedule.beginIfDue(at: 36, targetVisible: true))
    }

    func testInFlightAndWakeNeverOverlapRequests() {
        var schedule = QuotaRefreshSchedule()
        precondition(schedule.beginIfDue(at: 0, targetVisible: true))
        precondition(!schedule.beginIfDue(at: 5, targetVisible: true))
        schedule.woke()
        precondition(!schedule.beginIfDue(at: 100, targetVisible: true))
        schedule.completed(at: 100, succeeded: true)
        precondition(schedule.beginIfDue(at: 100, targetVisible: true))
    }

    func testFailuresBackOffAndSuccessRestoresFastPolling() {
        var schedule = QuotaRefreshSchedule()
        let starts: [TimeInterval] = [0, 5, 15, 35, 75, 135]
        for (index, time) in starts.enumerated() {
            if index > 0 { precondition(!schedule.beginIfDue(at: time - 0.1, targetVisible: true)) }
            precondition(schedule.beginIfDue(at: time, targetVisible: true))
            schedule.completed(at: time, succeeded: index == starts.count - 1)
        }
        precondition(schedule.beginIfDue(at: 140, targetVisible: true))
    }
    func testVisibleQuotaRefreshDoesNotWaitThirtySeconds() {
        var schedule = QuotaRefreshSchedule()
        precondition(schedule.beginIfDue(at: 0, targetVisible: true))
        schedule.completed(at: 2.6, succeeded: true)
        precondition(!schedule.beginIfDue(at: 4.9, targetVisible: true))
        precondition(schedule.beginIfDue(at: 5, targetVisible: true),
                     "Visible quota must refresh after five seconds, not wait thirty")
    }
}
