import SwiftUI
import SwiftData

struct PurchaseListView: View {
    var onShowSetup: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Purchase.date, order: .reverse) private var purchases: [Purchase]
    @State private var search = ""
    @State private var showingAdd = false

    private var filtered: [Purchase] {
        guard let term = search.nilIfBlank else { return purchases }
        return purchases.filter { purchase in
            [purchase.merchant, purchase.placeName, purchase.address, purchase.card, purchase.note]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    private struct DayGroup: Identifiable {
        var day: Date
        var items: [Purchase]
        var id: Date { day }
    }

    private var days: [DayGroup] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            DayGroup(day: day, items: groups[day, default: []].sorted { $0.date > $1.date })
        }
    }

    private var thisMonth: [Purchase] {
        let calendar = Calendar.current
        return purchases.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if purchases.isEmpty {
                    ContentUnavailableView {
                        Label("No purchases yet", systemImage: "wave.3.right.circle")
                    } description: {
                        Text("Set up the Wallet automation once, then every Apple Pay tap is logged here with the time and place.")
                    } actions: {
                        Button("Set Up Automation", action: onShowSetup)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    list
                }
            }
            .navigationTitle("TapTrail")
            .navigationDestination(for: Purchase.self) { purchase in
                PurchaseDetailView(purchase: purchase)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Purchase", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddPurchaseView()
            }
        }
    }

    private var list: some View {
        List {
            if search.nilIfBlank == nil {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("This month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(thisMonth.isEmpty ? Money.format(0, code: nil) : Money.total(thisMonth))
                                .font(.title2.bold())
                                .monospacedDigit()
                        }
                        Spacer()
                        Text("\(thisMonth.count) purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            ForEach(days) { group in
                Section {
                    ForEach(group.items) { purchase in
                        NavigationLink(value: purchase) {
                            PurchaseRow(purchase: purchase)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            context.delete(group.items[index])
                        }
                    }
                } header: {
                    HStack {
                        Text(group.day, format: .dateTime.weekday(.wide).month().day())
                        Spacer()
                        Text(Money.total(group.items))
                            .monospacedDigit()
                    }
                }
            }
        }
        .searchable(text: $search, prompt: "Merchant, place, card or note")
    }
}

struct PurchaseRow: View {
    let purchase: Purchase

    private var detailLine: String {
        var parts = [purchase.date.formatted(date: .omitted, time: .shortened)]
        if let card = purchase.card?.nilIfBlank { parts.append(card) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: purchase.source == .applePay ? "wave.3.right.circle.fill" : "pencil.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(purchase.merchant)
                    .font(.headline)
                    .lineLimit(1)
                if let line = purchase.locationLine {
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(purchase.formattedAmount)
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
