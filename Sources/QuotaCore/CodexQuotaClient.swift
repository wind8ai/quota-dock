import Foundation
import Darwin

enum QuotaReadError: String, Error {
    case executableMissing, timeout, transport, protocolFailure, authenticationRequired, identityChanged, unavailable
}

struct CodexQuotaClient {
    let executable: URL
    var arguments = ["app-server", "--stdio"]
    var timeout: TimeInterval = 15

    func read() -> Result<AccountQuota, QuotaReadError> {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else { return .failure(.executableMissing) }
        let process = Process()
        let input = Pipe(), output = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return .failure(.transport) }
        let writer = input.fileHandleForWriting
        _ = fcntl(writer.fileDescriptor, F_SETNOSIGPIPE, 1)
        defer {
            writer.closeFile()
            let eofGrace = ProcessInfo.processInfo.systemUptime + 0.5
            while process.isRunning && ProcessInfo.processInfo.systemUptime < eofGrace { usleep(10_000) }
            if process.isRunning { process.terminate() }
            let grace = ProcessInfo.processInfo.systemUptime + 1
            while process.isRunning && ProcessInfo.processInfo.systemUptime < grace { usleep(10_000) }
            if process.isRunning { _ = Darwin.kill(process.processIdentifier, SIGKILL) }
            output.fileHandleForReading.closeFile()
        }
        func send(_ message: [String: Any]) throws {
            var data = try JSONSerialization.data(withJSONObject: message, options: [.sortedKeys])
            data.append(10)
            try writer.write(contentsOf: data)
        }
        do {
            try send(["id": 1, "method": "initialize", "params": ["clientInfo": ["name": "quota_dock", "version": "3.1.0"]]])
        } catch { return .failure(.transport) }

        var expectedID = 1
        var identity: String?
        var pendingQuota: AccountQuota?
        var buffer = Data()
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        while ProcessInfo.processInfo.systemUptime < deadline {
            var descriptor = pollfd(fd: output.fileHandleForReading.fileDescriptor,
                                    events: Int16(POLLIN | POLLHUP), revents: 0)
            let wait = Int32(max(1, min(250, (deadline - ProcessInfo.processInfo.systemUptime) * 1000)))
            let ready = poll(&descriptor, 1, wait)
            if ready < 0 {
                if errno == EINTR { continue }
                return .failure(.transport)
            }
            if ready == 0 { continue }
            if descriptor.revents & Int16(POLLERR | POLLNVAL) != 0 { return .failure(.transport) }
            var chunk = [UInt8](repeating: 0, count: 8192)
            let count = Darwin.read(descriptor.fd, &chunk, chunk.count)
            if count <= 0 {
                if count < 0 && errno == EINTR { continue }
                return .failure(.transport)
            }
            buffer.append(contentsOf: chunk.prefix(count))
            guard buffer.count <= 1_000_000 else { return .failure(.protocolFailure) }
            while let newline = buffer.firstIndex(of: 10) {
                let line = Data(buffer[..<newline])
                buffer.removeSubrange(...newline)
                guard !line.isEmpty else { continue }
                guard let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else {
                    return .failure(.protocolFailure)
                }
                // Notifications contain no response id. Server requests are not
                // authorized: this client implements only the read-only protocol.
                if message["method"] != nil {
                    if let id = message["id"] {
                        try? send(["id": id, "error": ["code": -32601, "message": "Unsupported server request"]])
                    }
                    continue
                }
                guard (message["id"] as? NSNumber)?.intValue == expectedID else { continue }
                if message["error"] != nil {
                    return .failure(expectedID == 2 || expectedID == 4 ? .authenticationRequired : .unavailable)
                }
                guard let result = message["result"] as? [String: Any] else { return .failure(.protocolFailure) }
                do {
                    switch expectedID {
                    case 1:
                        try send(["method": "initialized"])
                        expectedID = 2
                        try send(["id": 2, "method": "account/read", "params": ["refreshToken": false]])
                    case 2:
                        guard let account = Self.identity(in: result) else { return .failure(.authenticationRequired) }
                        identity = account
                        expectedID = 3
                        try send(["id": 3, "method": "account/rateLimits/read"])
                    case 3:
                        guard let quota = AccountQuota.parse(result, at: Date()) else { return .failure(.unavailable) }
                        pendingQuota = quota
                        expectedID = 4
                        try send(["id": 4, "method": "account/read", "params": ["refreshToken": false]])
                    case 4:
                        guard let account = Self.identity(in: result), account == identity else { return .failure(.identityChanged) }
                        guard let quota = pendingQuota, quota.isFresh(at: Date()) else { return .failure(.unavailable) }
                        return .success(quota)
                    default:
                        return .failure(.protocolFailure)
                    }
                } catch { return .failure(.transport) }
            }
        }
        return .failure(.timeout)
    }

    private static func identity(in result: [String: Any]) -> String? {
        guard let account = result["account"] as? [String: Any],
              account["type"] as? String == "chatgpt",
              let email = account["email"] as? String, !email.isEmpty else { return nil }
        // Kept only in memory for the two-read comparison, never logged/cached.
        return email + "|" + (account["planType"] as? String ?? "")
    }
}
