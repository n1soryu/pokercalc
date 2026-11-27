import PokerCore
import SwiftUI

enum TableOperation: String, CaseIterable, Identifiable {
    case blinds = "Change blinds"
    case rebuy = "Rebuy"
    case add = "Add player"
    case cashOut = "Cash out player"

    var id: Self { self }

    func unavailableReason(in session: TableSession) -> String? {
        guard session.canEndNight else { return "Finish the current hand to manage the table." }
        if self == .rebuy, !session.rebuysAllowed { return "Rebuys are off for this night." }
        if self == .rebuy || self == .cashOut, session.seats.allSatisfy({ $0.cashedOut != nil }) {
            return "All players have cashed out."
        }
        return nil
    }
}

struct TableManagementView: View {
    let operation: TableOperation
    let controller: GameController
    @Environment(\.dismiss) private var dismiss
    @State private var small: String
    @State private var big: String
    @State private var seatID: UUID?
    @State private var name = ""
    @State private var amount = ""
    @State private var confirming = false

    init(operation: TableOperation, controller: GameController) {
        self.operation = operation
        self.controller = controller
        _small = State(initialValue: String(controller.session.smallBlind))
        _big = State(initialValue: String(controller.session.bigBlind))
        _seatID = State(initialValue: controller.session.seats.first { $0.cashedOut == nil }?.id)
    }

    private var seat: SessionSeat? {
        controller.session.seats.first { $0.id == seatID && $0.cashedOut == nil }
    }

    private var points: Int? { Int(amount).flatMap { $0 > 0 ? $0 : nil } }

    private var rebuyTotals: (stack: Int, buyIn: Int)? {
        guard let seat, let points, points <= Int.max - seat.stack,
              points <= Int.max - seat.totalBuyIn else { return nil }
        return (seat.stack + points, seat.totalBuyIn + points)
    }

    private var valid: Bool {
        guard operation.unavailableReason(in: controller.session) == nil else { return false }
        switch operation {
        case .blinds:
            guard let sb = Int(small), let bb = Int(big) else { return false }
            return sb > 0 && bb >= sb
        case .add: return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && points != nil
        case .rebuy: return rebuyTotals != nil
        case .cashOut: return seat != nil
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(operation.explanation, systemImage: operation.systemImage)
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surfacePrimary)
                switch operation {
                case .blinds:
                    Section("Blinds for the next hand") {
                        numberField("Small blind", text: $small)
                        numberField("Big blind", text: $big)
                        Text("Use positive whole numbers. The big blind must be at least the small blind.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                case .add:
                    Section("New seat") {
                        TextField("Player name", text: $name)
                            .textInputAutocapitalization(.words)
                        numberField("Starting points", text: $amount)
                        if !valid {
                            Text("Enter a name and a positive whole-number starting stack.")
                                .foregroundStyle(Theme.warning)
                        }
                    }
                case .rebuy:
                    Section("Rebuy") {
                        playerPicker
                        numberField("Points to add", text: $amount)
                        if let totals = rebuyTotals {
                            LabeledContent("New stack", value: String(totals.stack))
                            LabeledContent("Total buy-in", value: String(totals.buyIn))
                        } else {
                            Text("Enter a positive whole-number rebuy that fits the player's balance.")
                                .foregroundStyle(Theme.warning)
                        }
                    }
                case .cashOut:
                    Section("Player leaving") {
                        playerPicker
                        if let seat { LabeledContent("Final stack", value: String(seat.stack)) }
                    }
                }

                Section {
                    if operation == .cashOut {
                        Button("Cash out player", role: .destructive) { confirming = true }
                            .disabled(!valid)
                    } else {
                        Button(operation.actionTitle, action: submit)
                            .disabled(!valid)
                    }
                }
            }
            .themedScreen()
            .navigationTitle(operation.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .confirmationDialog("Cash out \(seat?.name ?? "") with \(seat?.stack ?? 0) points?",
                                isPresented: $confirming, titleVisibility: .visible) {
                Button("Cash out", role: .destructive, action: submit)
                Button("Cancel", role: .cancel) {}
            }
            .alert("Could not update the table", isPresented: Binding(
                get: { controller.errorMessage != nil },
                set: { if !$0 { controller.errorMessage = nil } }
            )) {
                Button("OK") { controller.errorMessage = nil }
            } message: {
                Text(controller.errorMessage ?? "")
            }
        }
    }

    private var playerPicker: some View {
        Picker("Player", selection: $seatID) {
            ForEach(controller.session.seats.filter { $0.cashedOut == nil }) { player in
                Text(player.name).tag(Optional(player.id))
            }
        }
    }

    private func numberField(_ label: String, text: Binding<String>) -> some View {
        LabeledContent(label) {
            TextField(label, text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }

    private func submit() {
        guard valid else { return }
        let succeeded: Bool
        switch operation {
        case .blinds:
            guard let sb = Int(small), let bb = Int(big) else { return }
            succeeded = controller.changeBlinds(small: sb, big: bb)
        case .add:
            guard let points else { return }
            succeeded = controller.addPlayer(name: name, buyIn: points)
        case .rebuy:
            guard let seat, let points else { return }
            succeeded = controller.rebuy(seat: seat.id, amount: points)
        case .cashOut:
            guard let seat else { return }
            succeeded = controller.cashOut(seat: seat.id)
        }
        if succeeded { dismiss() }
    }
}

private extension TableOperation {
    var explanation: String {
        switch self {
        case .blinds: "Set the forced bets that will be posted when the next hand begins."
        case .rebuy: "Add points to a player's stack and total buy-in."
        case .add: "Seat a new player between hands without changing the saved roster."
        case .cashOut: "Record a player's final stack and remove them from future hands."
        }
    }

    var actionTitle: String {
        switch self {
        case .blinds: "Save blinds"
        case .rebuy: "Add rebuy"
        case .add: "Add to table"
        case .cashOut: "Cash out player"
        }
    }
}
