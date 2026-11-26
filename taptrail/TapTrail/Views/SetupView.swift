import SwiftUI
import UIKit

struct SetupView: View {
    @ObservedObject private var location = LocationService.shared
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("iPhone apps can't read Apple Pay purchases directly. TapTrail uses a Shortcuts automation that runs every time you tap a Wallet card to pay. It saves the merchant, amount, card, the exact time and where you were standing.")
                        .font(.subheadline)
                }

                Section("1. Create the automation") {
                    StepRow(number: 1, text: "Open **Shortcuts**, go to the **Automation** tab and tap **+**.")
                    StepRow(number: 2, text: "Choose **Transaction**. Select your cards, leave categories on all, and pick **Run Immediately**. Tap **Next**.")
                    StepRow(number: 3, text: "Choose **New Blank Automation**.")
                    StepRow(number: 4, text: "Add the action **Get Current Location**.")
                    StepRow(number: 5, text: "Add the action **Log Purchase** from TapTrail.")
                    StepRow(number: 6, text: "Tap **Merchant** and pick *Shortcut Input → Merchant*. Do the same for **Amount** (*Amount*) and **Card** (*Card or Pass*). Set **Location** to *Current Location*.")
                    StepRow(number: 7, text: "Tap **Done**. The next time you pay with Apple Pay, the purchase shows up here.")

                    Button {
                        if let url = URL(string: "shortcuts://") { openURL(url) }
                    } label: {
                        Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
                    }
                }

                Section {
                    LabeledContent("Location access", value: location.statusText)

                    switch location.status {
                    case .notDetermined:
                        Button("Allow Location") { location.requestPermissionIfNeeded() }
                    case .authorizedWhenInUse:
                        Button("Allow “Always” (optional)") { location.requestAlways() }
                    case .denied, .restricted:
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    default:
                        EmptyView()
                    }
                } header: {
                    Text("2. Location (optional)")
                } footer: {
                    Text("The Get Current Location step uses the Shortcuts app's own location access, so this is only needed for purchases you add by hand, or if you leave that step out. Without that step, TapTrail needs “Always” access to find your location while it's closed.")
                }

                Section("Good to know") {
                    Label("It runs when you tap your iPhone or a Wallet card to pay in a store. Online Apple Pay checkouts may not trigger it.", systemImage: "wave.3.right")
                    Label("Some banks don't send the amount or merchant. You can fix any purchase by opening it.", systemImage: "pencil")
                    Label("Everything stays on your iPhone. Nothing is uploaded.", systemImage: "lock")
                    Label("Use + on the Purchases tab to add cash or other purchases by hand.", systemImage: "plus.circle")
                }
                .font(.subheadline)
            }
            .navigationTitle("Setup")
        }
    }
}

private struct StepRow: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.tint))
            Text(text)
                .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
