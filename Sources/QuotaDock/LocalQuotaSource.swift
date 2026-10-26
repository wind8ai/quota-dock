import Foundation

enum LocalQuotaSource {
    static func read() -> AccountQuota? {
        let root = ProcessInfo.processInfo.environment["CODEX_HOME"]
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
        return LocalQuotaReader.latest(in: root.appendingPathComponent("sessions", isDirectory: true))
    }

    static func diagnose() -> Int32 {
        var report: [String: Any] = ["source": "local-session-log"]
        let quota = read()
        if let quota = quota {
            report["status"] = "recent-local-observation"
            report["remainingPercent"] = quota.remainingPercent
            report["period"] = quota.windowDurationMins == 300 ? "5-hour" : "weekly"
            report["windowDurationMins"] = quota.windowDurationMins
            report["observedAt"] = ISO8601DateFormatter().string(from: quota.observedAt)
            report["ageSeconds"] = max(0, Int(Date().timeIntervalSince(quota.observedAt)))
            report["resetsAt"] = quota.resetsAt
        } else {
            report["status"] = "unavailable"
            report["reason"] = "no-recent-local-observation"
        }
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys, .prettyPrinted]),
           let text = String(data: data, encoding: .utf8) { print(text) }
        return quota == nil ? 1 : 0
    }
}
