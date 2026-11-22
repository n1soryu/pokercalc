import PokerCore
import SwiftData
import SwiftUI
import UIKit

struct TableView: View {
    @Bindable var controller: GameController
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingChecker = false
    @State private var showingRankings = false
    @State private var showingRaise = false
    @State private var confirmingEndNight = false
    @State private var raiseAmount = 0

    var body: some View {
        Group {
            if let state = controller.state {
                table(state)
            } else {
                ContentUnavailableView("No hand in progress", systemImage: "suit.club", description: Text("Start a hand to begin playing."))
                    .overlay(alignment: .bottom) {
                        Button("Start hand") { controller.startHand() }
                            .buttonStyle(ThemedButtonStyle(kind: .strong))
                            .padding()
                    }
            }
        }
        .themedScreen()
        .navigationTitle("Table")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Showdown checker") { showingChecker = true }
                    Button("Hand rankings") { showingRankings = true }
                    Divider()
                    Button("End night", role: .destructive) { confirmingEndNight = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingChecker) { ShowdownCheckerView().themedSheet() }
        .sheet(isPresented: $showingRankings) { HandRankingsView().themedSheet() }
        .confirmationDialog("End this night?", isPresented: $confirmingEndNight) {
            Button("End night", role: .destructive) {
                appModel.endNight(context: modelContext)
            }
        } message: {
            Text("The current results will be saved to Past Nights.")
        }
        .sheet(isPresented: $showingRaise) {
            RaiseView(
                amount: $raiseAmount,
                range: (controller.legal.minRaiseTo ?? 1)...max(1, controller.legal.maxRaiseTo),
                potAmount: controller.state?.pots.reduce(0) { $0 + $1.amount } ?? 0
            ) {
                controller.apply(.betOrRaise(to: raiseAmount))
                showingRaise = false
            }.themedSheet()
        }
        .alert("Table", isPresented: .constant(controller.errorMessage != nil), presenting: controller.errorMessage) { _ in
            Button("OK") { controller.errorMessage = nil }
        } message: { Text($0) }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    @ViewBuilder
    private func table(_ state: HandState) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(actorText(state))
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !controller.legal.canCheck, controller.legal.callAmount > 0 {
                    Text("Call \(controller.legal.callAmount)")
                        .font(.system(.title3, design: .rounded, weight: .regular))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let streetBanner = streetBanner(state.street) {
                    Text(streetBanner)
                        .font(.headline.bold())
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent, in: Capsule())
                }
                PotsView(state: state)
                ForEach(state.seats) { seat in
                    SeatRow(
                        seat: seat,
                        seatIndex: state.seats.firstIndex(where: { $0.id == seat.id }) ?? 0,
                        state: state,
                        isActor: state.currentActorIndex.flatMap { state.seats[$0].id == seat.id } ?? false
                    )
                }
                if state.street == .showdown {
                    AwardPanel(state: state) { potIndex, winners in
                        controller.award(potIndex: potIndex, winners: winners)
                    }
                }
                actionBar
            }

            .padding()
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack {
                if controller.legal.canCheck {
                    Button("Check") { controller.apply(.check) }
                        .buttonStyle(ThemedButtonStyle(kind: .primary))
                } else {
                    Button("Call \(controller.legal.callAmount)") { controller.apply(.call) }
                        .buttonStyle(ThemedButtonStyle(kind: .primary))
                }
                Button("Fold") { controller.apply(.fold) }
                    .buttonStyle(ThemedButtonStyle(kind: .outline))
            }
            HStack {
                if controller.legal.minRaiseTo != nil {
                    Button("Bet / Raise") {
                        raiseAmount = controller.legal.minRaiseTo ?? controller.legal.maxRaiseTo
                        showingRaise = true
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
                }
                Button("All-in") { controller.apply(.allIn) }
                    .buttonStyle(ThemedButtonStyle(kind: .destructive))
            }
            Button("Undo") { controller.undo() }
                .buttonStyle(ThemedButtonStyle(kind: .quiet))
                .disabled(controller.session.currentHand?.events.isEmpty ?? true)
        }
    }

    private func actorText(_ state: HandState) -> String {
        guard let index = state.currentActorIndex else { return state.street == .complete ? "Hand complete" : "Showdown" }
        return "\(state.seats[index].name) to act"
    }

    private func streetBanner(_ street: Street) -> String? {
        switch street {
        case .flop: return "Deal the flop"
        case .turn: return "Deal the turn"
        case .river: return "Deal the river"
        default: return nil
        }
    }
}

private struct AwardPanel: View {
    let state: HandState
    let onAward: (Int, [UUID]) -> Void
    @State private var potIndex = 0
    @State private var winners = Set<UUID>()

    private var currentPot: Pot? {
        guard state.pots.indices.contains(potIndex) else { return nil }
        return state.pots[potIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Award pots").font(.title2.bold())
            if let pot = currentPot {
                Text("Pot \(potIndex + 1): \(pot.amount)")
                    .font(.headline)
                ForEach(pot.eligible, id: \.self) { id in
                    if let seat = state.seats.first(where: { $0.id == id }) {
                        Button {
                            if winners.contains(id) { winners.remove(id) } else { winners.insert(id) }
                        } label: {
                            HStack {
                                Text(seat.name)
                                Spacer()
                                Image(systemName: winners.contains(id) ? "checkmark.circle.fill" : "circle")
                            }
                        }
                        .buttonStyle(ThemedButtonStyle(kind: winners.contains(id) ? .primary : .outline))
                    }
                }
                Button("Confirm winners") {
                    onAward(potIndex, Array(winners))
                    winners = []
                    if potIndex + 1 < state.pots.count { potIndex += 1 }
                }
                .buttonStyle(ThemedButtonStyle(kind: .primary))
                .disabled(winners.isEmpty)
            } else {
                Text("All pots awarded.")
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .panel()
    }
}

private struct SeatRow: View {
    let seat: SeatState
    let seatIndex: Int
    let state: HandState
    let isActor: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(seat.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text("Bet \(seat.committedThisStreet) · Total \(seat.committedTotal)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 6) {
                badgeText
            }
            Text("\(seat.stack)")
                .font(.title3.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            if seat.status == .folded { Text("FOLD").foregroundStyle(Theme.textSecondary) }
            if seat.status == .allIn { Text("ALL IN").foregroundStyle(Theme.suitRed).fontWeight(.semibold) }
        }
        .padding()
        .background(isActor ? Theme.accent : Theme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActor ? Theme.textPrimary : Theme.textSecondary.opacity(0.25), lineWidth: isActor ? 2 : 1)
        )
        .opacity(seat.status == .folded ? 0.4 : 1)
    }

    @ViewBuilder
    private var badgeText: some View {
        if seatIndex == state.setup.buttonIndex {
            Text("D")
                .font(.caption.bold())
                .foregroundStyle(Theme.background)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Theme.textPrimary, in: Capsule())
        }
        if let blindBadge = blindBadge {
            Text(blindBadge)
                .font(.caption.bold())
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Theme.accent, in: Capsule())
        }
    }

    private var blindBadge: String? {
        let count = state.seats.count
        guard count > 0 else { return nil }
        if count == 2 {
            if seatIndex == state.setup.buttonIndex { return "SB" }
            return "BB"
        }
        let smallBlindIndex = (state.setup.buttonIndex + 1) % count
        let bigBlindIndex = (smallBlindIndex + 1) % count
        if seatIndex == smallBlindIndex { return "SB" }
        if seatIndex == bigBlindIndex { return "BB" }
        return nil
    }
}

private struct PotsView: View {
    let state: HandState

    private var potTotal: Int {
        state.pots.reduce(0) { $0 + $1.amount } + state.seats.reduce(0) { $0 + $1.committedTotal }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pot")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textSecondary)
            Text("\(potTotal)")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            ForEach(Array(state.pots.enumerated()), id: \.offset) { index, pot in
                if index > 0 {
                    Text("Side pot \(index): \(pot.amount)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .panel()
    }
}

private struct RaiseView: View {
    @Binding var amount: Int
    let range: ClosedRange<Int>
    let potAmount: Int
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Raise to \(amount)").font(.title.bold())
                Stepper("Amount", value: $amount, in: range)
                    .tint(Theme.textPrimary)
                Slider(value: Binding(
                    get: { Double(amount) },
                    set: { amount = min(range.upperBound, max(range.lowerBound, Int($0))) }
                ), in: Double(range.lowerBound)...Double(range.upperBound))
                .tint(Theme.textPrimary)
                HStack {
                    Button("Min") { amount = range.lowerBound }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("Half pot") { amount = min(range.upperBound, max(range.lowerBound, potAmount / 2)) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                }
                HStack {
                    Button("Pot") { amount = min(range.upperBound, max(range.lowerBound, potAmount)) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("All-in") { amount = range.upperBound }.buttonStyle(ThemedButtonStyle(kind: .outline))
                }
                Button("Confirm") { onSubmit(); dismiss() }
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
            }
            .padding()
            .navigationTitle("Bet / Raise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }
}
