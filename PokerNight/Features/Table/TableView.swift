import PokerCore
import SwiftData
import SwiftUI
import UIKit

struct TableView: View {
    @Bindable var controller: GameController
    @State private var checker: CheckerRequest?
    @State private var management: TableOperation?
    @State private var showingRankings = false
    @State private var showingRaise = false
    @State private var confirmingEndNight = false
    @State private var raiseAmount = 0

    var body: some View {
        Group {
            if let state = controller.state {
                table(state)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("No hand in progress").font(.title.bold())
                        sessionSeats
                        startButton("Start hand")
                    }
                    .padding()
                }
            }
        }
        .themedScreen()
        .navigationTitle("Table")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Showdown checker") { checker = CheckerRequest() }
                    Button("Hand rankings") { showingRankings = true }
                    Divider()
                    ForEach(TableOperation.allCases) { operation in
                        Button(operation.rawValue) { management = operation }
                            .disabled(operation.unavailableReason(in: controller.session) != nil)
                    }
                    ForEach(disabledReasons, id: \.self) { reason in
                        Text(reason)
                    }
                    Divider()
                    Button("End night", role: .destructive) { confirmingEndNight = true }
                        .disabled(!controller.session.canEndNight)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Table options")
                .accessibilityHint("Open showdown, table management, and end-night options.")
            }
        }
        .sheet(item: $checker) { request in
            ShowdownCheckerView(initialNames: request.names).themedSheet()
        }
        .sheet(item: $management) { operation in
            TableManagementView(operation: operation, controller: controller).themedSheet()
        }
        .sheet(isPresented: $showingRankings) { HandRankingsView().themedSheet() }
        .sheet(isPresented: $confirmingEndNight) {
            EndNightReviewView(controller: controller).themedSheet()
        }
        .sheet(isPresented: $showingRaise) {
            if let state = controller.state, let targets = RaiseTargets(state) {
                RaiseView(amount: $raiseAmount, targets: targets) {
                    controller.apply(.betOrRaise(to: raiseAmount))
                    showingRaise = false
                }.themedSheet()
            }
        }
        .alert("Table", isPresented: .constant(management == nil && controller.errorMessage != nil), presenting: controller.errorMessage) { _ in
            Button("OK") { controller.errorMessage = nil }
        } message: { Text($0) }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private struct CheckerRequest: Identifiable {
        let id = UUID()
        var names: [String]? = nil
    }

    private var disabledReasons: [String] {
        var reasons: [String] = []
        for operation in TableOperation.allCases {
            if let reason = operation.unavailableReason(in: controller.session), !reasons.contains(reason) {
                reasons.append(reason)
            }
        }
        return reasons
    }

    private var sessionSeats: some View {
        ForEach(controller.session.seats) { seat in
            LabeledContent(seat.name) {
                if let amount = seat.cashedOut { Text("Cashed out · \(amount)") }
                else { Text("\(seat.stack) points") }
            }
            .monospacedDigit()
            .padding()
            .panel()
            .accessibilityElement(children: .combine)
        }
    }

    private func startButton(_ title: String) -> some View {
        VStack {
            if !controller.session.canStartHand {
                Text("At least two players need points to start a hand.")
            }
            Button(title) { controller.startHand() }
                .buttonStyle(ThemedButtonStyle(kind: .strong))
                .disabled(!controller.session.canStartHand)
                .accessibilityHint(controller.session.canStartHand ? "Starts the next hand." : "At least two players need points to start a hand.")
        }
    }

    @ViewBuilder
    private func table(_ state: HandState) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                tableHeader(state)
                if let streetBanner = streetBanner(state.street) {
                    Text(streetBanner)
                        .font(.headline.bold())
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.accent, in: Capsule())
                }
                PotsView(state: state)
                if state.street == .complete {
                    sessionSeats
                } else {
                    ForEach(state.seats) { seat in
                        SeatRow(
                            seat: seat,
                            seatIndex: state.seats.firstIndex(where: { $0.id == seat.id }) ?? 0,
                            state: state,
                            isActor: state.currentActorIndex.flatMap { state.seats[$0].id == seat.id } ?? false
                        )
                    }
                }
                ForEach(state.unawardedPotIndices, id: \.self) { index in
                    AwardPanel(state: state, potIndex: index, onCheck: {
                        checker = CheckerRequest(names: state.eligibleNames(for: state.pots[index]))
                    }, onAward: controller.award)
                }
                actionBar
            }

            .padding()
        }
    }

    private func tableHeader(_ state: HandState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.street == .complete ? "Hand complete" : state.street == .showdown ? "Showdown" : "Your table")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                    Text(actorText(state))
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Text("\(controller.session.smallBlind)/\(controller.session.bigBlind)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            if !controller.legal.canCheck, controller.legal.callAmount > 0 {
                Label("Call \(controller.legal.callAmount)", systemImage: "arrow.turn.down.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var actionBar: some View {
        VStack(spacing: 10) {
            if let state = controller.state,
               state.street == .complete {
                startButton("Start next hand")
            } else if controller.state?.street != .showdown {
                HStack {
                    if controller.legal.canCheck || controller.legal.callAmount == 0 {
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
            }
            Button(controller.session.lastTableEdit.map { "Undo \($0)" } ?? "Undo") { controller.undo() }
                .buttonStyle(ThemedButtonStyle(kind: .quiet))
                .disabled(!controller.session.canUndo)
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
    let potIndex: Int
    let onCheck: () -> Void
    let onAward: (Int, [UUID]) -> Void
    @State private var winners = Set<UUID>()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let pot = state.pots[potIndex]
            Text(potIndex == 0 ? "Main pot · \(pot.amount)" : "Side pot \(potIndex) · \(pot.amount)")
                .font(.headline)
            Button("Check hands", action: onCheck)
                .buttonStyle(ThemedButtonStyle(kind: .outline))
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
                    .accessibilityLabel("\(seat.name), \(winners.contains(id) ? "selected winner" : "eligible winner")")
                    .accessibilityHint("Double tap to \(winners.contains(id) ? "remove" : "select") \(seat.name) as a winner of this pot.")
                }
            }
            Button("Confirm winners") {
                onAward(potIndex, Array(winners))
                winners = []
            }
            .buttonStyle(ThemedButtonStyle(kind: .primary))
            .disabled(winners.isEmpty)
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Text(seat.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .layoutPriority(1)
                Text("Bet \(seat.committedThisStreet) · Total \(seat.committedTotal)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 6) { badgeText }
                Text("\(seat.stack)")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                if seat.status == .folded { Text("FOLD").foregroundStyle(Theme.textSecondary) }
                if seat.status == .allIn { Text("ALL IN").foregroundStyle(Theme.suitRed).fontWeight(.semibold) }
            }
        }
        .padding()
        .background(isActor ? Theme.accentSoft : Theme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isActor ? Theme.accent : Theme.textTertiary.opacity(0.25), lineWidth: isActor ? 2 : 1)
        )
        .opacity(seat.status == .folded ? 0.4 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
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

    private var accessibilityDescription: String {
        var details = [seat.name, "stack \(seat.stack)", "bet this street \(seat.committedThisStreet)", "total committed \(seat.committedTotal)"]
        if seatIndex == state.setup.buttonIndex { details.append("dealer") }
        if let blindBadge { details.append(blindBadge == "SB" ? "small blind" : "big blind") }
        if isActor { details.append("current actor") }
        if seat.status == .folded { details.append("folded") }
        if seat.status == .allIn { details.append("all in") }
        return details.joined(separator: ", ")
    }
}

private struct PotsView: View {
    let state: HandState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("In the middle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("points")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Text("\(state.potTotal)")
                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(Theme.accent)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pot \(state.potTotal) points")
    }
}

private struct RaiseView: View {
    @Binding var amount: Int
    let targets: RaiseTargets
    private var range: ClosedRange<Int> { targets.range }
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 24) {
                Text("Raise to \(amount)").font(.title.bold())
                Stepper("Amount", value: $amount, in: range, step: 10)
                    .tint(Theme.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    Button("-10") { amount = max(range.lowerBound, amount - 10) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("-100") { amount = max(range.lowerBound, amount - 100) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("-1000") { amount = max(range.lowerBound, amount - 1000) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("+10") { amount = amount + min(10, range.upperBound - amount) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("+100") { amount = amount + min(100, range.upperBound - amount) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("+1000") { amount = amount + min(1000, range.upperBound - amount) }.buttonStyle(ThemedButtonStyle(kind: .outline))
                }
                if range.lowerBound < range.upperBound {
                    Slider(value: Binding(
                        get: { Double(amount) },
                        set: { amount = min(range.upperBound, max(range.lowerBound, Int($0))) }
                    ), in: Double(range.lowerBound)...Double(range.upperBound))
                    .tint(Theme.textPrimary)
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    Button("Min") { amount = range.lowerBound }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("Half pot") { amount = targets.halfPot }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("Pot") { amount = targets.pot }.buttonStyle(ThemedButtonStyle(kind: .outline))
                    Button("All-in") { amount = range.upperBound }.buttonStyle(ThemedButtonStyle(kind: .outline))
                }
                Button("Confirm") { onSubmit(); dismiss() }
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
            }
            .padding()
            }
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
