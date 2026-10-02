import Foundation

struct QuotaReader {
    private static let sessionsURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".codex/sessions", isDirectory: true)
    private static let sessionSearchLimit = 12
    private static let resetTimeTolerance: TimeInterval = 120

    static func latestSnapshot() -> QuotaSnapshot? {
        latestSnapshot(in: sessionsURL)
    }

    static func latestSnapshot(in directory: URL) -> QuotaSnapshot? {
        let snapshots = recentSessionFiles(in: directory)
            .compactMap { snapshot(in: $0.url, fallbackDate: $0.modified) }
        guard let newestResetAt = snapshots.map(\.resetsAt).max() else { return nil }

        // Codex may report the same weekly reset timestamp a second apart across
        // sessions. Treat that jitter as one quota window, then select the most
        // recent response from that window instead of preferring the larger value.
        return snapshots
            .filter { newestResetAt - $0.resetsAt <= resetTimeTolerance }
            .max { $0.observedAt < $1.observedAt }
    }

    private static func recentSessionFiles(in directory: URL) -> [(url: URL, modified: Date)] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var sessions: [(url: URL, modified: Date)] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "jsonl" else { continue }
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true,
                  let modified = values.contentModificationDate else { continue }
            sessions.append((url, modified))
        }
        return sessions
            .sorted { $0.modified > $1.modified }
            .prefix(sessionSearchLimit)
            .map { $0 }
    }

    private static func snapshot(in url: URL, fallbackDate: Date) -> QuotaSnapshot? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { handle.closeFile() }

        let size = handle.seekToEndOfFile()
        let readLength: UInt64 = min(size, 2_000_000)
        handle.seek(toFileOffset: size - readLength)
        let data = handle.readDataToEndOfFile()
        guard let text = String(data: data, encoding: .utf8) else { return nil }

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: true).reversed() {
            guard rawLine.contains("\"rate_limits\"") else { continue }
            guard let lineData = String(rawLine).data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  object["type"] as? String == "event_msg",
                  let payload = object["payload"] as? [String: Any],
                  payload["type"] as? String == "token_count" else { continue }

            let info = payload["info"] as? [String: Any]
            let limits = (payload["rate_limits"] as? [String: Any])
                ?? (info?["rate_limits"] as? [String: Any])
            guard let resolvedLimits = limits,
                  resolvedLimits["limit_id"] as? String == "codex",
                  let primary = resolvedLimits["primary"] as? [String: Any],
                  let used = primary["used_percent"] as? NSNumber,
                  used.doubleValue.isFinite,
                  let resetsAt = primary["resets_at"] as? NSNumber else { continue }

            let observedAt = (object["timestamp"] as? String)
                .flatMap(ISO8601DateFormatter().date(from:))
                ?? fallbackDate
            return QuotaSnapshot(
                remainingPercent: max(0, min(100, 100 - used.doubleValue)),
                observedAt: observedAt,
                resetsAt: resetsAt.doubleValue
            )
        }
        return nil
    }
}
