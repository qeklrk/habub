// Quick checks for AmountParser. Run on a Mac from the taptrail folder:
//   swiftc -o /tmp/amount-checks TapTrail/Model/AmountParser.swift Tests/main.swift && /tmp/amount-checks
import Foundation

var failures = 0
let us = Locale(identifier: "en_US")

func check(_ input: String, _ value: Double?, _ code: String?, line: Int = #line) {
    let result = AmountParser.parse(input, locale: us)
    let ok: Bool
    if let value {
        ok = result.map { abs($0.value - value) < 0.0001 && $0.currencyCode == code } ?? false
    } else {
        ok = result == nil
    }
    if !ok {
        failures += 1
        print("FAIL line \(line): \"\(input)\" -> \(String(describing: result)), expected \(String(describing: value)) \(code ?? "nil")")
    }
}

check("$4.50", 4.5, "USD")
check("4,50 €", 4.5, "EUR")
check("€4.5", 4.5, "EUR")
check("£1,234.56", 1234.56, "GBP")
check("1.234,56 EUR", 1234.56, "EUR")
check("¥1,200", 1200, "JPY")
check("CA$12.00", 12, "CAD")
check("US$ 7.99", 7.99, "USD")
check("A$5", 5, "AUD")
check("USD 19.99", 19.99, "USD")
check("12", 12, nil)
check("0.99", 0.99, nil)
check("-$3.25", -3.25, "USD")
check("$1,000,000.00", 1_000_000, "USD")
check("", nil, nil)
check("free", nil, nil)

if failures > 0 {
    print("\(failures) check(s) failed")
    exit(1)
}
print("All amount checks passed")
