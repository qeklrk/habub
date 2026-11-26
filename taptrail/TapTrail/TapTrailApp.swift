import SwiftUI
import SwiftData

@main
struct TapTrailApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(PurchaseStore.container)
    }
}

struct RootView: View {
    enum Tab: Hashable {
        case purchases, map, setup
    }

    @State private var tab: Tab = .purchases

    var body: some View {
        TabView(selection: $tab) {
            PurchaseListView(onShowSetup: { tab = .setup })
                .tabItem { Label("Purchases", systemImage: "list.bullet.rectangle") }
                .tag(Tab.purchases)

            PurchaseMapView()
                .tabItem { Label("Map", systemImage: "map") }
                .tag(Tab.map)

            SetupView()
                .tabItem { Label("Setup", systemImage: "gearshape") }
                .tag(Tab.setup)
        }
    }
}
