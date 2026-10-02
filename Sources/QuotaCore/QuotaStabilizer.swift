import Foundation

final class QuotaStabilizer {
    private static let historyKey = "quota-history-v2"
    private static let historyLimit = 5
    private static let resetTimeTolerance: TimeInterval = 120

    private let defaults: UserDefaults
    private var history: [QuotaSnapshot]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.historyKey),
           let decoded = try? JSONDecoder().decode([QuotaSnapshot].self, from: data) {
            history = Array(decoded
                .filter { (0...100).contains($0.remainingPercent) && $0.resetsAt > 0 }
                .suffix(Self.historyLimit))
        } else {
            history = []
        }
    }

    func displayPercent(for observed: QuotaSnapshot?) -> Double? {
        guard let observed = observed else {
            return history.last?.remainingPercent
        }

        guard let cached = history.last else {
            cache(observed)
            return observed.remainingPercent
        }

        let resetDelta = observed.resetsAt - cached.resetsAt
        if resetDelta > Self.resetTimeTolerance {
            cache(observed)
            return observed.remainingPercent
        }

        if resetDelta < -Self.resetTimeTolerance {
            return cached.remainingPercent
        }

        // Within one weekly window, remaining quota only decreases. A larger
        // value from another session is stale and must not replace the cache.
        // A legacy rounded value represents a half-point interval. Allow its
        // first precise replacement inside that interval, then resume monotonicity.
        let correctsLegacyRounding = cached.hasDecimalPrecision != true
            && observed.hasDecimalPrecision == true
            && observed.remainingPercent < cached.remainingPercent + 0.5
        guard observed.remainingPercent <= cached.remainingPercent || correctsLegacyRounding else {
            return cached.remainingPercent
        }

        cache(observed)
        return observed.remainingPercent
    }

    private func cache(_ snapshot: QuotaSnapshot) {
        if let last = history.last,
           abs(last.resetsAt - snapshot.resetsAt) <= Self.resetTimeTolerance,
           last.remainingPercent == snapshot.remainingPercent {
            history[history.count - 1] = snapshot
        } else {
            history.append(snapshot)
        }
        history = Array(history.suffix(Self.historyLimit))
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: Self.historyKey)
        }
    }
}
