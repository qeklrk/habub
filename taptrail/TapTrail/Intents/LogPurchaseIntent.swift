import AppIntents
import CoreLocation

/// The action the Wallet "Transaction" automation runs each time you pay.
/// Shortcuts passes in the merchant, amount and card; the time is taken when it runs.
struct LogPurchaseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Purchase"
    static var description = IntentDescription(
        "Saves a purchase with the exact time, place and card. Add it to a Wallet Transaction automation in Shortcuts."
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Merchant")
    var merchant: String?

    @Parameter(title: "Amount")
    var amount: String?

    @Parameter(title: "Card")
    var card: String?

    @Parameter(title: "Location")
    var location: CLPlacemark?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) at \(\.$merchant)") {
            \.$card
            \.$location
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let purchase = try await PurchaseRecorder.record(.init(
            merchant: merchant,
            amountText: amount,
            card: card,
            placemark: location,
            source: .applePay
        ))

        var message = "Logged \(purchase.formattedAmount) at \(purchase.merchant)"
        if let line = purchase.locationLine {
            message += " · \(line)"
        }
        return .result(dialog: "\(message)")
    }
}
