import SwiftData
import SwiftUI

struct EndNightReviewView: View {
    let controller: GameController
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Safe to end", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.success)
                    Text("Review every player's points before saving this night to Past Nights.")
                        .foregroundStyle(Theme.textSecondary)
                    LabeledContent("Original starting stack", value: controller.session.startingStack.map(String.init) ?? "Not recorded")
                }
                .listRowBackground(Theme.surface)
                Section("Results · best to worst") {
                    ForEach(NightArchive.results(for: controller.session)) { result in NightResultRow(result: result) }
                }
                .listRowBackground(Theme.surface)
                Section {
                    Button("Save results and end night", role: .destructive) {
                        do {
                            try appModel.endNight(context: context)
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .disabled(!controller.session.canEndNight)
                } footer: {
                    Text("PokerCalc saves the results first, then removes the active table. If saving fails, the active table is kept so you can try again.")
                }
                .listRowBackground(Theme.surface)
            }
            .themedScreen()
            .navigationTitle("End Night")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Could not end night", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }
}
