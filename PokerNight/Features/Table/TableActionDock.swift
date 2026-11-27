import PokerCore
import SwiftUI

struct TableActionDock: View {
    let controller: GameController
    let onRaise: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            if let state = controller.state {
                dockContent(for: state)
                undoButton
            } else {
                startHandContent(title: "Start hand")
            }
        }
        .frame(maxWidth: 720)
        .padding(.horizontal, Theme.Spacing.standard)
        .padding(.top, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceElevated)
        .overlay(alignment: .top) { Divider() }
    }

    @ViewBuilder
    private func dockContent(for state: HandState) -> some View {
        switch state.street {
        case .complete:
            startHandContent(title: "Start next hand")
        case .showdown:
            Label("Select and confirm each pot's winner above.", systemImage: "arrow.up")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityLabel("Showdown. Select and confirm each pot's winner above.")
        case .preflop, .flop, .turn, .river:
            if let actor = state.currentActorIndex.map({ state.seats[$0].name }) {
                Text("\(actor)'s action")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            bettingActions
        }
    }

    private var bettingActions: some View {
        VStack(spacing: Theme.Spacing.small) {
            actionLayout {
                if controller.legal.canCheck || controller.legal.callAmount == 0 {
                    Button {
                        controller.apply(.check)
                    } label: {
                        ActionButtonLabel(title: "Check", explanation: "No points added")
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
                    .disabled(!controller.legal.canCheck)
                } else {
                    Button {
                        controller.apply(.call)
                    } label: {
                        ActionButtonLabel(title: "Call \(controller.legal.callAmount)", explanation: "Match the current bet")
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
                }

                Button {
                    controller.apply(.fold)
                } label: {
                    ActionButtonLabel(title: "Fold", explanation: "Give up this hand")
                }
                .buttonStyle(ThemedButtonStyle(kind: .outline))
                .disabled(!controller.legal.canFold)
            }

            actionLayout {
                if controller.legal.minRaiseTo != nil {
                    Button(action: onRaise) {
                        ActionButtonLabel(title: "Bet / Raise", explanation: "Choose a legal total")
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .primary))
                }

                Button {
                    controller.apply(.allIn)
                } label: {
                    ActionButtonLabel(title: "All-in", explanation: "Commit the full stack")
                }
                .buttonStyle(ThemedButtonStyle(kind: .destructive))
            }
        }
    }

    @ViewBuilder
    private func actionLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: Theme.Spacing.small, content: content)
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.small, content: content)
                VStack(spacing: Theme.Spacing.small, content: content)
            }
        }
    }

    private func startHandContent(title: String) -> some View {
        VStack(spacing: Theme.Spacing.small) {
            if !controller.session.canStartHand {
                Label("At least two players need points to start.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.warning)
            }
            Button(title) { controller.startHand() }
                .buttonStyle(ThemedButtonStyle(kind: .strong))
                .disabled(!controller.session.canStartHand)
                .accessibilityHint(controller.session.canStartHand
                                   ? "Posts the blinds and begins the next hand."
                                   : "At least two players need points to start a hand.")
        }
    }

    private var undoButton: some View {
        Button {
            controller.undo()
        } label: {
            Label(
                controller.session.undoDescription.map { "Undo \($0)" } ?? "Undo",
                systemImage: "arrow.uturn.backward"
            )
        }
        .buttonStyle(ThemedButtonStyle(kind: .quiet))
        .disabled(!controller.session.canUndo)
        .accessibilityHint(controller.session.undoDescription.map { "Reverses \($0)." } ?? "There is no action to undo.")
    }
}

private struct ActionButtonLabel: View {
    let title: String
    let explanation: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.body.weight(.semibold))
            Text(explanation)
                .font(.caption2)
                .opacity(0.82)
        }
        .padding(.vertical, Theme.Spacing.xSmall)
    }
}
