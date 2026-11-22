/// The result of evaluating the best five-card hand available.
public struct EvaluatedHand: Comparable, Codable, Sendable, Equatable {
    /// The category of the hand.
    public let category: HandCategory
    /// Ranks used to break ties, ordered from most significant to least significant.
    public let tiebreakers: [Rank]
    /// The five cards making up the evaluated hand.
    public let bestFive: [Card]

    /// A human-readable name for the hand.
    public var displayName: String {
        if category == .straightFlush, tiebreakers.first == .ace {
            return "Royal Flush"
        }
        return category.displayName
    }

    /// Creates an evaluated hand.
    public init(category: HandCategory, tiebreakers: [Rank], bestFive: [Card]) {
        self.category = category
        self.tiebreakers = tiebreakers
        self.bestFive = bestFive
    }

    public static func < (lhs: EvaluatedHand, rhs: EvaluatedHand) -> Bool {
        if lhs.category != rhs.category {
            return lhs.category < rhs.category
        }
        for (left, right) in zip(lhs.tiebreakers, rhs.tiebreakers) where left != right {
            return left < right
        }
        return lhs.tiebreakers.count < rhs.tiebreakers.count
    }
}

private extension Array where Element == Rank {
    static func lexicographicallyDescending(_ values: [Rank]) -> [Rank] {
        values.sorted(by: >)
    }
}
