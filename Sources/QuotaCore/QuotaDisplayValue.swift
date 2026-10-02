import Foundation

enum QuotaDisplayValue {
    static func text(for percent: Double?) -> String {
        guard let percent = percent, percent.isFinite else { return "--" }
        return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"),
                      max(0, min(100, percent)))
    }
}
