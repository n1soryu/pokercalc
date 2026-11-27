import SwiftData
import SwiftUI

struct PlayersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var players: [Player]
    @State private var newName = ""
    @State private var pendingDeletion: Player?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Label("This roster is for future night setup. Renaming or deleting a saved player does not change anyone already seated at an active table.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .listRowBackground(Theme.surfaceSecondary)

            Section("Add a player") {
                HStack(spacing: Theme.Spacing.small) {
                    TextField("Player name", text: $newName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit(addPlayer)
                    Button("Add", systemImage: "plus", action: addPlayer)
                        .buttonStyle(.borderedProminent)
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .listRowBackground(Theme.surfacePrimary)

            Section("Saved players") {
                if players.isEmpty {
                    ContentUnavailableView(
                        "No saved players",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Add a name above. You will choose who is playing when you start a night.")
                    )
                    .listRowBackground(Theme.surfacePrimary)
                } else {
                    ForEach(players) { player in
                        HStack(spacing: Theme.Spacing.medium) {
                            TextField("Player name", text: Binding(
                                get: { player.name },
                                set: { player.name = $0 }
                            ))
                            .textInputAutocapitalization(.words)
                            .onSubmit { saveRename(player) }
                            .accessibilityLabel("Name for \(player.name)")

                            Button(role: .destructive) {
                                pendingDeletion = player
                            } label: {
                                Label("Delete \(player.name)", systemImage: "trash")
                                    .labelStyle(.iconOnly)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.destructive)
                        }
                        .listRowBackground(Theme.surfacePrimary)
                    }
                }
            }
        }
        .themedScreen()
        .navigationTitle("Players")
        .confirmationDialog(
            "Delete saved player?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { player in
            Button("Delete \(player.name)", role: .destructive) { delete(player) }
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
        } message: { player in
            Text("\(player.name) will be removed from future setup. Active tables and past-night results will stay unchanged.")
        }
        .alert("Could not save players", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var setupPlayers: [SetupPlayer] {
        players.map { SetupPlayer(id: $0.id, name: $0.name) }
    }

    private func addPlayer() {
        do {
            let name = try PlayerName.validated(newName, in: setupPlayers)
            context.insert(Player(name: name))
            try context.save()
            newName = ""
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func saveRename(_ player: Player) {
        do {
            player.name = try PlayerName.validated(player.name, excluding: player.id, in: setupPlayers)
            try context.save()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ player: Player) {
        context.delete(player)
        do {
            try context.save()
            pendingDeletion = nil
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}
