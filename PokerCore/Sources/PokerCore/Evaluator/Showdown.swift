/// A player and their two hole cards for showdown evaluation.
public struct ShowdownPlayer: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let holeCards: [Card]

    /// Creates a showdown player.
    public init(id: String, name: String, holeCards: [Card]) {
        self.id = id
        self.name = name
        self.holeCards = holeCards
    }
}

/// One player's evaluated showdown result.
public struct ShowdownPlayerResult: Codable, Sendable, Equatable, Identifiable {
    public let player: ShowdownPlayer
    public let evaluatedHand: EvaluatedHand
    public let holeCardsInBestFive: [Card]
    public let boardCardsInBestFive: [Card]

    public var id: String { player.id }
    public var name: String { player.name }

    init(player: ShowdownPlayer, evaluatedHand: EvaluatedHand, board: [Card]) {
        self.player = player
        self.evaluatedHand = evaluatedHand
        self.holeCardsInBestFive = evaluatedHand.bestFive.filter { player.holeCards.contains($0) }
        self.boardCardsInBestFive = evaluatedHand.bestFive.filter { board.contains($0) }
    }
}

/// The ranked outcome of a showdown.
public struct ShowdownResult: Codable, Sendable, Equatable {
    public let rankedPlayers: [ShowdownPlayerResult]
    public let winners: [ShowdownPlayerResult]
    public let explanation: String
    public let isIncompleteBoard: Bool

    public var players: [ShowdownPlayerResult] { rankedPlayers }
}

/// Evaluates a Hold'em board and two or more players.
public enum Showdown {
    /// Evaluates each player's best five cards and explains the result.
    public static func evaluate(board: [Card], players: [ShowdownPlayer]) throws -> ShowdownResult {
        guard (3...5).contains(board.count) else { throw ShowdownError.invalidBoardCount }
        guard players.count >= 2 else { throw ShowdownError.notEnoughPlayers }
        let allCards = board + players.flatMap(\.holeCards)
        guard Set(allCards).count == allCards.count else { throw ShowdownError.duplicateCards }
        guard players.allSatisfy({ $0.holeCards.count == 2 }) else { throw ShowdownError.invalidHoleCards }

        let results = players.map {
            ShowdownPlayerResult(player: $0, evaluatedHand: bestHand(from: board + $0.holeCards), board: board)
        }.sorted { $0.evaluatedHand > $1.evaluatedHand }
        let winners = results.filter { $0.evaluatedHand == results[0].evaluatedHand }
        return ShowdownResult(
            rankedPlayers: results,
            winners: winners,
            explanation: explanation(winners: winners, ranked: results, board: board),
            isIncompleteBoard: board.count < 5
        )
    }
}

/// Errors raised while evaluating a showdown.
public enum ShowdownError: Error, Equatable, Sendable {
    case invalidBoardCount
    case duplicateCards
    case invalidHoleCards
    case notEnoughPlayers
}

private func explanation(winners: [ShowdownPlayerResult], ranked: [ShowdownPlayerResult], board: [Card]) -> String {
    guard winners.count > 1 else {
        let winner = winners[0]
        let runnerUp = ranked.first { $0.evaluatedHand != winner.evaluatedHand }
        guard let runnerUp else { return "\(winner.evaluatedHand.displayName) wins." }
        return explainDifference(winner.evaluatedHand, runnerUp.evaluatedHand)
    }

    if winners.allSatisfy({ Set($0.evaluatedHand.bestFive) == Set(board) && board.count == 5 }) {
        return "The board plays for everyone, so the pot splits."
    }
    return "Both have the same five-card hand (suits don't matter), so the pot splits."
}

private func explainDifference(_ winner: EvaluatedHand, _ runnerUp: EvaluatedHand) -> String {
    if winner.category != runnerUp.category {
        return "\(winner.displayName) beats \(runnerUp.displayName)."
    }
    switch winner.category {
    case .pair:
        return "Both have a pair, but \(winner.tiebreakers[0].pluralName) beat \(runnerUp.tiebreakers[0].pluralName)."
    case .twoPair:
        let winnerPairs = "\(winner.tiebreakers[0].pluralName) and \(winner.tiebreakers[1].pluralName)"
        return "Both have Two Pair, \(winnerPairs). The next-best card decides it: \(winner.tiebreakers[2].name) beats \(runnerUp.tiebreakers[2].name)."
    case .fullHouse:
        return "Both have a Full House. \(winner.tiebreakers[0].pluralName) full beats \(runnerUp.tiebreakers[0].pluralName) full."
    default:
        if let index = zip(winner.tiebreakers, runnerUp.tiebreakers).enumerated().first(where: { $0.element.0 != $0.element.1 })?.offset {
            return "Both have \(winner.displayName). \(winner.tiebreakers[index].name) beats \(runnerUp.tiebreakers[index].name)."
        }
        return "The higher hand wins."
    }
}
