import PokerCore
import SwiftUI

struct PotLedgerView: View {
    let state: HandState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                    Text("Pot")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text("\(state.potTotal)")
                        .font(Theme.Typography.metric)
                        .foregroundStyle(Theme.actionPrimary)
                }
                Spacer()
                Text("points")
                    .font(.footnote)
                    .foregroundStyle(Theme.textTertiary)
            }

            if state.pots.count > 1 {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Spacing.medium) { potBreakdown }
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) { potBreakdown }
                }
            } else if state.street != .showdown && state.street != .complete {
                Text("Includes every point committed in this hand.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.large)
        .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .stroke(Theme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var potBreakdown: some View {
        ForEach(Array(state.pots.enumerated()), id: \.offset) { index, pot in
            LabeledContent(index == 0 ? "Main pot" : "Side pot \(index)", value: "\(pot.amount)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var accessibilityLabel: String {
        let breakdown = state.pots.enumerated().map { index, pot in
            "\(index == 0 ? "main pot" : "side pot \(index)") \(pot.amount)"
        }.joined(separator: ", ")
        return breakdown.isEmpty ? "Pot \(state.potTotal) points" : "Pot \(state.potTotal) points, \(breakdown)"
    }
}

struct PotAwardPanel: View {
    let state: HandState
    let potIndex: Int
    let onCheckHands: () -> Void
    let onAward: (Int, [UUID]) -> Bool
    @State private var winners = Set<UUID>()

    var body: some View {
        let pot = state.pots[potIndex]

        VStack(alignment: .leading, spacing: Theme.Spacing.standard) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text(potIndex == 0 ? "Award the main pot" : "Award side pot \(potIndex)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Select every tied winner. PokerCalc will split \(pot.amount) points and handle any odd point.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Theme.Spacing.small) {
                ForEach(pot.eligible, id: \.self) { id in
                    if let seat = state.seats.first(where: { $0.id == id }) {
                        winnerButton(for: seat)
                    }
                }
            }

            Button(action: onCheckHands) {
                Label("Compare these hands", systemImage: "rectangle.portrait.on.rectangle.portrait")
            }
            .buttonStyle(ThemedButtonStyle(kind: .outline))

            Button(confirmTitle(for: pot.amount), action: confirmAward)
                .buttonStyle(ThemedButtonStyle(kind: .strong))
                .disabled(winners.isEmpty)
                .accessibilityHint(winners.isEmpty ? "Select at least one eligible winner first." : "Awards this pot and saves the table.")
        }
        .padding(Theme.Spacing.large)
        .background(Theme.surfaceElevated, in: .rect(cornerRadius: Theme.Radius.hero))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.hero)
                .stroke(Theme.currentActorBorder, lineWidth: 1.5)
        }
    }

    private func winnerButton(for seat: SeatState) -> some View {
        let selected = winners.contains(seat.id)
        return Button {
            if selected {
                winners.remove(seat.id)
            } else {
                winners.insert(seat.id)
            }
        } label: {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Theme.actionPrimary : Theme.textTertiary)
                Text(seat.name)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("Eligible")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, Theme.Spacing.medium)
            .background(selected ? Theme.actionSecondary : Theme.surfaceSecondary, in: .rect(cornerRadius: Theme.Radius.control))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.control)
                    .stroke(selected ? Theme.focus : Theme.border, lineWidth: selected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(seat.name), \(selected ? "selected winner" : "eligible winner")")
        .accessibilityHint("Double tap to \(selected ? "remove" : "select") \(seat.name) as a winner of this pot.")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func confirmTitle(for amount: Int) -> String {
        winners.count == 1 ? "Award \(amount) points" : "Split \(amount) points"
    }

    private func confirmAward() {
        if onAward(potIndex, Array(winners)) {
            winners = []
        }
    }
}
