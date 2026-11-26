import Foundation
import SwiftData
import CoreLocation

enum PurchaseSource: String, Codable {
    case applePay
    case manual
}

@Model
final class Purchase {
    var date: Date = Date()
    var merchant: String = ""
    var amount: Double?
    var currencyCode: String?
    /// The amount exactly as Shortcuts sent it, kept in case it could not be parsed.
    var rawAmount: String?
    var card: String?
    var latitude: Double?
    var longitude: Double?
    var horizontalAccuracy: Double?
    var placeName: String?
    var address: String?
    var note: String = ""
    var sourceRaw: String = "applePay"

    init(
        date: Date,
        merchant: String,
        amount: Double?,
        currencyCode: String?,
        rawAmount: String?,
        card: String?,
        latitude: Double?,
        longitude: Double?,
        horizontalAccuracy: Double?,
        placeName: String?,
        address: String?,
        source: PurchaseSource
    ) {
        self.date = date
        self.merchant = merchant
        self.amount = amount
        self.currencyCode = currencyCode
        self.rawAmount = rawAmount
        self.card = card
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.placeName = placeName
        self.address = address
        self.note = ""
        self.sourceRaw = source.rawValue
    }
}

extension Purchase {
    var source: PurchaseSource { PurchaseSource(rawValue: sourceRaw) ?? .applePay }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var formattedAmount: String {
        guard let amount else { return rawAmount?.nilIfBlank ?? "—" }
        return Money.format(amount, code: currencyCode)
    }

    /// The store name if one was found, otherwise the street address.
    var locationLine: String? { placeName ?? address }

    var paymentDescription: String {
        switch source {
        case .applePay:
            if let card = card?.nilIfBlank { return "Apple Pay · \(card)" }
            return "Apple Pay"
        case .manual:
            if let card = card?.nilIfBlank { return "Added by hand · \(card)" }
            return "Added by hand"
        }
    }
}

enum Money {
    static var localCode: String { Locale.current.currency?.identifier ?? "USD" }

    static func format(_ value: Double, code: String?) -> String {
        value.formatted(.currency(code: code ?? localCode))
    }

    /// Sums purchases per currency, e.g. "$42.10" or "$12.00 + €8.50".
    static func total(_ purchases: [Purchase]) -> String {
        var sums: [String: Double] = [:]
        for purchase in purchases {
            guard let amount = purchase.amount else { continue }
            sums[purchase.currencyCode ?? localCode, default: 0] += amount
        }
        return sums
            .sorted { $0.key < $1.key }
            .map { format($0.value, code: $0.key) }
            .joined(separator: " + ")
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
