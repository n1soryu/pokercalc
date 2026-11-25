extension HandState {
    /// The points committed during betting, or the total of the built pots once betting ends.
    public var potTotal: Int {
        switch street {
        case .preflop, .flop, .turn, .river:
            return seats.reduce(0) { $0 + $1.committedTotal }
        case .showdown, .complete:
            return pots.reduce(0) { $0 + $1.amount }
        }
    }

    /// The showdown pots still open for winner selection.
    public var unawardedPotIndices: [Int] {
        guard street == .showdown else { return [] }
        return pots.indices.filter { !awardedPotIndices.contains($0) }
    }

    /// The eligible player names for a pot, in table order.
    public func eligibleNames(for pot: Pot) -> [String] {
        seats.filter { pot.eligible.contains($0.id) }.map(\.name)
    }

    /// The first pot still awaiting an award, in main-pot then side-pot order.
    public var nextPotToAward: Int? {
        guard street == .showdown else { return nil }
        return pots.indices.first { !awardedPotIndices.contains($0) }
    }
}

/// Legal raise-to targets for the current actor, including pot-relative shortcuts.
public struct RaiseTargets: Sendable {
    /// The minimum full raise through the actor's all-in amount.
    public let range: ClosedRange<Int>
    /// A half-pot raise after calling, rounded down and limited to the legal range.
    public let halfPot: Int
    /// A full-pot raise after calling, limited to the legal range.
    public let pot: Int

    /// Computes targets from the live hand, or returns nil when raising is unavailable.
    public init?(_ state: HandState) {
        let legal = legalActions(state)
        guard let actor = state.currentActorIndex, let minimum = legal.minRaiseTo else { return nil }
        let afterCall = state.seats[actor].committedThisStreet + legal.callAmount
        let potAfterCall = state.potTotal + legal.callAmount
        range = minimum...legal.maxRaiseTo
        let room = legal.maxRaiseTo - afterCall
        halfPot = max(minimum, afterCall + min(room, potAfterCall / 2))
        pot = max(minimum, afterCall + min(room, potAfterCall))
    }
}
