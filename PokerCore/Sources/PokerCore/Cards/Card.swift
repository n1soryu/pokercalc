/// A playing card identified by its rank and suit.
public struct Card: Hashable, Codable, Sendable {
    /// The card's rank.
    public let rank: Rank
    /// The card's suit.
    public let suit: Suit

    /// Creates a card from its rank and suit.
    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    /// Creates a card from compact notation such as `As` or `Td`.
    public init?(_ notation: String) {
        let characters = Array(notation)
        guard characters.count == 2,
              let rank = Rank(character: characters[0]),
              let suit = Suit(character: characters[1]) else {
            return nil
        }
        self.init(rank: rank, suit: suit)
    }

    /// Parses whitespace-separated compact card notation.
    public static func parse(_ text: String) -> [Card] {
        text.split(whereSeparator: \.isWhitespace).compactMap { Card(String($0)) }
    }
}
