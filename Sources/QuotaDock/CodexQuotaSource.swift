import AppKit

enum CodexQuotaSource {
    static func executable() -> URL? {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? ""
        var candidates = path.split(separator: ":").map { String($0) + "/codex" }
        candidates += ["/opt/homebrew/bin/codex", "/usr/local/bin/codex"]
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.openai.codex") {
            candidates.append(app.appendingPathComponent("Contents/Resources/codex-cli/bin/codex").path)
            candidates.append(app.appendingPathComponent("Contents/Resources/codex").path)
        }
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
            .map { URL(fileURLWithPath: $0) }
    }

    static func read() -> Result<AccountQuota, QuotaReadError> {
        guard let executable = executable() else { return .failure(.executableMissing) }
        return CodexQuotaClient(executable: executable).read()
    }

    static func diagnose() -> Int32 {
        var report: [String: Any] = ["source": "codex-app-server/account/rateLimits/read"]
        let status: Int32
        switch read() {
        case .success(let quota):
            report["status"] = "live"
            report["remainingPercent"] = quota.remainingPercent
            report["windowDurationMins"] = quota.windowDurationMins
            report["period"] = quota.windowDurationMins == 300 ? "5-hour" : "weekly"
            report["resetsAt"] = quota.resetsAt
            report["observedAt"] = ISO8601DateFormatter().string(from: quota.observedAt)
            status = 0
        case .failure(let error):
            report["status"] = "unavailable"
            report["reason"] = error.rawValue
            status = 1
        }
        if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys, .prettyPrinted]),
           let text = String(data: data, encoding: .utf8) { print(text) }
        return status
    }
}
