import SwiftUI

struct BetweenHandTools: View {
    let controller: GameController
    let onSelect: (TableOperation) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text("Between-hand tools")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Table changes are available only when no hand is in progress.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }

            LazyVGrid(columns: columns, spacing: Theme.Spacing.small) {
                ForEach(TableOperation.allCases) { operation in
                    Button {
                        onSelect(operation)
                    } label: {
                        Label(operation.shortTitle, systemImage: operation.systemImage)
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .outline))
                    .disabled(operation.unavailableReason(in: controller.session) != nil)
                    .accessibilityHint(operation.unavailableReason(in: controller.session) ?? operation.accessibilityHint)
                }
            }

            if !controller.session.rebuysAllowed {
                Label("Rebuys are off for this night.", systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var columns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }
}

extension TableOperation {
    var shortTitle: String {
        switch self {
        case .blinds: "Blinds"
        case .rebuy: "Rebuy"
        case .add: "Add player"
        case .cashOut: "Cash out"
        }
    }

    var systemImage: String {
        switch self {
        case .blinds: "arrow.left.arrow.right"
        case .rebuy: "plus.circle"
        case .add: "person.badge.plus"
        case .cashOut: "person.crop.circle.badge.minus"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .blinds: "Change the small and big blind for the next hand."
        case .rebuy: "Add points to an eligible player's stack."
        case .add: "Seat a new player with a buy-in."
        case .cashOut: "Remove a player and record their final stack."
        }
    }
}
