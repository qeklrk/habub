import SwiftData

/// One database shared by the app's screens and the Log Purchase action,
/// so a purchase logged in the background shows up in the list right away.
enum PurchaseStore {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Purchase.self)
        } catch {
            fatalError("Could not open the purchase database: \(error)")
        }
    }()
}
