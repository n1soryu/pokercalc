import Foundation
import Testing
@testable import PokerCore

struct SessionTests {
    private let a = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
    private let b = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
    private let c = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!

    private func makeSession(rebuysAllowed: Bool = true) throws -> TableSession {
        try TableSession(
            seats: [
                SessionSeat(id: a, name: "A", stack: 100),
                SessionSeat(id: b, name: "B", stack: 100),
                SessionSeat(id: c, name: "C", stack: 0)
            ],
            smallBlind: 5,
            bigBlind: 10,
            buttonIndex: 0,
            rebuysAllowed: rebuysAllowed
        )
    }

    @Test
    func buttonSkipsBustedPlayersAndStartsHeadsUp() throws {
        var session = try makeSession()
        try session.startNextHand()
        #expect(session.buttonIndex == 0)
        try session.apply(.action(.fold))
        try session.startNextHand()
        #expect(session.currentHand?.setup.seats.count == 2)
        #expect(session.buttonIndex == 1)
        #expect(session.currentHand?.setup.buttonIndex == 1)
    }

    @Test
    func rebuyAllowedAndDisallowed() throws {
        var session = try makeSession(rebuysAllowed: true)
        try session.rebuy(seat: a, amount: 25)
        #expect(session.seats.first(where: { $0.id == a })?.stack == 125)
        var disallowed = try makeSession(rebuysAllowed: false)
        #expect(throws: TableSessionError.rebuysDisabled) {
            try disallowed.rebuy(seat: a, amount: 25)
        }
    }

    @Test
    func cashOutRecordsFinalStack() throws {
        var session = try makeSession()
        try session.cashOut(seat: a)
        #expect(session.seats.first(where: { $0.id == a })?.cashedOut == 100)
        #expect(session.results().first(where: { $0.id == a })?.net == 0)
    }

    @Test
    func betweenHandOperationsAreGuarded() throws {
        var session = try makeSession()
        try session.startNextHand()
        #expect(throws: TableSessionError.handInProgress) {
            try session.setBlinds(smallBlind: 2, bigBlind: 4)
        }
    }

    @Test
    func resultsIncludeNet() throws {
        let session = try makeSession()
        let result = session.results().first(where: { $0.id == a })
        #expect(result?.totalBuyIn == 100)
        #expect(result?.finalStack == 100)
        #expect(result?.net == 0)
    }

    @Test
    func midHandCodableRoundTrip() throws {
        var session = try makeSession()
        try session.startNextHand()
        try session.apply(.action(.call))
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(TableSession.self, from: data)
        #expect(decoded == session)
        #expect(decoded.currentState == session.currentState)
    }

    @Test
    func undoAwardRestoresIncompleteHand() throws {
        var session = try makeSession()
        try session.startNextHand()
        try session.apply(.action(.fold))
        #expect(session.currentState?.street == .complete)
        try session.undo()
        #expect(session.currentState?.street != .complete)
        #expect(session.seats.first(where: { $0.id == a })?.handsPlayed == 0)
    }
}
