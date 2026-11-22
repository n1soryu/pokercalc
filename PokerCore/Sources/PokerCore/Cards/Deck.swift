/// The complete 52-card deck in rank and suit order.
public enum Deck {
    /// Every distinct card in a standard deck.
    public static let all: [Card] = Rank.allCases.flatMap { rank in
        Suit.allCases.map { Card(rank: rank, suit: $0) }
    }
}
