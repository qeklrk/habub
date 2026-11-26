import SwiftUI

/// For purchases the automation missed, such as cash or a card you swiped.
struct AddPurchaseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var merchant = ""
    @State private var amount = ""
    @State private var card = ""
    @State private var date = Date()
    @State private var useLocation = true
    @State private var saving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Merchant", text: $merchant)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Card or payment method (optional)", text: $card)
                }

                Section {
                    DatePicker("When", selection: $date)
                    Toggle("Use my current location", isOn: $useLocation)
                } footer: {
                    Text("Turn location off if you are adding a purchase you made somewhere else.")
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Add Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if saving {
                        ProgressView()
                    } else {
                        Button("Save") { save() }
                            .disabled(merchant.nilIfBlank == nil)
                    }
                }
            }
            .onAppear {
                LocationService.shared.requestPermissionIfNeeded()
            }
        }
    }

    @MainActor
    private func save() {
        saving = true
        errorMessage = nil
        Task {
            do {
                try await PurchaseRecorder.record(.init(
                    merchant: merchant,
                    amountText: amount,
                    card: card,
                    placemark: nil,
                    source: .manual,
                    date: date,
                    useLocation: useLocation
                ))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                saving = false
            }
        }
    }
}
