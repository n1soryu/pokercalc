import PokerCore

struct ActiveNightSummary: Equatable, Sendable {
    let playerCount: Int
    let handNumber: Int
    let smallBlind: Int
    let bigBlind: Int
    let phase: String

    init(session: TableSession) {
        playerCount = session.seats.filter { $0.cashedOut == nil }.count
        smallBlind = session.smallBlind
        bigBlind = session.bigBlind

        if let state = session.currentState {
            handNumber = max(1, state.street == .complete ? session.handsPlayed : session.handsPlayed + 1)
            phase = state.street.displayName
        } else {
            handNumber = session.handsPlayed + 1
            phase = "Between hands"
        }
    }
}

extension TableSession {
    var summary: ActiveNightSummary { ActiveNightSummary(session: self) }
}

extension Street {
    var displayName: String {
        switch self {
        case .preflop: "Pre-flop"
        case .flop: "Flop"
        case .turn: "Turn"
        case .river: "River"
        case .showdown: "Showdown"
        case .complete: "Hand complete"
        }
    }

    var plainLanguage: String {
        switch self {
        case .preflop: "Players act after receiving their two private cards."
        case .flop: "The first three shared cards are on the table."
        case .turn: "The fourth shared card is on the table."
        case .river: "The fifth and final shared card is on the table."
        case .showdown: "Compare the remaining hands and award each pot."
        case .complete: "The result is recorded. Review it or start the next hand."
        }
    }
}
