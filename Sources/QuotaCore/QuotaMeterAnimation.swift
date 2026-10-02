import Foundation

/// Uses elapsed visible time so hiding a window also pauses bubbles and transitions.
struct QuotaMeterAnimation {
    private(set) var targetPercent: Double?
    private(set) var displayedPercent: Double?
    var phase: Double = 0
    private var transitionFrom: Double = 0
    private var elapsed: Double = 0.6
    private let duration: Double = 0.6

    mutating func setTarget(_ percent: Double?, animated: Bool) {
        let target = percent.map { max(0, min(100, $0)) }
        guard target != targetPercent else { return }
        let previous = displayedPercent
        targetPercent = target
        if animated, let previous = previous, target != nil {
            transitionFrom = previous
            elapsed = 0
        } else {
            displayedPercent = target
            elapsed = duration
        }
    }

    @discardableResult
    mutating func advance(by delta: Double, visible: Bool, reducedMotion: Bool) -> Bool {
        guard visible else { return false }
        if reducedMotion {
            let changed = displayedPercent != targetPercent || phase != 0
            displayedPercent = targetPercent
            elapsed = duration
            phase = 0
            return changed
        }
        let delta = max(0, delta)
        var changed = false
        if let target = targetPercent, elapsed < duration {
            elapsed = min(duration, elapsed + delta)
            let progress = elapsed / duration
            let eased = progress * progress * (3 - 2 * progress)
            displayedPercent = transitionFrom + (target - transitionFrom) * eased
            changed = true
        }
        if let displayed = displayedPercent, displayed > 0, delta > 0 {
            phase = (phase + delta * .pi * 2 / 3).truncatingRemainder(dividingBy: .pi * 2)
            changed = true
        }
        return changed
    }
}
