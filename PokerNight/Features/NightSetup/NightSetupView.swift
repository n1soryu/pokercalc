import PokerCore
import SwiftData
import SwiftUI

struct NightSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var roster: [Player]
    let onStart: (TableSession) -> Void
    @State private var selected = Set<UUID>()
    @State private var startingStack = 10
    @State private var startingStackText = "10"
    @State private var smallBlind = 1
    @State private var bigBlind = 2
    @State private var rebuysAllowed = false

    private var startingStackBinding: Binding<Int> {
        Binding(
            get: { startingStack },
            set: { value in
                startingStack = value
                startingStackText = String(value)
            }
        )
    }

    private var normalizedStartingStack: Int {
        min(10000, max(10, Int(startingStackText) ?? startingStack))
    }

    private func normalizeStartingStack() {
        startingStack = normalizedStartingStack
        startingStackText = String(startingStack)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Players") {
                    ForEach(roster) { player in
                        Toggle(player.name, isOn: Binding(get: { selected.contains(player.id) }, set: { isOn in
                            if isOn { selected.insert(player.id) } else { selected.remove(player.id) }
                        }))
                        .listRowBackground(Theme.surface)
                    }
                    if roster.isEmpty {
                        Text("Add players first.")
                            .foregroundStyle(Theme.textSecondary)
                            .listRowBackground(Theme.surface)
                    }
                }
                Section("Night") {
                    HStack {
                        Text("Starting stack")
                        Spacer()
                        TextField("Starting stack", text: $startingStackText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .onSubmit(normalizeStartingStack)
                            .onChange(of: startingStackText) { _, value in
                                if let value = Int(value), (10...10000).contains(value) {
                                    startingStack = value
                                }
                            }
                    }
                    .listRowBackground(Theme.surface)
                    Stepper("Adjust by 10", value: startingStackBinding, in: 10...10000, step: 10)
                        .listRowBackground(Theme.surface)
                    Stepper("Small blind: \(smallBlind)", value: $smallBlind, in: 1...1000)
                        .listRowBackground(Theme.surface)
                    Stepper("Big blind: \(bigBlind)", value: $bigBlind, in: smallBlind...2000)
                        .listRowBackground(Theme.surface)
                    Toggle("Allow rebuys", isOn: $rebuysAllowed)
                        .listRowBackground(Theme.surface)
                }
                Section {
                    Button("Start night") {
                        normalizeStartingStack()
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
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
                    .listRowBackground(Theme.surface)
                }
            }
            .themedScreen()
            .navigationTitle("New Night")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
