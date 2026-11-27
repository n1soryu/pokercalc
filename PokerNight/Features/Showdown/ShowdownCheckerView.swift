import PokerCore
import SwiftUI

struct ShowdownCheckerView: View {
    @State private var board: [Card] = []
    private let initialNames: [String]
    @State private var players: [DraftPlayer]
    @State private var selectedSlot: CardSlot?
    @Environment(\.dismiss) private var dismiss

    init(initialNames: [String]? = nil) {
        let names = initialNames ?? ["Player 1", "Player 2"]
        self.initialNames = names
        _players = State(initialValue: names.map { DraftPlayer(name: $0) })
    }

    private var usedCards: Set<Card> {
        Set(board + players.flatMap(\.cards))
    }

    private var result: ShowdownResult? {
        guard board.count >= 3, players.allSatisfy({ $0.cards.count == 2 }) else { return nil }
        return try? Showdown.evaluate(
            board: board,
            players: players.map { ShowdownPlayer(id: $0.id.uuidString, name: $0.name, holeCards: $0.cards) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Label("Hand comparison only", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.actionPrimary)
                        Text("The checker does not award pots or change the active table. Enter the physical cards, compare the result, then return to the table to select winners.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.large)
                    .background(Theme.surfaceSecondary, in: .rect(cornerRadius: Theme.Radius.panel))

                    sectionHeader("Board")
                    cardSlots(
                        cards: board,
                        count: 5,
                        placeholder: "Add board card",
                        onTap: { index in
                            if index < board.count {
                                board.remove(at: index)
                            } else if board.count < 5 {
                                selectedSlot = .board(index)
                            }
                        }
                    )

                    sectionHeader("Players")
                    ForEach($players) { $player in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                TextField("Player name", text: $player.name)
                                    .textFieldStyle(.roundedBorder)
                                if players.count > 2 {
                                    Button(role: .destructive) {
                                        players.removeAll { $0.id == player.id }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .accessibilityLabel("Remove \(player.name)")
                                }
                            }
                            cardSlots(
                                cards: player.cards,
                                count: 2,
                                placeholder: "Add hole card",
                                onTap: { index in
                                    guard let playerIndex = players.firstIndex(where: { $0.id == player.id }) else { return }
                                    if index < players[playerIndex].cards.count {
                                        players[playerIndex].cards.remove(at: index)
                                    } else {
                                        selectedSlot = .hole(player.id, index)
                                    }
                                }
                            )
                        }
                        .padding()
                        .panel()
                    }

                    Button {
                        players.append(DraftPlayer(name: "Player \(players.count + 1)"))
                    } label: {
                        Label("Add player", systemImage: "plus")
                    }
                    .buttonStyle(ThemedButtonStyle(kind: .outline))

                    if let result {
                        ResultPanel(result: result)
                    } else {
                        Label(inputGuidance, systemImage: "circle.dotted")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                            .padding(Theme.Spacing.standard)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.control))
                    }

                    Button("Reset", role: .destructive) {
                        board = []
                        players = initialNames.map { DraftPlayer(name: $0) }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .buttonStyle(ThemedButtonStyle(kind: .quiet))
                }
                .padding()
            }
            .themedScreen()
            .navigationTitle("Showdown Checker")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedSlot) { slot in
                CardPickerView(usedCards: usedCards) { card in
                    assign(card, to: slot)
                    selectedSlot = nil
                }
                .themedSheet()
            }
        }
    }

    private var inputGuidance: String {
        if board.count < 3 {
            return "Add at least three board cards to compare hands."
        }
        if let player = players.first(where: { $0.cards.count < 2 }) {
            return "Add two hole cards for \(player.name.isEmpty ? "each player" : player.name)."
        }
        return "Add cards to see the result."
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
    }

    @ViewBuilder
    private func cardSlots(
        cards: [Card],
        count: Int,
        placeholder: String,
        onTap: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                if index < cards.count {
                    Button {
                        onTap(index)
                    } label: {
                        CardView(card: cards[index], size: count == 5 ? .compact : .regular)
                    }
                    .accessibilityLabel("\(cards[index].rank.name) of \(cards[index].suit.rawValue). Tap to clear.")
                } else if index == cards.count {
                    Button {
                        onTap(index)
                    } label: {
                        RoundedRectangle(cornerRadius: Theme.Radius.compact)
                            .stroke(Theme.textSecondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(
                                width: count == 5 ? CardDisplaySize.compact.width : CardDisplaySize.regular.width,
                                height: count == 5 ? CardDisplaySize.compact.height : CardDisplaySize.regular.height
                            )
                            .overlay {
                                Image(systemName: "plus")
                                    .foregroundStyle(Theme.textSecondary)
                            }
                    }
                    .accessibilityLabel(placeholder)
                }
            }
        }
    }

    private func assign(_ card: Card, to slot: CardSlot) {
        switch slot {
        case .board:
            board.append(card)
        case let .hole(playerID, _):
            guard let index = players.firstIndex(where: { $0.id == playerID }) else { return }
            players[index].cards.append(card)
        }
    }
}

private struct DraftPlayer: Identifiable {
    let id = UUID()
    var name: String
    var cards: [Card] = []
}

private enum CardSlot: Hashable, Identifiable {
    case board(Int)
    case hole(UUID, Int)

    var id: String {
        switch self {
        case let .board(index): "board-\(index)"
        case let .hole(playerID, index): "\(playerID.uuidString)-\(index)"
        }
    }
}

private struct CardPickerView: View {
    let usedCards: Set<Card>
    let onSelect: (Card) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                    ForEach(Suit.allCases, id: \.self) { suit in
                        ForEach(Rank.allCases, id: \.self) { rank in
                            let card = Card(rank: rank, suit: suit)
                            Button {
                                onSelect(card)
                                dismiss()
                            } label: {
                                CardView(card: card)
                                    .opacity(usedCards.contains(card) ? 0.3 : 1)
                            }
                            .disabled(usedCards.contains(card))
                            .accessibilityLabel("\(rank.name) of \(suit.rawValue)")
                            .accessibilityValue(usedCards.contains(card) ? "Already used" : "Available")
                            .accessibilityHint(usedCards.contains(card) ? "Unavailable because this card is already in the hand." : "Double tap to place this card in the selected slot.")
                        }
                    }
                }
                .padding()
            }
            .themedScreen()
            .navigationTitle("Pick a card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

private struct ResultPanel: View {
    let result: ShowdownResult

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.standard) {
            Label(result.isIncompleteBoard ? "Result so far" : "Comparison complete", systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.success)
            Text(resultHeadline)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            Text(result.explanation)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if result.isIncompleteBoard {
                Label("The board is incomplete. This is the best hand if play ended now.", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Theme.warning)
            }

            VStack(spacing: Theme.Spacing.medium) {
                ForEach(result.rankedPlayers) { player in
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text("\(player.name) — \(player.evaluatedHand.displayName)")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Best five cards")
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                        HStack(spacing: 5) {
                        ForEach(player.evaluatedHand.bestFive, id: \.self) { card in
                            CardView(card: card, size: .compact)
                                .overlay {
                                    RoundedRectangle(cornerRadius: Theme.Radius.compact)
                                        .stroke(
                                            player.holeCardsInBestFive.contains(card) ? Theme.currentActorBorder : Theme.borderStrong,
                                            lineWidth: 2
                                        )
                                }
                                .accessibilityLabel(
                                    "\(card.rank.name) of \(card.suit.rawValue), " +
                                    (player.holeCardsInBestFive.contains(card) ? "from hand" : "from board")
                                )
                        }
                    }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.standard)
                    .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.control))
                }
            }

            Label("Return to the table and select the winner for each pot.", systemImage: "arrow.uturn.backward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.actionPrimary)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.currentActorSurface, in: .rect(cornerRadius: Theme.Radius.hero))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.hero)
                .stroke(Theme.currentActorBorder, lineWidth: 1.5)
        }
    }

    private var resultHeadline: String {
        if result.winners.count == 1, let winner = result.winners.first {
            return "\(winner.name) wins with \(winner.evaluatedHand.displayName.lowercased())."
        }
        let names = result.winners.map(\.name).joined(separator: " and ")
        return "\(names) tie with \(result.winners[0].evaluatedHand.displayName.lowercased())."
    }
}
