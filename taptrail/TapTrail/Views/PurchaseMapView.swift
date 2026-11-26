import SwiftUI
import SwiftData
import MapKit

struct PurchaseMapView: View {
    @Query(sort: \Purchase.date, order: .reverse) private var purchases: [Purchase]
    @State private var position: MapCameraPosition = .automatic
    @State private var selection: Purchase?

    private var located: [Purchase] {
        purchases.filter { $0.coordinate != nil }
    }

    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selection) {
                ForEach(located) { purchase in
                    Marker(
                        purchase.merchant,
                        systemImage: "creditcard.fill",
                        coordinate: purchase.coordinate ?? CLLocationCoordinate2D()
                    )
                    .tag(purchase)
                }
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .safeAreaInset(edge: .bottom) {
                if let selection {
                    NavigationLink(value: selection) {
                        PurchaseRow(purchase: selection)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding()
                } else if located.isEmpty {
                    Text("Purchases with a location will appear here.")
                        .font(.subheadline)
                        .padding()
                        .background(.regularMaterial, in: Capsule())
                        .padding()
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Purchase.self) { purchase in
                PurchaseDetailView(purchase: purchase)
            }
        }
    }
}
