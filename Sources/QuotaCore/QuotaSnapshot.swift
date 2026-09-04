import Foundation

struct QuotaSnapshot: Codable {
    let remainingPercent: Int
    let observedAt: Date
    let resetsAt: TimeInterval
}
