import Foundation

final class QuotaDisplayValueTests {
    func testIntegerWithoutPercentSign() {
        for (value, expected) in [(100.0, "100"), (64.0, "64"), (64.34, "64"),
                                  (32.86, "33"), (64.5, "65"), (0.0, "≤1"),
                                  (-10.0, "≤1"), (110.0, "100")] {
            precondition(QuotaDisplayValue.text(for: value) == expected)
        }
    }

    func testLastPercentDoesNotClaimExhaustion() {
        precondition(QuotaDisplayValue.text(for: 0) == "≤1",
                     "A local 100%-used receipt does not confirm exhaustion")
        for value in [0.01, 0.49, 0.5, 0.99, 1.0] {
            precondition(QuotaDisplayValue.text(for: value) == "1",
                         "A positive remainder must never display as exhausted")
        }
    }

    func testZeroRequiresConfirmedExhaustion() {
        precondition(QuotaDisplayValue.text(for: 0, exhaustionConfirmed: true) == "0")
        precondition(QuotaDisplayValue.text(for: 0.1, exhaustionConfirmed: true) == "1")
        precondition(QuotaDisplayValue.text(for: nil, exhaustionConfirmed: true) == "--")
    }

    func testUnknownAndInvalidValuesHaveNoPercentSign() {
        precondition(QuotaDisplayValue.text(for: nil) == "--")
        precondition(QuotaDisplayValue.text(for: .nan) == "--")
        precondition(QuotaDisplayValue.text(for: .infinity) == "--")
    }
}
