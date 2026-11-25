import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Night.date, order: .reverse) private var nights: [Night]
    @State private var pendingDeletion: Night?
    @State private var errorMessage: String?

    var body: some View {
        List(nights) { night in
            NavigationLink {
                NightDetailView(night: night)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(night.date, format: .dateTime.year().month().day())
                    Text("\(night.handsPlayed) hands · Blinds \(night.smallBlind)/\(night.bigBlind)")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                    if let top = try? night.results.first {
                        Text("Top result: \(top.name) \(top.signedNet)").monospacedDigit()
                    } else {
                        Text("Results unavailable").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .swipeActions(allowsFullSwipe: false) {
                Button("Delete", role: .destructive) { pendingDeletion = night }
            }
            .listRowBackground(Theme.surface)
        }
        .themedScreen()
        .overlay {
            if nights.isEmpty { ContentUnavailableView("No past nights", systemImage: "clock") }
        }
        .navigationTitle("Past Nights")
        .confirmationDialog("Delete saved night?", isPresented: Binding(
            get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
        ), presenting: pendingDeletion) { night in
            Button("Delete night", role: .destructive) { delete(night) }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { night in
            Text("Delete the night from \(night.date.formatted(date: .abbreviated, time: .omitted)) and all its results? Players and the active night will be kept.")
        }
        .alert("Could not delete night", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func delete(_ night: Night) {
        context.delete(night)
        do { try context.save(); pendingDeletion = nil }
        catch { context.rollback(); errorMessage = error.localizedDescription }
    }
}

private struct NightDetailView: View {
    let night: Night

    var body: some View {
        List {
            Section("Night") {
                Text(night.date, format: .dateTime.year().month().day().hour().minute())
                LabeledContent("Hands", value: "\(night.handsPlayed)")
                LabeledContent("Blinds", value: "\(night.smallBlind)/\(night.bigBlind)")
                LabeledContent("Original starting stack", value: night.startingStack.map(String.init) ?? "Not recorded")
                LabeledContent("Rebuys", value: night.rebuysAllowed ? "Allowed" : "Off")
            }
            .listRowBackground(Theme.surface)
            Section("Results · best to worst") {
                if let results = try? night.results {
                    ForEach(results) { result in NightResultRow(result: result) }
                } else {
                    Text("These saved results could not be read.")
                }
            }
            .listRowBackground(Theme.surface)
        }
        .themedScreen()
        .navigationTitle("Night Details")
    }
}
