import CoreLocation
import Foundation
import SwiftData

/// Saves a purchase with the time, location and best guess at the store.
/// Used by both the Log Purchase action and the manual Add screen.
@MainActor
enum PurchaseRecorder {
    struct Input {
        var merchant: String?
        var amountText: String?
        var card: String?
        var placemark: CLPlacemark?
        var source: PurchaseSource
        var date: Date = Date()
        var useLocation: Bool = true
    }

    @discardableResult
    static func record(_ input: Input) async throws -> Purchase {
        let realMerchant = input.merchant?.nilIfBlank
        let merchant = realMerchant ?? "Unknown merchant"
        let parsed = input.amountText.flatMap { AmountParser.parse($0) }

        var fix: LocationFix?
        var place = PlaceInfo(name: nil, address: nil)

        if input.useLocation {
            if let placemark = input.placemark, let location = placemark.location {
                fix = LocationFix(location)
                place = PlaceInfo(
                    name: PlaceLookup.name(from: placemark),
                    address: PlaceLookup.address(from: placemark)
                )
            } else {
                fix = await LocationService.shared.currentFix()
            }
        }

        if let fix {
            let lat = fix.latitude
            let lon = fix.longitude
            if let realMerchant {
                let store = await PlaceLookup.withTimeout(5, {
                    await PlaceLookup.nearbyStore(matching: realMerchant, latitude: lat, longitude: lon)
                })
                if let store {
                    place.name = store.name ?? place.name
                    place.address = store.address ?? place.address
                }
            }
            if place.address == nil {
                let info = await PlaceLookup.withTimeout(4, {
                    await PlaceLookup.reverseGeocode(latitude: lat, longitude: lon)
                })
                if let info {
                    place.name = place.name ?? info.name
                    place.address = info.address
                }
            }
        }

        let purchase = Purchase(
            date: input.date,
            merchant: merchant,
            amount: parsed?.value,
            currencyCode: parsed?.currencyCode,
            rawAmount: input.amountText?.nilIfBlank,
            card: input.card?.nilIfBlank,
            latitude: fix?.latitude,
            longitude: fix?.longitude,
            horizontalAccuracy: fix?.accuracy,
            placeName: place.name,
            address: place.address,
            source: input.source
        )

        let context = PurchaseStore.container.mainContext
        context.insert(purchase)
        try context.save()
        return purchase
    }
}
