import CoreLocation
import MapKit

struct PlaceInfo: Sendable {
    var name: String?
    var address: String?
}

enum PlaceLookup {
    static func address(from placemark: CLPlacemark) -> String? {
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        let parts = [street.nilIfBlank, placemark.locality, placemark.administrativeArea, placemark.postalCode]
            .compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// A point-of-interest name such as "Union Square", but not a plain street address.
    static func name(from placemark: CLPlacemark) -> String? {
        if let area = placemark.areasOfInterest?.first { return area }
        guard let name = placemark.name?.nilIfBlank else { return nil }
        if let address = address(from: placemark), address.contains(name) { return nil }
        return name
    }

    static func reverseGeocode(latitude: Double, longitude: Double) async -> PlaceInfo? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return nil
        }
        return PlaceInfo(name: name(from: placemark), address: address(from: placemark))
    }

    /// Looks for a store with the merchant's name close to where you were standing,
    /// so "STARBUCKS #1234" becomes the actual Starbucks and its address.
    static func nearbyStore(
        matching merchant: String,
        latitude: Double,
        longitude: Double,
        within maxDistance: CLLocationDistance = 250
    ) async -> PlaceInfo? {
        let here = CLLocation(latitude: latitude, longitude: longitude)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = cleanMerchantName(merchant)
        request.region = MKCoordinateRegion(
            center: here.coordinate,
            latitudinalMeters: maxDistance * 3,
            longitudinalMeters: maxDistance * 3
        )
        request.resultTypes = .pointOfInterest

        guard let response = try? await MKLocalSearch(request: request).start() else { return nil }

        var best: (item: MKMapItem, distance: CLLocationDistance)?
        for item in response.mapItems {
            guard let spot = item.placemark.location else { continue }
            let distance = spot.distance(from: here)
            if distance <= maxDistance, distance < (best?.distance ?? .infinity) {
                best = (item, distance)
            }
        }
        guard let match = best?.item else { return nil }
        return PlaceInfo(name: match.name, address: address(from: match.placemark))
    }

    /// Card statements often add store numbers ("TARGET T-1234"); drop them before searching.
    static func cleanMerchantName(_ merchant: String) -> String {
        let words = merchant.split(separator: " ").filter { word in
            !word.contains("#") && !word.contains(where: \.isNumber)
        }
        let cleaned = words.joined(separator: " ")
        return cleaned.isEmpty ? merchant : cleaned
    }

    static func withTimeout<T: Sendable>(
        _ seconds: Double,
        _ operation: @escaping @Sendable () async -> T?
    ) async -> T? {
        await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(for: .seconds(seconds))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
