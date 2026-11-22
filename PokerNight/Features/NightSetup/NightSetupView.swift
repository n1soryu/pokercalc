import PokerCore
import SwiftData
import SwiftUI

struct NightSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var roster: [Player]
    let onStart: (TableSession) -> Void
    @State private var selected = Set<UUID>()
    @State private var startingStack = 200
    @State private var smallBlind = 1
    @State private var bigBlind = 2
    @State private var rebuysAllowed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    ForEach(roster) { player in
                        Toggle(player.name, isOn: Binding(get: { selected.contains(player.id) }, set: { isOn in
                            if isOn { selected.insert(player.id) } else { selected.remove(player.id) }
                        }))
                    }
                    if roster.isEmpty {
                        Text("Add players first.")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Night") {
                    Stepper("Starting stack: \(startingStack)", value: $startingStack, in: 1...10000)
                    Stepper("Small blind: \(smallBlind)", value: $smallBlind, in: 1...1000)
                    Stepper("Big blind: \(bigBlind)", value: $bigBlind, in: smallBlind...2000)
                    Toggle("Allow rebuys", isOn: $rebuysAllowed)
                }
                Section {
                    Button("Start night") {
                        let players = roster.filter { selected.contains($0.id) }
                        guard players.count >= 2, let session = try? TableSession(
                            seats: players.map { SessionSeat(id: $0.id, name: $0.name, stack: startingStack) },
                            smallBlind: smallBlind,
                            bigBlind: bigBlind,
                            rebuysAllowed: rebuysAllowed
                        ) else { return }
                        onStart(session)
                        dismiss()
                    }
                    .disabled(selected.count < 2)
                }
            }
            .navigationTitle("New Night")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
