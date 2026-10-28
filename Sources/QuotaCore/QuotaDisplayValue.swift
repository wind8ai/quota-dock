import Foundation

enum QuotaDisplayValue {
    static func text(for percent: Double?, exhaustionConfirmed: Bool = false) -> String {
        guard let percent = percent, percent.isFinite else { return "--" }
        let remaining = max(0, min(100, percent))
        if remaining == 0 { return exhaustionConfirmed ? "0" : "≤1" }
        return String(max(1, Int(remaining.rounded())))
    }
}
