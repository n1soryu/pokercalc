import PokerCore
import Testing
@testable import PokerNight

struct TablePresentationTests {
    @Test func summaryDescribesTheNextHandBeforePlayBegins() throws {
        let session = try makeSession()

        #expect(session.summary.playerCount == 3)
        #expect(session.summary.handNumber == 1)
        #expect(session.summary.smallBlind == 5)
        #expect(session.summary.bigBlind == 10)
        #expect(session.summary.phase == "Between hands")
    }

    @Test func presentationNamesTheActorAndExplainsTheLegalCall() throws {
        var session = try makeSession()
        try session.startNextHand()
        let state = try #require(session.currentState)
        let actorIndex = try #require(state.currentActorIndex)
        let actor = state.seats[actorIndex]
        let presentation = TablePresentation(session: session, state: state)

        #expect(presentation.handNumber == 1)
        #expect(presentation.streetName == "Pre-flop")
        #expect(presentation.actorName == actor.name)
        #expect(presentation.actionPrompt == "Call 10 to match the current bet.")
    }

    @Test func undoDescriptionIdentifiesThePlayerAndAction() throws {
        var session = try makeSession()
        try session.startNextHand()
        let state = try #require(session.currentState)
        let actorIndex = try #require(state.currentActorIndex)
        let actorName = state.seats[actorIndex].name

        try session.apply(.action(.call))

        #expect(session.undoDescription == "\(actorName)'s call")
    }

    @Test func raiseContextExplainsTheResultingStack() throws {
        var session = try makeSession()
        try session.startNextHand()
        let state = try #require(session.currentState)
        let context = try #require(RaiseContext(state: state))

        #expect(context.currentCommitment == 0)
        #expect(context.callAmount == 10)
        #expect(context.minimum == 20)
        #expect(context.maximum == 100)
        #expect(context.addedAmount(for: 35) == 35)
        #expect(context.remainingStack(after: 35) == 65)
    }

    @Test func completedHandSummaryUsesTheCompletedHandNumber() throws {
        var session = try makeSession()
        try session.startNextHand()
        try session.apply(.action(.fold))
        try session.apply(.action(.fold))

        #expect(session.summary.handNumber == 1)
        #expect(session.summary.phase == "Hand complete")
    }

    private func makeSession() throws -> TableSession {
        try TableSession(
            seats: [
                SessionSeat(name: "Maya", stack: 100),
                SessionSeat(name: "Noah", stack: 100),
                SessionSeat(name: "Ari", stack: 100)
            ],
            smallBlind: 5,
            bigBlind: 10,
            buttonIndex: 0,
            startingStack: 100
        )
    }
}
