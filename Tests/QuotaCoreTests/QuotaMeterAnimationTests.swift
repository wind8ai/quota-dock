import Foundation

final class QuotaMeterAnimationTests {
    func testTransitionReachesTargetInSixTenths() {
        var state = QuotaMeterAnimation()
        state.setTarget(100, animated: true)
        precondition(state.displayedPercent == 100)
        state.setTarget(20, animated: true)
        state.advance(by: 0.3, visible: true, reducedMotion: false)
        precondition(abs(state.displayedPercent! - 60) < 0.001)
        state.advance(by: 0.3, visible: true, reducedMotion: false)
        precondition(state.displayedPercent == 20)
    }

    func testHiddenStatePausesTransitionAndBubbles() {
        var state = QuotaMeterAnimation()
        state.setTarget(80, animated: false)
        state.setTarget(40, animated: true)
        let phase = state.phase
        precondition(!state.advance(by: 10, visible: false, reducedMotion: false))
        precondition(state.displayedPercent == 80 && state.phase == phase)
        state.advance(by: 0.3, visible: true, reducedMotion: false)
        precondition(abs(state.displayedPercent! - 60) < 0.001)
    }

    func testReducedMotionSnapsLevelAndFreezesPhase() {
        var state = QuotaMeterAnimation()
        state.setTarget(80, animated: false)
        state.advance(by: 0.1, visible: true, reducedMotion: false)
        state.setTarget(20, animated: true)
        state.advance(by: 0.1, visible: true, reducedMotion: true)
        precondition(state.displayedPercent == 20 && state.phase == 0)
        precondition(!state.advance(by: 5, visible: true, reducedMotion: true))
    }

    func testRetargetingStartsAtCurrentLevel() {
        var state = QuotaMeterAnimation()
        state.setTarget(100, animated: false)
        state.setTarget(0, animated: true)
        state.advance(by: 0.3, visible: true, reducedMotion: false)
        state.setTarget(80, animated: true)
        precondition(abs(state.displayedPercent! - 50) < 0.001)
        state.advance(by: 0.6, visible: true, reducedMotion: false)
        precondition(state.displayedPercent == 80)
    }

    func testZeroAndUnknownStopAmbientAnimation() {
        var state = QuotaMeterAnimation()
        state.setTarget(0, animated: false)
        precondition(!state.advance(by: 1, visible: true, reducedMotion: false))
        precondition(state.displayedPercent == 0)
        state.setTarget(nil, animated: true)
        precondition(!state.advance(by: 1, visible: true, reducedMotion: false))
        precondition(state.displayedPercent == nil && state.targetPercent == nil)
    }

    func testFractionalTargetSurvivesTransition() {
        var state = QuotaMeterAnimation()
        state.setTarget(64.3, animated: false)
        state.setTarget(63.7, animated: true)
        state.advance(by: 0.6, visible: true, reducedMotion: false)
        precondition(abs(state.displayedPercent! - 63.7) < 0.000001)
        precondition(state.targetPercent == 63.7)
    }
}
