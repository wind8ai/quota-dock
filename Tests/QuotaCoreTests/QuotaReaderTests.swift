import Foundation

final class QuotaReaderTests {
    private var directory: URL!

    func setUp() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func tearDown() throws {
        try FileManager.default.removeItem(at: directory)
    }

    // Synthetic token_count fixtures only; never read the user's sessions.
    private func event(used: Double = 25, reset: Double = 1000,
                       id: String = "codex", nested: Bool = false,
                       timestamp: String = "2026-09-04T01:00:00Z") throws -> String {
        let limits: [String: Any] = ["limit_id": id,
            "primary": ["used_percent": used, "resets_at": reset],
            "secondary": ["used_percent": 99, "resets_at": 9999]]
        var payload: [String: Any] = ["type": "token_count"]
        if nested { payload["info"] = ["rate_limits": limits] }
        else { payload["rate_limits"] = limits }
        let data = try JSONSerialization.data(withJSONObject: [
            "type": "event_msg", "timestamp": timestamp, "payload": payload
        ])
        return String(decoding: data, as: UTF8.self)
    }

    private func write(_ text: String, name: String = "session.jsonl", modified: Double = 2000) throws {
        let file = directory.appendingPathComponent(name)
        try text.write(to: file, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: modified)],
                                              ofItemAtPath: file.path)
    }

    func testReadsMainPrimaryAndIgnoresNewerSpark() throws {
        try write(event() + "\n" + event(used: 2, id: "codex_spark"))
        precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == 75)
    }

    func testSupportsNestedRateLimits() throws {
        try write(event(used: 48, nested: true))
        precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == 52)
    }

    func testUsesLastValidEventWithinFile() throws {
        try write(event(used: 20) + "\n" + event(used: 42) + "\n{\"rate_limits\": broken\n")
        precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == 58)
    }

    func testNewResetCycleWinsOverNewerObservationOfOldCycle() throws {
        try write(event(used: 80, reset: 1000, timestamp: "2026-09-04T02:00:00Z"), name: "old.jsonl")
        try write(event(used: 5, reset: 2000), name: "new.jsonl")
        precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == 95)
    }

    func testWithin120SecondsUsesNewestObservation() throws {
        try write(event(used: 80, reset: 1000, timestamp: "2026-09-04T02:00:00Z"), name: "recent.jsonl")
        try write(event(used: 5, reset: 1120), name: "jitter.jsonl")
        precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == 20)
    }

    func testClampsAndPreservesFractionalPercent() throws {
        for (used, expected) in [(-10.0, 100.0), (110.0, 0.0), (24.4, 75.6)] {
            try write(event(used: used))
            precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == expected)
        }
    }

    func testMissingOrInvalidDataReturnsNil() throws {
        precondition(QuotaReader.latestSnapshot(in: directory) == nil)
        try write("not JSON\n{\"type\":\"event_msg\",\"payload\":{\"type\":\"token_count\",\"rate_limits\":{}}}\n")
        precondition(QuotaReader.latestSnapshot(in: directory) == nil)
        try write(event(id: "codex_spark"))
        precondition(QuotaReader.latestSnapshot(in: directory) == nil)
    }

    func testFallbackToFileModificationDate() throws {
        try write(event(timestamp: "invalid"), modified: 4567)
        precondition(QuotaReader.latestSnapshot(in: directory)?.observedAt == Date(timeIntervalSince1970: 4567))
    }

    func testOnlySearchesTwelveMostRecentlyModifiedFiles() throws {
        try write(event(), name: "old.jsonl", modified: 100)
        for index in 0..<12 {
            try write(event(id: "codex_spark"), name: "spark-\(index).jsonl", modified: Double(200 + index))
        }
        precondition(QuotaReader.latestSnapshot(in: directory) == nil)
    }

    func testReadsTailOfLargeFile() throws {
        try write(String(repeating: "x", count: 2_100_000) + "\n" + event(used: 63))
        precondition(QuotaReader.latestSnapshot(in: directory)?.remainingPercent == 37)
    }
}
