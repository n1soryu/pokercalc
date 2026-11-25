import Foundation
import SwiftData
import Testing
@testable import PokerNight

@MainActor
struct HistoryMigrationTests {
    @Test func existingHistorySurvivesMakingOriginalStackOptional() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("history.store")
        let id = try createLegacyHistory(at: url)
        let container = try ModelContainer(for: Player.self, Night.self, configurations: ModelConfiguration(url: url))
        let context = ModelContext(container)
        let nights = try context.fetch(FetchDescriptor<Night>())
        let night = try #require(nights.first)
        #expect(nights.count == 1)
        #expect(night.id == id)
        #expect(night.startingStack == 100)
        #expect(night.handsPlayed == 3)
        #expect(try night.results.first?.name == "Alice")
        #expect(try context.fetch(FetchDescriptor<Player>()).first?.name == "Alice")
    }

    private func createLegacyHistory(at url: URL) throws -> UUID {
        let container = try ModelContainer(for: Player.self, LegacyHistory.Night.self,
                                           configurations: ModelConfiguration(url: url))
        let context = ModelContext(container)
        let night = LegacyHistory.Night()
        context.insert(night)
        context.insert(Player(name: "Alice"))
        try context.save()
        return night.id
    }
}

// Mirrors the shipped pre-Phase-9 model, including its required starting stack.
private enum LegacyHistory {
    @Model final class Night {
        @Attribute(.unique) var id: UUID
        var date: Date
        var smallBlind: Int
        var bigBlind: Int
        var startingStack: Int
        var rebuysAllowed: Bool
        var handsPlayed: Int
        var resultsData: Data

        init() {
            id = UUID()
            date = Date()
            smallBlind = 1
            bigBlind = 2
            startingStack = 100
            rebuysAllowed = true
            handsPlayed = 3
            resultsData = Data("[{\"id\":\"00000000-0000-0000-0000-000000000001\",\"name\":\"Alice\",\"totalBuyIn\":100,\"finalStack\":110,\"net\":10}]".utf8)
        }
    }
}
