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
                switch operation {
                case .blinds:
                    numberField("Small blind", text: $small)
                    numberField("Big blind", text: $big)
                    Text("Use positive whole numbers. The big blind must cover the small blind.")
                case .add:
                    TextField("Player name", text: $name)
                    numberField("Buy-in", text: $amount)
                    if !valid { Text("Enter a name and a positive whole-number buy-in.") }
                case .rebuy:
                    playerPicker
                    numberField("Rebuy points", text: $amount)
                    if let totals = rebuyTotals {
                        LabeledContent("New stack", value: String(totals.stack))
                        LabeledContent("Total buy-in", value: String(totals.buyIn))
                    } else {
                        Text("Enter a positive whole-number rebuy that fits the player’s balance.")
                    }
                case .cashOut:
                    playerPicker
                    if let seat { LabeledContent("Final stack", value: String(seat.stack)) }
                }

                if operation == .cashOut {
                    Button("Cash out", role: .destructive) { confirming = true }.disabled(!valid)
                } else {
                    Button("Save", action: submit).disabled(!valid)
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
            TextField(label, text: text).keyboardType(.numberPad).multilineTextAlignment(.trailing)
        }
    }

    private func submit() {
        guard valid else { return }
        switch operation {
        case .blinds:
            guard let sb = Int(small), let bb = Int(big) else { return }
            controller.changeBlinds(small: sb, big: bb)
        case .add:
            guard let points else { return }
            controller.addPlayer(name: name, buyIn: points)
        case .rebuy:
            guard let seat, let points else { return }
            controller.rebuy(seat: seat.id, amount: points)
        case .cashOut:
            guard let seat else { return }
            controller.cashOut(seat: seat.id)
        }
        dismiss()
    }
}
