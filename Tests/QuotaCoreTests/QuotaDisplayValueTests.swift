import Foundation

final class QuotaDisplayValueTests {
    func testOneDecimalWithoutPercentSign() {
        for (value, expected) in [(100.0, "100.0"), (64.0, "64.0"), (64.34, "64.3"),
                                  (32.86, "32.9"), (0.0, "0.0")] {
            precondition(QuotaDisplayValue.text(for: value) == expected)
        }
    }

    func testUnknownAndInvalidValuesHaveNoPercentSign() {
        precondition(QuotaDisplayValue.text(for: nil) == "--")
        precondition(QuotaDisplayValue.text(for: .nan) == "--")
        precondition(QuotaDisplayValue.text(for: .infinity) == "--")
    }
}
