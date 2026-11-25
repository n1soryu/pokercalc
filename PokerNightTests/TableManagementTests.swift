import Foundation
import PokerCore
import Testing
@testable import PokerNight

@MainActor
struct TableManagementTests {
    private func table(rebuys: Bool = true) throws -> TableSession {
        try TableSession(seats: [SessionSeat(name: "A", stack: 20), SessionSeat(name: "B", stack: 20)],
                         rebuysAllowed: rebuys)
    }

    @Test func editsPersistExactlyOnceAndDetermineWhoCanPlay() throws {
        var saves: [TableSession] = []
        let controller = GameController(session: try table()) { saves.append($0) }
        let id = controller.session.seats[0].id
        controller.changeBlinds(small: 2, big: 4)
        controller.rebuy(seat: id, amount: 7)
        controller.cashOut(seat: id)
        #expect(!controller.session.canStartHand)
        controller.addPlayer(name: "  C ", buyIn: 15)
        #expect(controller.session.canStartHand)
        try #require(saves.count == 4)
        #expect(saves[0].bigBlind == 4)
        #expect(saves[1].seats[0].stack == 27)
        #expect(saves[1].seats[0].totalBuyIn == 27)
        #expect(saves[2].seats[0].cashedOut == 27)
        #expect(saves[3].seats.last?.name == "C")
        #expect(saves.last == controller.session)
        controller.startHand()
        #expect(controller.state?.seats.map(\.name) == ["B", "C"])
        let started = controller.session
        controller.rebuy(seat: id, amount: 5)
        controller.changeBlinds(small: 1, big: 2)
        controller.addPlayer(name: "D", buyIn: 10)
        controller.cashOut(seat: started.seats[1].id)
        #expect(saves.count == 5)
        #expect(controller.session == started)
        #expect(controller.errorMessage != nil)
    }

    @Test func invalidEditsAndFailedWritesPreserveTheSession() throws {
        var attempts = 0
        let initial = try table(rebuys: false)
        let controller = GameController(session: initial) { _ in
            attempts += 1
            throw CocoaError(.fileWriteNoPermission)
        }
        controller.changeBlinds(small: 3, big: 2)
        controller.rebuy(seat: initial.seats[0].id, amount: 10)
        controller.addPlayer(name: " ", buyIn: 5)
        controller.addPlayer(name: "C", buyIn: 0)
        #expect(attempts == 0)
        controller.cashOut(seat: initial.seats[0].id)
        #expect(attempts == 1)
        #expect(controller.session == initial)
        #expect(controller.errorMessage != nil)
    }
}
