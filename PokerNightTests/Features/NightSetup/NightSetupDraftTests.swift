import Foundation
import PokerCore
import Testing
@testable import PokerNight

struct NightSetupDraftTests {
    private let roster = [SetupPlayer(id: UUID(), name: "Alice"), SetupPlayer(id: UUID(), name: "Bob"), SetupPlayer(id: UUID(), name: "Cara")]

    @Test func selectionOrderDealerAndDefaultsReachTheFirstHand() throws {
        var draft = NightSetupDraft()
        draft.select(roster[2].id, isSelected: true)
        draft.select(roster[0].id, isSelected: true)
        draft.select(roster[1].id, isSelected: true)
        draft.dealerID = roster[0].id
        draft.seatIDs.swapAt(0, 1)
        var session = try draft.makeSession(roster: roster)
        #expect(session.seats.map(\.name) == ["Alice", "Cara", "Bob"])
        #expect(session.startingStack == 10)
        #expect(session.smallBlind == 1)
        #expect(session.bigBlind == 2)
        #expect(session.rebuysAllowed == false)
        try session.startNextHand()
        let hand = try #require(session.currentState)
        #expect(hand.seats[hand.setup.buttonIndex].id == roster[0].id)
    }

    @Test func deselectingDealerChoosesRemainingSeatAndRandomChoiceIsSelected() throws {
        var draft = NightSetupDraft()
        for player in roster { draft.select(player.id, isSelected: true) }
        draft.select(roster[0].id, isSelected: false)
        #expect(draft.dealerID == roster[1].id)
        draft.randomizeDealer()
        #expect(draft.seatIDs.contains(try #require(draft.dealerID)))
        #expect(throws: Never.self) { try draft.makeSession(roster: roster) }
    }

    @Test(arguments: ["", "9", "10001", "1.5", "-10", "abc"])
    func rejectsInvalidStack(text: String) {
        var draft = selectedDraft()
        draft.startingStackText = text
        #expect(throws: SetupError.invalidStack) { try draft.makeSession(roster: roster) }
    }

    @Test(arguments: ["10", "15", "10000"])
    func acceptsWholeNumberStackWithinRange(text: String) throws {
        var draft = selectedDraft()
        draft.startingStackText = text
        #expect(try draft.makeSession(roster: roster).startingStack == Int(text))
    }

    @Test func validatesNamesSeatsBlindsAndDealer() {
        #expect(throws: SetupError.emptyName) { try PlayerName.validated(" \n", in: roster) }
        #expect(throws: SetupError.duplicateName) { try PlayerName.validated(" ALICE ", in: roster) }
        var draft = selectedDraft()
        draft.bigBlind = 0
        #expect(throws: SetupError.invalidBlinds) { try draft.makeSession(roster: roster) }
        draft = selectedDraft()
        draft.dealerID = UUID()
        #expect(throws: SetupError.invalidDealer) { try draft.makeSession(roster: roster) }
        draft = selectedDraft()
        draft.seatIDs.append(draft.seatIDs[0])
        #expect(throws: SetupError.invalidSeats) { try draft.makeSession(roster: roster) }
        draft = selectedDraft()
        #expect(throws: SetupError.invalidSeats) { try draft.makeSession(roster: Array(roster.dropFirst())) }
        draft.seatIDs = [roster[0].id]
        #expect(throws: SetupError.notEnoughPlayers) { try draft.makeSession(roster: roster) }
        draft = selectedDraft()
        let duplicates = [roster[0], SetupPlayer(id: roster[1].id, name: "alice")]
        #expect(throws: SetupError.duplicateName) { try draft.makeSession(roster: duplicates) }
    }

    private func selectedDraft() -> NightSetupDraft {
        var draft = NightSetupDraft()
        for player in roster { draft.select(player.id, isSelected: true) }
        return draft
    }
}
