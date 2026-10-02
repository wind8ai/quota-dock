import Foundation

final class QuotaDisplayValueTests {
    func testIntegerWithoutPercentSign() {
        for (value, expected) in [(100.0, "100"), (64.0, "64"), (64.34, "64"),
                                  (32.86, "33"), (64.5, "65"), (0.0, "0"),
                                  (-10.0, "0"), (110.0, "100")] {
            precondition(QuotaDisplayValue.text(for: value) == expected)
        }
    }

    func testUnknownAndInvalidValuesHaveNoPercentSign() {
        precondition(QuotaDisplayValue.text(for: nil) == "--")
        precondition(QuotaDisplayValue.text(for: .nan) == "--")
        precondition(QuotaDisplayValue.text(for: .infinity) == "--")
    }
}
