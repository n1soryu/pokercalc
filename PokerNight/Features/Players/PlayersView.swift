import SwiftData
import SwiftUI

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var players: [Player]
    @State private var newName = ""

    var body: some View {
        List {
            Section("Add player") {
                HStack {
                    TextField("Name", text: $newName)
                    Button("Add") {
                        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        context.insert(Player(name: name))
                        newName = ""
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .primary))
                }
                .listRowBackground(Theme.surface)
            }
            ForEach(players) { player in
                TextField("Name", text: Binding(get: { player.name }, set: { player.name = $0 }))
                    .listRowBackground(Theme.surface)
            }
            .onDelete { offsets in offsets.map { players[$0] }.forEach(context.delete) }
            .tint(Theme.suitRed)
        }
        .themedScreen()
        .navigationTitle("Players")
    }
}
