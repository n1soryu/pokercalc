import Foundation
import Testing
@testable import PokerCore

struct NightMetadataTests {
    @Test func nightHandCountSurvivesCompleteRosterTurnoverAndUndo() throws {
        var session = try TableSession(seats: [SessionSeat(name: "A", stack: 10), SessionSeat(name: "B", stack: 10)], startingStack: 10)
        try session.startNextHand()
        try session.apply(.action(.fold))
        #expect(session.handsPlayed == 1)
        let originals = session.seats.map(\.id)
        try session.addPlayer(name: "C", buyIn: 10)
        try session.addPlayer(name: "D", buyIn: 10)
        for id in originals { try session.cashOut(seat: id) }
        try session.startNextHand()
        try session.apply(.action(.fold))
        #expect(session.handsPlayed == 2)
        #expect(session.seats.map(\.handsPlayed).max() == 1)
        try session.undo()
        #expect(session.handsPlayed == 1)
        try session.apply(.action(.fold))
        let restored = try JSONDecoder().decode(TableSession.self, from: JSONEncoder().encode(session))
        #expect(restored.handsPlayed == 2)
        #expect(restored.startingStack == 10)
    }

    @Test func legacyMetadataDecodesWithoutInventingAStartingStack() throws {
        var session = try TableSession(seats: [SessionSeat(name: "A", stack: 10), SessionSeat(name: "B", stack: 10)])
        try session.startNextHand()
        try session.apply(.action(.fold))
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        for key in ["startingStack", "nightID", "completedHands"] { json.removeValue(forKey: key) }
        let restored = try JSONDecoder().decode(TableSession.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(restored.handsPlayed == 1)
        #expect(restored.startingStack == nil)
        #expect(restored.nightID == nil)
    }
}
