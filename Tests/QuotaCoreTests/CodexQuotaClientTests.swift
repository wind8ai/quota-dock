import Foundation

final class CodexQuotaClientTests {
    func testRejectsAccountChange() {
        guard case .failure(.identityChanged) = client("changed").read() else {
            preconditionFailure("Never publish another account's in-flight reading")
        }
    }

    func testTimeoutAndProtocolErrorsAreBounded() {
        let start = ProcessInfo.processInfo.systemUptime
        guard case .failure(.timeout) = client("timeout", timeout: 0.2).read() else {
            preconditionFailure("Unresponsive quota source must time out")
        }
        precondition(ProcessInfo.processInfo.systemUptime - start < 3)
        guard case .failure(.protocolFailure) = client("malformed").read() else { preconditionFailure("Malformed JSON") }
        guard case .failure(.transport) = client("exit").read() else { preconditionFailure("Unexpected process exit") }
        guard case .failure(.authenticationRequired) = client("auth").read() else { preconditionFailure("Missing login") }
    }
    private func client(_ mode: String, timeout: TimeInterval = 3) -> CodexQuotaClient {
        let fixture = URL(fileURLWithPath: #file).deletingLastPathComponent()
            .appendingPathComponent("fixtures/quota-rpc.sh")
        return CodexQuotaClient(executable: URL(fileURLWithPath: "/bin/sh"),
            arguments: [fixture.path, mode], timeout: timeout)
    }

    func testReadsOfficialProtocolAndIgnoresNotifications() {
        guard case .success(let quota) = client("valid").read() else {
            preconditionFailure("Initialized account quota protocol must produce a live snapshot")
        }
        precondition(quota.remainingPercent == 71 && quota.windowDurationMins == 10080)
    }
}
