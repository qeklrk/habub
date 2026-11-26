import SwiftUI
import SwiftData
import MapKit

struct PurchaseDetailView: View {
    @Bindable var purchase: Purchase
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            if let coordinate = purchase.coordinate {
                Section {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        latitudinalMeters: 400,
                        longitudinalMeters: 400
                    ))) {
                        Marker(purchase.locationLine ?? purchase.merchant, systemImage: "creditcard.fill", coordinate: coordinate)
                    }
                    .frame(height: 220)
                    .listRowInsets(EdgeInsets())
                }
            }

            Section("Purchase") {
                LabeledContent("Amount", value: purchase.formattedAmount)
                TextField("Merchant", text: $purchase.merchant)
                LabeledContent("Paid with", value: purchase.paymentDescription)
                if let raw = purchase.rawAmount, purchase.amount == nil {
                    LabeledContent("Amount as sent", value: raw)
                }
            }

            Section("When") {
                LabeledContent("Date", value: purchase.date.formatted(date: .complete, time: .omitted))
                LabeledContent("Time", value: purchase.date.formatted(.dateTime.hour().minute().second()))
            }

            Section("Where") {
                if let place = purchase.placeName {
                    LabeledContent("Place", value: place)
                }
                if let address = purchase.address {
                    Text(address)
                }
                if let coordinate = purchase.coordinate {
                    LabeledContent(
                        "Coordinates",
                        value: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
                    )
                    if let accuracy = purchase.horizontalAccuracy, accuracy >= 0 {
                        LabeledContent("Accurate to", value: "±\(Int(accuracy.rounded())) m")
                    }
                    Button {
                        openInMaps(coordinate)
                    } label: {
                        Label("Open in Maps", systemImage: "map")
                    }
                } else {
                    Text("No location was recorded for this purchase.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Note") {
                TextField("Add a note", text: $purchase.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(purchase.merchant)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openInMaps(_ coordinate: CLLocationCoordinate2D) {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
            URLQueryItem(name: "q", value: purchase.placeName ?? purchase.merchant),
        ]
        if let url = components?.url {
            openURL(url)
        }
    }
}
