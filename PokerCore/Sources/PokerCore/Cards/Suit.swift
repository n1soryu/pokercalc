/// The four suits in a standard deck.
public enum Suit: String, CaseIterable, Codable, Sendable {
    case spades
    case hearts
    case diamonds
    case clubs

    /// The Unicode symbol used when displaying this suit.
    public var symbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        }
    }

    init?(character: Character) {
        switch character.lowercased() {
        case "s": self = .spades
        case "h": self = .hearts
        case "d": self = .diamonds
        case "c": self = .clubs
        default: return nil
        }
    }
}
