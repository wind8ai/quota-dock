import Foundation

final class LocalQuotaReaderTests {
    private func directory(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }

    private func event(_ used: Double = 25, at time: Double = 1000.125,
                       reset: Double = 5000, bucket: String = "codex", nested: Bool = false) throws -> Data {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let limits: [String: Any] = ["limit_id": bucket, "primary": [
            "used_percent": used, "window_minutes": 10080, "resets_at": reset]]
        var payload: [String: Any] = ["type": "token_count"]
        if nested { payload["info"] = ["rate_limits": limits] } else { payload["rate_limits"] = limits }
        var data = try JSONSerialization.data(withJSONObject: [
            "type": "event_msg", "timestamp": formatter.string(from: Date(timeIntervalSince1970: time)),
            "payload": payload])
        data.append(10)
        return data
    }

    func testReadsRecentLocalQuotaWithoutCLI() throws {
        try directory { root in
            try event().write(to: root.appendingPathComponent("session.jsonl"))
            let value = LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1001))
            precondition(value?.remainingPercent == 75)
            precondition(value?.observedAt == Date(timeIntervalSince1970: 1000.125))
        }
    }

    func testNewestObservationWinsOverFileModificationAndReset() throws {
        try directory { root in
            let old = root.appendingPathComponent("old.jsonl"), new = root.appendingPathComponent("new.jsonl")
            try event(80, at: 1000, reset: 9999).write(to: old)
            try event(20, at: 1001).write(to: new)
            try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 3000)], ofItemAtPath: old.path)
            try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 2000)], ofItemAtPath: new.path)
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1002))?.remainingPercent == 80)
        }
    }

    func testNestedReceiptsIgnoreNewerSpark() throws {
        try directory { root in
            var data = try event(25, nested: true)
            data.append(try event(99, at: 1001, bucket: "spark"))
            try data.write(to: root.appendingPathComponent("session.jsonl"))
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1002))?.remainingPercent == 75)
        }
    }

    func testNewerCorrectionCanIncreaseRemaining() throws {
        try directory { root in
            var data = try event(80, at: 1000)
            data.append(try event(70, at: 1001))
            try data.write(to: root.appendingPathComponent("session.jsonl"))
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1002))?.remainingPercent == 30)
        }
    }

    func testExpiredNewestDoesNotResurrectOlderWindow() throws {
        try directory { root in
            var data = try event(25, at: 1000)
            data.append(try event(90, at: 1001, reset: 1002))
            try data.write(to: root.appendingPathComponent("session.jsonl"))
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1003)) == nil)
        }
    }

    func testRejectsOldFutureAndMissingTimestamp() throws {
        try directory { root in
            let file = root.appendingPathComponent("session.jsonl")
            try event(at: 1000).write(to: file)
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1900)) == nil)
            try event(at: 2000).write(to: file)
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1000)) == nil)
            var object = try JSONSerialization.jsonObject(with: event()) as! [String: Any]
            object.removeValue(forKey: "timestamp")
            try JSONSerialization.data(withJSONObject: object).write(to: file)
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1001)) == nil)
        }
    }

    func testTruncatedUTF8AndPartialJSONDoNotHideValidTail() throws {
        try directory { root in
            var data = Data(repeating: 0xff, count: 2_000_000)
            data.append(10)
            data.append(try event())
            data.append(Data("{\"rate_limits\":".utf8))
            try data.write(to: root.appendingPathComponent("session.jsonl"))
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1001))?.remainingPercent == 75)
        }
    }

    func testOnlyTwelveRecentFilesAreRead() throws {
        try directory { root in
            for i in 0..<13 {
                let file = root.appendingPathComponent("\(i).jsonl")
                try event(bucket: i == 0 ? "codex" : "spark").write(to: file)
                try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: Double(i))], ofItemAtPath: file.path)
            }
            precondition(LocalQuotaReader.latest(in: root, now: Date(timeIntervalSince1970: 1001)) == nil)
        }
    }
}
