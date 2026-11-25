import Foundation
import Testing
@testable import PokerCore

struct PointConservationTests {
    @Test func sessionConservesPointsAcrossBettingAwardsManagementAndUndo() throws {
        var session = try TableSession(
            seats: [SessionSeat(name: "A", stack: 40), SessionSeat(name: "B", stack: 40), SessionSeat(name: "C", stack: 40)],
            smallBlind: 5,
            bigBlind: 10,
            rebuysAllowed: true
        )
        try assertConserved(session)

        try session.startNextHand()
        try assertConserved(session)
        try session.apply(.action(.call))
        try assertConserved(session)
        try session.apply(.action(.call))
        try assertConserved(session)
        try session.apply(.action(.check))
        try assertConserved(session)
        try session.apply(.action(.fold))
        try assertConserved(session)
        try session.apply(.action(.fold))
        try assertConserved(session)

        let firstSeat = try #require(session.seats.first)
        try session.rebuy(seat: firstSeat.id, amount: 20)
        try assertConserved(session)
        try session.cashOut(seat: firstSeat.id)
        try assertConserved(session)
        try session.undo()
        try assertConserved(session)
        try session.undo()
        try assertConserved(session)
    }

    @Test func sessionConservesPointsAcrossAllInShowdownAndAwards() throws {
        var session = try TableSession(
            seats: [SessionSeat(name: "A", stack: 20), SessionSeat(name: "B", stack: 20)],
            smallBlind: 5,
            bigBlind: 10
        )
        try session.startNextHand()
        try assertConserved(session)
        try session.apply(.action(.allIn))
        try assertConserved(session)
        try session.apply(.action(.call))
        try assertConserved(session)
        let state = try #require(session.currentState)
        let winner = try #require(state.pots.first?.eligible.first)
        try session.apply(.award(potIndex: 0, winners: [winner]))
        try assertConserved(session)
    }

    private func assertConserved(_ session: TableSession, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let totals = try #require(session.pointTotals, sourceLocation: sourceLocation)
        #expect(session.isPointConserved, sourceLocation: sourceLocation)
        #expect(totals.buyIns == totals.accountedFor, sourceLocation: sourceLocation)
    }
}
