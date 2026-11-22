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
                }
            }
            ForEach(players) { player in
                TextField("Name", text: Binding(get: { player.name }, set: { player.name = $0 }))
            }
            .onDelete { offsets in offsets.map { players[$0] }.forEach(context.delete) }
        }
        .navigationTitle("Players")
    }
}
