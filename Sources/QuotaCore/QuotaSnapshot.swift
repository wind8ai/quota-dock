import Foundation

struct QuotaSnapshot: Codable {
    let remainingPercent: Double
    let observedAt: Date
    let resetsAt: TimeInterval
    // Missing in legacy integer caches; encoded on the first precise observation.
    var hasDecimalPrecision: Bool? = true
}
