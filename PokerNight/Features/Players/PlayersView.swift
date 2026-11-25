import SwiftData
import SwiftUI

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var players: [Player]
    @State private var newName = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Add player") {
                HStack {
                    TextField("Name", text: $newName)
                    Button("Add") {
                        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        context.insert(Player(name: name))
                        saveChanges { newName = "" }
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .primary))
                }
                .listRowBackground(Theme.surface)
            }
            ForEach(players) { player in
                TextField("Name", text: Binding(get: { player.name }, set: { player.name = $0 }))
                    .onSubmit { saveChanges() }
                    .listRowBackground(Theme.surface)
            }
            .onDelete(perform: delete)
            .tint(Theme.suitRed)
        }
        .themedScreen()
        .navigationTitle("Players")
        .alert("Could not save players", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { players[$0] }.forEach(context.delete)
        saveChanges()
    }

    private func saveChanges(afterSave: () -> Void = {}) {
        do {
            try context.save()
            afterSave()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
