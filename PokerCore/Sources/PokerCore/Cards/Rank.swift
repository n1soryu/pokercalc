/// Card ranks ordered from two through ace.
public enum Rank: Int, CaseIterable, Comparable, Codable, Sendable {
    case two = 2
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king
    case ace

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The short label used when displaying this rank.
    public var shortName: String {
        switch self {
        case .two: "2"
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .ten: "10"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        case .ace: "A"
        }
    }

    /// The singular name used in explanations.
    public var name: String {
        switch self {
        case .two: "Two"
        case .three: "Three"
        case .four: "Four"
        case .five: "Five"
        case .six: "Six"
        case .seven: "Seven"
        case .eight: "Eight"
        case .nine: "Nine"
        case .ten: "Ten"
        case .jack: "Jack"
        case .queen: "Queen"
        case .king: "King"
        case .ace: "Ace"
        }
    }

    /// The plural name used in explanations.
    public var pluralName: String {
        switch self {
        case .six: "Sixes"
        case .seven: "Sevens"
        case .eight: "Eights"
        case .nine: "Nines"
        case .ten: "Tens"
        case .jack: "Jacks"
        case .queen: "Queens"
        case .king: "Kings"
        case .ace: "Aces"
        default: "\(name)s"
        }
    }

    init?(character: Character) {
        switch character.lowercased() {
        case "2": self = .two
        case "3": self = .three
        case "4": self = .four
        case "5": self = .five
        case "6": self = .six
        case "7": self = .seven
        case "8": self = .eight
        case "9": self = .nine
        case "t": self = .ten
        case "j": self = .jack
        case "q": self = .queen
        case "k": self = .king
        case "a": self = .ace
        default: return nil
        }
    }
}
