import Foundation

enum QuotaDisplayValue {
    static func text(for percent: Double?) -> String {
        guard let percent = percent, percent.isFinite else { return "--" }
        return String(Int(max(0, min(100, percent)).rounded()))
    }
}
