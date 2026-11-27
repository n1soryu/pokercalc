import PokerCore
import SwiftUI
import UIKit

struct TableView: View {
    @Bindable var controller: GameController
    @State private var presentedSheet: TableSheet?
    @State private var raiseAmount = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xLarge) {
                if let state = controller.state {
                    activeHand(state)
                } else {
                    BetweenHandsHeader(
                        title: controller.session.handsPlayed == 0 ? "The table is ready" : "Between hands",
                        message: controller.session.handsPlayed == 0
                            ? "Start the first hand when every player is seated and ready."
                            : "Stacks are saved. Start the next hand or make a table change."
                    )
                    SessionPlayerList(seats: controller.session.seats)
                    BetweenHandTools(controller: controller, onSelect: openManagement)
                }
            }
            .frame(maxWidth: 720)
            .padding(.horizontal, Theme.Spacing.standard)
            .padding(.vertical, Theme.Spacing.standard)
            .frame(maxWidth: .infinity)
        }
        .themedScreen()
        .navigationTitle("Table")
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TableActionDock(
                controller: controller,
                onRaise: openRaise
            )
        }
        .toolbar { tableToolbar }
        .sheet(item: $presentedSheet, content: sheet)
        .alert("Could not update the table", isPresented: errorIsPresented) {
            Button("OK") { controller.errorMessage = nil }
        } message: {
            Text(controller.errorMessage ?? "")
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    @ViewBuilder
    private func activeHand(_ state: HandState) -> some View {
        let presentation = TablePresentation(session: controller.session, state: state)
        TableHandHeader(
            presentation: presentation,
            blinds: "\(controller.session.smallBlind)/\(controller.session.bigBlind)"
        )
        PotLedgerView(state: state)

        if state.street == .complete {
            SessionPlayerList(seats: controller.session.seats)
        } else {
            HandPlayerList(state: state)
        }

        ForEach(state.unawardedPotIndices, id: \.self) { index in
            PotAwardPanel(
                state: state,
                potIndex: index,
                onCheckHands: {
                    presentedSheet = .checker(state.eligibleNames(for: state.pots[index]))
                },
                onAward: controller.award
            )
        }

        if state.street == .complete {
            HandCompletePanel(handNumber: presentation.handNumber)
            BetweenHandTools(controller: controller, onSelect: openManagement)
        }
    }

    @ToolbarContentBuilder
    private var tableToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("Showdown checker", systemImage: "rectangle.portrait.on.rectangle.portrait") {
                presentedSheet = .checker(nil)
            }
            .accessibilityHint("Compare physical card hands without changing the table.")

            Button("Hand rankings", systemImage: "list.number") {
                presentedSheet = .rankings
            }

            Menu("Table settings", systemImage: "slider.horizontal.3") {
                Section("Between hands") {
                    ForEach(TableOperation.allCases) { operation in
                        Button(operation.rawValue) { presentedSheet = .management(operation) }
                            .disabled(operation.unavailableReason(in: controller.session) != nil)
                    }
                }
                if let reason = managementUnavailableReason {
                    Text(reason)
                }
                Section {
                    Button("End night", role: .destructive) { presentedSheet = .endNight }
                        .disabled(!controller.session.canEndNight)
                }
            }
            .accessibilityHint("Change blinds, manage players, or end the night.")
        }
    }

    private var managementUnavailableReason: String? {
        TableOperation.allCases.compactMap { $0.unavailableReason(in: controller.session) }.first
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { controller.errorMessage != nil && presentedSheet == nil },
            set: { if !$0 { controller.errorMessage = nil } }
        )
    }

    private func openRaise() {
        guard let state = controller.state, let targets = RaiseTargets(state) else { return }
        raiseAmount = targets.range.lowerBound
        presentedSheet = .raise
    }

    private func openManagement(_ operation: TableOperation) {
        presentedSheet = .management(operation)
    }

    @ViewBuilder
    private func sheet(_ sheet: TableSheet) -> some View {
        switch sheet {
        case let .checker(names):
            ShowdownCheckerView(initialNames: names)
                .themedSheet()
        case .rankings:
            HandRankingsView()
                .themedSheet()
        case .raise:
            if let state = controller.state,
               let targets = RaiseTargets(state),
               let context = RaiseContext(state: state) {
                RaiseView(amount: $raiseAmount, targets: targets, context: context) {
                    controller.apply(.betOrRaise(to: raiseAmount))
                }
                .themedSheet()
            }
        case let .management(operation):
            TableManagementView(operation: operation, controller: controller)
                .themedSheet()
        case .endNight:
            EndNightReviewView(controller: controller)
                .themedSheet()
        }
    }
}

private enum TableSheet: Identifiable, Equatable {
    case checker([String]?)
    case rankings
    case raise
    case management(TableOperation)
    case endNight

    var id: String {
        switch self {
        case let .checker(names): "checker-\(names?.joined(separator: "|") ?? "all")"
        case .rankings: "rankings"
        case .raise: "raise"
        case let .management(operation): "management-\(operation.id)"
        case .endNight: "end-night"
        }
    }
}
