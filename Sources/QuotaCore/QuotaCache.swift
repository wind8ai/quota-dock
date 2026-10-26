import Foundation

final class QuotaCache {
    private var snapshot: AccountQuota?
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, namespace: String) {
        self.defaults = defaults
        key = "quota-last-local-observation-v1:" + namespace
        if let data = defaults.data(forKey: key) {
            snapshot = try? JSONDecoder().decode(AccountQuota.self, from: data)
        }
    }

    func update(_ observation: AccountQuota?, at now: Date) {
        let selected = preview(observation, at: now)
        guard selected != snapshot else { return }
        snapshot = selected
        if let selected = selected, let data = try? JSONEncoder().encode(selected) {
            defaults.set(data, forKey: key)
        } else { defaults.removeObject(forKey: key) }
    }

    func current(at now: Date) -> AccountQuota? {
        preview(nil, at: now)
    }

    /// Select without writing preferences, also used by read-only diagnostics.
    func preview(_ observation: AccountQuota?, at now: Date) -> AccountQuota? {
        let cached = snapshot.flatMap { $0.isUsable(at: now) ? $0 : nil }
        guard let observation = observation, observation.isUsable(at: now) else { return cached }
        guard let current = cached else { return observation }
        return observation.observedAt >= current.observedAt ? observation : current
    }
}
