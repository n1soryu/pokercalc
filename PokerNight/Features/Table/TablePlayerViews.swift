import PokerCore
import SwiftUI

struct HandPlayerList: View {
    let state: HandState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Players")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: Theme.Spacing.small) {
                ForEach(Array(state.seats.enumerated()), id: \.element.id) { index, seat in
                    HandPlayerRow(
                        seat: seat,
                        position: position(for: index),
                        isActor: state.currentActorIndex == index
                    )
                }
            }
        }
    }

    private func position(for index: Int) -> PlayerPosition {
        let count = state.seats.count
        let button = state.setup.buttonIndex
        let smallBlind = count == 2 ? button : (button + 1) % count
        let bigBlind = count == 2 ? (button + 1) % count : (button + 2) % count
        return PlayerPosition(
            isDealer: index == button,
            blind: index == smallBlind ? .small : index == bigBlind ? .big : nil
        )
    }
}

private struct HandPlayerRow: View {
    let seat: SeatState
    let position: PlayerPosition
    let isActor: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Theme.Spacing.standard) {
                identity
                Spacer(minLength: Theme.Spacing.small)
                commitments
                stack
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                HStack(alignment: .top) {
                    identity
                    Spacer(minLength: Theme.Spacing.small)
                    stack
                }
                commitments
            }
        }
        .padding(Theme.Spacing.standard)
        .background(
            isActor ? Theme.currentActorSurface : Theme.surfacePrimary,
            in: .rect(cornerRadius: isActor ? Theme.Radius.panel : Theme.Radius.compact)
        )
        .overlay {
            RoundedRectangle(cornerRadius: isActor ? Theme.Radius.panel : Theme.Radius.compact)
                .stroke(isActor ? Theme.currentActorBorder : Theme.border, lineWidth: isActor ? 2 : 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                Text(seat.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if isActor {
                    Text("To act")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.currentActorBorder)
                }
            }
            HStack(spacing: Theme.Spacing.small) {
                if position.isDealer { PositionBadge(text: "D", explanation: "Dealer") }
                if let blind = position.blind {
                    PositionBadge(text: blind == .small ? "SB" : "BB", explanation: blind == .small ? "Small blind" : "Big blind")
                }
                if seat.status == .folded {
                    StatusBadge(text: "Folded", systemImage: "xmark", color: Theme.textSecondary)
                } else if seat.status == .allIn {
                    StatusBadge(text: "All-in", systemImage: "circle.fill", color: Theme.destructive)
                }
            }
        }
        .layoutPriority(1)
    }

    private var commitments: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            Text("This street \(seat.committedThisStreet)")
            Text("This hand \(seat.committedTotal)")
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(Theme.textSecondary)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var stack: some View {
        VStack(alignment: .trailing, spacing: Theme.Spacing.xSmall) {
            Text("Stack")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            Text("\(seat.stack)")
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var accessibilityDescription: String {
        var details = [
            seat.name,
            "stack \(seat.stack)",
            "committed this street \(seat.committedThisStreet)",
            "committed this hand \(seat.committedTotal)"
        ]
        if position.isDealer { details.append("dealer") }
        if let blind = position.blind { details.append(blind == .small ? "small blind" : "big blind") }
        if isActor { details.append("current actor") }
        if seat.status == .folded { details.append("folded") }
        if seat.status == .allIn { details.append("all in") }
        return details.joined(separator: ", ")
    }
}

struct SessionPlayerList: View {
    let seats: [SessionSeat]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Stacks")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 0) {
                ForEach(seats) { seat in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.standard) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                            Text(seat.name)
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            if seat.cashedOut != nil {
                                Text("Cashed out")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            } else if seat.stack == 0 {
                                Text("No points")
                                    .font(.caption)
                                    .foregroundStyle(Theme.warning)
                            }
                        }
                        Spacer(minLength: Theme.Spacing.small)
                        Text("\(seat.cashedOut ?? seat.stack)")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(Theme.Spacing.standard)
                    .overlay(alignment: .bottom) { Divider() }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(seat.name), \(seat.cashedOut.map { "cashed out with \($0)" } ?? "stack \(seat.stack)")")
                }
            }
            .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.panel)
                    .stroke(Theme.border, lineWidth: 1)
            }
        }
    }
}

private struct PlayerPosition {
    enum Blind { case small, big }
    let isDealer: Bool
    let blind: Blind?
}

private struct PositionBadge: View {
    let text: String
    let explanation: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 7)
            .frame(minHeight: 24)
            .background(Theme.surfaceSecondary, in: .capsule)
            .accessibilityLabel(explanation)
    }
}

private struct StatusBadge: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .frame(minHeight: 24)
            .background(color.opacity(0.12), in: .capsule)
    }
}
