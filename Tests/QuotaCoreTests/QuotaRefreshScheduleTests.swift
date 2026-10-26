import Foundation

final class QuotaRefreshScheduleTests {
    func testHiddenWindowSlowsPollingAndRevealChecksImmediately() {
        var schedule = QuotaRefreshSchedule()
        precondition(schedule.beginIfDue(at: 0, targetVisible: false))
        schedule.completed()
        precondition(!schedule.beginIfDue(at: 29, targetVisible: false))
        precondition(schedule.beginIfDue(at: 30, targetVisible: false))
        schedule.completed()
        precondition(schedule.beginIfDue(at: 36, targetVisible: true))
    }

    func testInFlightAndWakeNeverOverlapRequests() {
        var schedule = QuotaRefreshSchedule()
        precondition(schedule.beginIfDue(at: 0, targetVisible: true))
        precondition(!schedule.beginIfDue(at: 5, targetVisible: true))
        schedule.woke()
        precondition(!schedule.beginIfDue(at: 100, targetVisible: true))
        schedule.completed()
        precondition(schedule.beginIfDue(at: 100, targetVisible: true))
    }
    func testVisibleQuotaRefreshDoesNotWaitThirtySeconds() {
        var schedule = QuotaRefreshSchedule()
        precondition(schedule.beginIfDue(at: 0, targetVisible: true))
        schedule.completed()
        precondition(!schedule.beginIfDue(at: 4.9, targetVisible: true))
        precondition(schedule.beginIfDue(at: 5, targetVisible: true),
                     "Visible quota must refresh after five seconds, not wait thirty")
    }
}
