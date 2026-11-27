import PokerCore
import SwiftData
import SwiftUI

struct NightSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Player.name) private var roster: [Player]
    let onStart: (TableSession) throws -> Void
    @State private var draft = NightSetupDraft()
    @State private var newName = ""
    @State private var errorMessage: String?

    private var players: [SetupPlayer] { roster.map { SetupPlayer(id: $0.id, name: $0.name) } }
    private var selectedPlayers: [SetupPlayer] {
        draft.seatIDs.compactMap { id in players.first { $0.id == id } }
    }
    private var stackBinding: Binding<Int> {
        Binding(get: { min(10000, max(10, Int(draft.startingStackText) ?? 10)) },
                set: { draft.startingStackText = String($0) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text("Set the seats, table rules, and first dealer.")
                            .font(.headline)
                        Text("PokerCalc uses points only. The dealer keeps this iPhone and records each announced action.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .listRowBackground(Theme.surfaceSecondary)
                rosterSection
                seatSection
                Section {
                    LabeledContent("Starting stack") {
                        TextField("Starting stack", text: $draft.startingStackText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 70)
                    }
                    Stepper("Adjust by 10", value: stackBinding, in: 10...10000, step: 10)
                    Stepper("Small blind: \(draft.smallBlind)", value: $draft.smallBlind, in: 1...1000)
                        .onChange(of: draft.smallBlind) { _, value in
                            draft.bigBlind = max(value, draft.bigBlind)
                        }
                    Stepper("Big blind: \(draft.bigBlind)", value: $draft.bigBlind, in: draft.smallBlind...2000)
                    Toggle("Allow rebuys", isOn: $draft.rebuysAllowed)
                } header: {
                    Text("Table rules")
                } footer: {
                    Text("Each player starts with the same stack. Blinds are forced points posted at the start of every hand.")
                }
                .listRowBackground(Theme.surface)
                Section {
                    if let message = draft.validationMessage(roster: players) {
                        Text(message).foregroundStyle(Theme.textSecondary)
                    }
                    Button("Start night") {
                        do {
                            try onStart(draft.makeSession(roster: players))
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .disabled(draft.validationMessage(roster: players) != nil)
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
                } header: {
                    Text("Ready to play")
                } footer: {
                    Text("Starting creates the table and saves it on this iPhone immediately.")
                }
                .listRowBackground(Theme.surface)
            }
            .environment(\.editMode, .constant(.active))
            .themedScreen()
            .navigationTitle("Start a Night")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("New night", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var rosterSection: some View {
        Section("Players") {
            HStack {
                TextField("New player name", text: $newName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                Button("Add") { addPlayer() }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ForEach(roster) { player in
                Toggle(player.name, isOn: Binding(
                    get: { draft.seatIDs.contains(player.id) },
                    set: { draft.select(player.id, isSelected: $0) }
                ))
            }
            if roster.isEmpty {
                Text("Add at least two players to begin. Names are saved for future nights.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var seatSection: some View {
        Section {
            ForEach(selectedPlayers) { player in
                HStack {
                    Text("Seat \((draft.seatIDs.firstIndex(of: player.id) ?? 0) + 1)")
                        .foregroundStyle(Theme.textSecondary)
                    Text(player.name)
                        .lineLimit(2)
                        .layoutPriority(1)
                    if draft.dealerID == player.id {
                        Text("Dealer")
                            .font(.caption.bold())
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            .onMove { source, destination in draft.seatIDs.move(fromOffsets: source, toOffset: destination) }
            if !selectedPlayers.isEmpty {
                Picker("First dealer", selection: $draft.dealerID) {
                    ForEach(selectedPlayers) { player in Text(player.name).tag(Optional(player.id)) }
                }
                Button("Randomize dealer") { draft.randomizeDealer() }
            }
        } header: {
            Text("Seat order")
        } footer: {
            Text("Select players above, then drag the handles into clockwise seat order. The dealer stays selected when seats move. Reordering changes table position, not the saved roster.")
        }
        .listRowBackground(Theme.surface)
    }

    private func addPlayer() {
        do {
            let name = try PlayerName.validated(newName, in: players)
            let player = Player(name: name)
            context.insert(player)
            do { try context.save() }
            catch { context.rollback(); throw error }
            draft.select(player.id, isSelected: true)
            newName = ""
        } catch { errorMessage = error.localizedDescription }
    }
}
