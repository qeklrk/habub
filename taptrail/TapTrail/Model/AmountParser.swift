import Foundation

/// The amount Shortcuts hands over is text such as "$4.50", "4,50 €" or "£1,234.56".
/// This turns it into a number plus an ISO currency code when one can be worked out.
struct ParsedAmount: Equatable {
    var value: Double
    var currencyCode: String?
}

enum AmountParser {
    /// Prefixed dollar symbols come first so "US$" is not read as "S$".
    private static let symbolCodes: [(symbol: String, code: String)] = [
        ("US$", "USD"), ("CA$", "CAD"), ("AU$", "AUD"), ("NZ$", "NZD"), ("HK$", "HKD"),
        ("MX$", "MXN"), ("C$", "CAD"), ("A$", "AUD"), ("S$", "SGD"), ("R$", "BRL"),
        ("€", "EUR"), ("£", "GBP"), ("¥", "JPY"), ("₹", "INR"), ("₩", "KRW"),
        ("₽", "RUB"), ("₺", "TRY"), ("฿", "THB"), ("₪", "ILS"), ("₫", "VND"),
        ("₱", "PHP"), ("zł", "PLN"),
    ]

    private static let isoCodes = Set(Locale.Currency.isoCurrencies.map(\.identifier))

    static func parse(_ text: String, locale: Locale = .current) -> ParsedAmount? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let value = number(in: trimmed) else { return nil }
        return ParsedAmount(value: value, currencyCode: currency(in: trimmed, locale: locale))
    }

    static func currency(in text: String, locale: Locale = .current) -> String? {
        for word in text.uppercased().split(whereSeparator: { !$0.isLetter }) where word.count == 3 {
            let code = String(word)
            if isoCodes.contains(code) { return code }
        }
        for entry in symbolCodes where text.contains(entry.symbol) {
            return entry.code
        }
        if text.contains("$") {
            if let local = locale.currency?.identifier, (locale.currencySymbol ?? "").contains("$") {
                return local
            }
            return "USD"
        }
        return nil
    }

    static func number(in text: String) -> Double? {
        let negative = text.contains("-") || text.contains("−")
        let kept = text.filter { $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") }
        let core = kept.trimmingCharacters(in: CharacterSet(charactersIn: ".,"))
        guard core.contains(where: \.isNumber) else { return nil }

        // Work out which mark (if any) is the decimal separator.
        var decimalMark: Character?
        let lastDot = core.lastIndex(of: ".")
        let lastComma = core.lastIndex(of: ",")
        if let dot = lastDot, let comma = lastComma {
            decimalMark = dot > comma ? "." : ","
        } else if let mark = lastDot ?? lastComma {
            let char = core[mark]
            let occurrences = core.filter { $0 == char }.count
            let digitsAfter = core.distance(from: core.index(after: mark), to: core.endIndex)
            // "4.50" or "4,5" is a decimal; "1,234" or "1.234.567" is grouping.
            if occurrences == 1 && digitsAfter != 3 {
                decimalMark = char
            }
        }

        var normalized = ""
        for char in core {
            if char.isNumber {
                normalized.append(char)
            } else if char == decimalMark {
                normalized.append(".")
            }
        }
        guard let value = Double(normalized) else { return nil }
        return negative ? -value : value
    }
}
