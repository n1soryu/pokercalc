import PokerCore
import SwiftUI

struct ShowdownCheckerView: View {
    @State private var board: [Card] = []
    private let initialNames: [String]
    @State private var players: [DraftPlayer]
    @State private var selectedSlot: CardSlot?

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
            .sheet(item: $selectedSlot) { slot in
                CardPickerView(usedCards: usedCards) { card in
                    assign(card, to: slot)
                    selectedSlot = nil
                }
                .themedSheet()
            }
        }
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
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                if index < cards.count {
                    Button {
                        onTap(index)
                    } label: {
                        CardView(card: cards[index])
                    }
                    .accessibilityLabel("\(cards[index].rank.name) of \(cards[index].suit.symbol). Tap to clear.")
                } else if index == cards.count {
                    Button {
                        onTap(index)
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.textSecondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(width: 52, height: 72)
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
        VStack(alignment: .leading, spacing: 12) {
            Text(result.winners.count == 1 ? "\(result.winners[0].name) wins" : "Split pot")
                .font(.title2.bold())
            Text(result.explanation)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            if result.isIncompleteBoard {
                Text("If the hand ended now")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(result.rankedPlayers) { player in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(player.name): \(player.evaluatedHand.displayName)")
                        .font(.headline)
                    HStack {
                        ForEach(player.evaluatedHand.bestFive, id: \.self) { card in
                            CardView(card: card)
                                .scaleEffect(0.72)
                                .frame(width: 38, height: 52)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            player.holeCardsInBestFive.contains(card) ? Theme.textPrimary : Theme.textSecondary,
                                            lineWidth: 2
                                        )
                                }
                                .accessibilityLabel(
                                    "\(card.rank.name) of \(card.suit.symbol), " +
                                    (player.holeCardsInBestFive.contains(card) ? "from hand" : "from board")
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
    }
}
