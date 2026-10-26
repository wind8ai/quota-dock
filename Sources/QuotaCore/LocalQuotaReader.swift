import Foundation

enum LocalQuotaReader {
    private static let fractional: ISO8601DateFormatter = {
        let value = ISO8601DateFormatter()
        value.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return value
    }()
    private static let wholeSeconds = ISO8601DateFormatter()

    static func latest(in directory: URL, now: Date = Date()) -> AccountQuota? {
        let keys: [URLResourceKey] = [.isRegularFileKey, .isSymbolicLinkKey, .contentModificationDateKey]
        guard let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return nil }
        var candidates: [(url: URL, modified: Date)] = []
        for case let url as URL in files {
            guard url.pathExtension == "jsonl",
                  let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true, values.isSymbolicLink != true,
                  let modified = values.contentModificationDate else { continue }
            candidates.append((url, modified))
        }
        candidates.sort { $0.modified == $1.modified ? $0.url.path < $1.url.path : $0.modified > $1.modified }
        var newest: (date: Date, quota: AccountQuota?)?
        for file in candidates.prefix(12) {
            guard let handle = try? FileHandle(forReadingFrom: file.url) else { continue }
            defer { handle.closeFile() }
            let data: Data
            do {
                let size = try handle.seekToEnd()
                try handle.seek(toOffset: size > 2_000_000 ? size - 2_000_000 : 0)
                data = try handle.readToEnd() ?? Data()
            } catch { continue }
            // A bounded tail may start inside UTF-8 or a JSON line. Decode it
            // lossily and ignore malformed lines instead of discarding the tail.
            for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
                guard line.contains("\"rate_limits\""),
                      let event = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
                      event["type"] as? String == "event_msg",
                      let payload = event["payload"] as? [String: Any],
                      payload["type"] as? String == "token_count",
                      let limits = (payload["rate_limits"] as? [String: Any])
                        ?? ((payload["info"] as? [String: Any])?["rate_limits"] as? [String: Any]),
                      limits["limit_id"] as? String == "codex",
                      let timestamp = event["timestamp"] as? String,
                      let observed = fractional.date(from: timestamp) ?? wholeSeconds.date(from: timestamp),
                      observed <= now else { continue }
                if newest == nil || observed > newest!.date {
                    newest = (observed, AccountQuota.parseLimits(limits, observedAt: observed))
                }
            }
        }
        guard let quota = newest?.quota, quota.isUsable(at: now) else { return nil }
        return quota
    }
}
