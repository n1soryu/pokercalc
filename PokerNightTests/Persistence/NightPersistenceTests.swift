import Foundation
import PokerCore
import Testing
@testable import PokerNight

struct NightPersistenceTests {
    @Test func originalStackSurvivesRebuyAndAutosave() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var session = try TableSession(seats: [SessionSeat(name: "A", stack: 10), SessionSeat(name: "B", stack: 10)],
                                       rebuysAllowed: true, startingStack: 10)
        try session.rebuy(seat: session.seats[0].id, amount: 90)
        try store.write(session)
        let restored = try store.load()
        #expect(restored.startingStack == 10)
        #expect(restored.seats[0].totalBuyIn == 100)
        #expect(restored.nightID == session.nightID)
    }

    @Test func legacySaveLeavesOriginalStackUnknown() throws {
        let session = try TableSession(seats: [SessionSeat(name: "A", stack: 100), SessionSeat(name: "B", stack: 10)])
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(session)) as? [String: Any])
        json.removeValue(forKey: "startingStack")
        json.removeValue(forKey: "nightID")
        let restored = try JSONDecoder().decode(TableSession.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(restored.startingStack == nil)
        #expect(restored.nightID == nil)
    }

    @Test func corruptRecoveryOnlyDeletesTheActiveFileAndRefusesReadableFiles() throws {
        let store = temporaryStore()
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let unrelated = store.url.deletingLastPathComponent().appendingPathComponent("history-sentinel")
        try Data("keep".utf8).write(to: unrelated)
        try Data("broken JSON".utf8).write(to: store.url)
        #expect(throws: ActiveNightError.corrupt) { try store.load() }
        #expect(store.exists)
        try store.removeCorruptFile()
        #expect(store.exists == false)
        #expect(try Data(contentsOf: unrelated) == Data("keep".utf8))
        let session = try TableSession(seats: [SessionSeat(name: "A", stack: 10), SessionSeat(name: "B", stack: 10)])
        try store.write(session)
        #expect(throws: ActiveNightError.fileChanged) { try store.removeCorruptFile() }
        #expect(try store.load() == session)
    }

    @Test func resultsSortByNetWithSeatOrderForTiesAndIncludeCashOuts() throws {
        var session = try TableSession(seats: [SessionSeat(name: "A", stack: 10), SessionSeat(name: "B", stack: 10), SessionSeat(name: "C", stack: 10)])
        #expect(NightArchive.results(for: session).map(\.name) == ["A", "B", "C"])
        try session.startNextHand()
        try session.apply(.action(.fold))
        try session.apply(.action(.fold))
        try session.cashOut(seat: session.seats[2].id)
        let results = NightArchive.results(for: session)
        #expect(results.map(\.name) == ["C", "A", "B"])
        #expect(results.map(\.net) == [1, 0, -1])
        #expect(results[0].finalStack == 11)
    }

    private func temporaryStore() -> ActiveNightStore {
        ActiveNightStore(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("active-night.json"))
    }
}
