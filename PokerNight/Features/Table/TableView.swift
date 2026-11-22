import PokerCore
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
                            .buttonStyle(.borderedProminent)
                            .padding()
                    }
            }
        }
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
        .sheet(isPresented: $showingChecker) { ShowdownCheckerView() }
        .sheet(isPresented: $showingRankings) { HandRankingsView() }
        .confirmationDialog("End this night?", isPresented: $confirmingEndNight) {
            Button("End night", role: .destructive) {
                appModel.endNight(context: modelContext)
            }
        } message: {
            Text("The current results will be saved to Past Nights.")
        }
        .sheet(isPresented: $showingRaise) {
            RaiseView(amount: $raiseAmount, range: (controller.legal.minRaiseTo ?? 1)...max(1, controller.legal.maxRaiseTo)) {
                controller.apply(.betOrRaise(to: raiseAmount))
                showingRaise = false
            }
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(state.street.rawValue.capitalized)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Pot: \(state.pots.reduce(0) { $0 + $1.amount } + state.seats.reduce(0) { $0 + $1.committedTotal })")
                    .font(.title2.bold())
                ForEach(state.seats) { seat in
                    SeatRow(seat: seat, isActor: state.currentActorIndex.flatMap { state.seats[$0].id == seat.id } ?? false)
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
                Button("Fold") { controller.apply(.fold) }
                    .buttonStyle(.bordered)
                if controller.legal.canCheck {
                    Button("Check") { controller.apply(.check) }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Call \(controller.legal.callAmount)") { controller.apply(.call) }
                        .buttonStyle(.borderedProminent)
                }
            }
            HStack {
                if controller.legal.minRaiseTo != nil {
                    Button("Bet / Raise") {
                        raiseAmount = controller.legal.minRaiseTo ?? controller.legal.maxRaiseTo
                        showingRaise = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button("All-in") { controller.apply(.allIn) }
                    .buttonStyle(.bordered)
                Button("Undo") { controller.undo() }
                    .disabled(controller.session.currentHand?.events.isEmpty ?? true)
            }
        }
    }

    private func actorText(_ state: HandState) -> String {
        guard let index = state.currentActorIndex else { return state.street == .complete ? "Hand complete" : "Showdown" }
        return "\(state.seats[index].name) to act"
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
                        .buttonStyle(.bordered)
                    }
                }
                Button("Confirm winners") {
                    onAward(potIndex, Array(winners))
                    winners = []
                    if potIndex + 1 < state.pots.count { potIndex += 1 }
                }
                .buttonStyle(.borderedProminent)
                .disabled(winners.isEmpty)
            } else {
                Text("All pots awarded.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SeatRow: View {
    let seat: SeatState
    let isActor: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(seat.name).font(.headline)
                Text("Bet \(seat.committedThisStreet) · Total \(seat.committedTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(seat.stack)")
                .font(.title3.monospacedDigit())
            if seat.status == .folded { Text("Folded").foregroundStyle(.secondary) }
            if seat.status == .allIn { Text("All-in").foregroundStyle(.orange) }
        }
        .padding()
        .background(isActor ? Color.accentColor.opacity(0.18) : .secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct RaiseView: View {
    @Binding var amount: Int
    let range: ClosedRange<Int>
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Raise to \(amount)").font(.title.bold())
                Stepper("Amount", value: $amount, in: range)
                HStack {
                    Button("Min") { amount = range.lowerBound }
                    Button("All-in") { amount = range.upperBound }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Bet / Raise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { onSubmit(); dismiss() } }
            }
        }
    }
}
