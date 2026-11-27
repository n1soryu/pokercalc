import PokerCore

struct TablePresentation: Equatable {
    let handNumber: Int
    let streetName: String
    let streetExplanation: String
    let actorName: String?
    let actionPrompt: String

    init(session: TableSession, state: HandState) {
        handNumber = max(1, state.street == .complete ? session.handsPlayed : session.handsPlayed + 1)
        streetName = state.street.displayName
        streetExplanation = state.street.plainLanguage
        actorName = state.currentActorIndex.map { state.seats[$0].name }

        let legal = legalActions(state)
        if state.street == .showdown {
            actionPrompt = "Select the winner of each pot."
        } else if state.street == .complete {
            actionPrompt = "Review the result or start the next hand."
        } else if legal.canCheck {
            actionPrompt = "Check is available — no points are needed to continue."
        } else {
            actionPrompt = "Call \(legal.callAmount) to match the current bet."
        }
    }
}

extension TableSession {
    var undoDescription: String? {
        if let lastTableEdit {
            return lastTableEdit
        }
        guard let currentHand, let event = currentHand.events.last else { return nil }

        switch event {
        case let .award(potIndex, _):
            return potIndex == 0 ? "main-pot award" : "side-pot \(potIndex) award"
        case let .action(action):
            let priorEvents = Array(currentHand.events.dropLast())
            let priorState = try? replay(currentHand.setup, priorEvents)
            let actorName: String?
            if let priorState, let actorIndex = priorState.currentActorIndex {
                actorName = priorState.seats[actorIndex].name
            } else {
                actorName = nil
            }
            let actionName: String
            switch action {
            case .fold: actionName = "fold"
            case .check: actionName = "check"
            case .call: actionName = "call"
            case .betOrRaise: actionName = "bet or raise"
            case .allIn: actionName = "all-in"
            }
            return actorName.map { "\($0)'s \(actionName)" } ?? actionName
        }
    }
}

struct RaiseContext: Equatable {
    let playerName: String
    let currentStack: Int
    let currentCommitment: Int
    let callAmount: Int
    let currentPot: Int
    let minimum: Int
    let maximum: Int

    init?(state: HandState) {
        let legal = legalActions(state)
        guard let actorIndex = state.currentActorIndex, let minimum = legal.minRaiseTo else { return nil }
        let actor = state.seats[actorIndex]
        playerName = actor.name
        currentStack = actor.stack
        currentCommitment = actor.committedThisStreet
        callAmount = legal.callAmount
        currentPot = state.potTotal
        self.minimum = minimum
        maximum = legal.maxRaiseTo
    }

    func addedAmount(for total: Int) -> Int {
        max(0, total - currentCommitment)
    }

    func remainingStack(after total: Int) -> Int {
        max(0, currentStack - addedAmount(for: total))
    }
}
