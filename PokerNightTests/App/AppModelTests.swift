import Foundation
import PokerCore
import SwiftData
import Testing
@testable import PokerNight

@MainActor
struct AppModelTests {
    private let store = ActiveNightStore(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("active-night.json"))

    @Test func startDismissResumeAndEndDriveNavigationAndPersistResults() throws {
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let context = try makeContext()
        let model = AppModel(store: store)
        try model.start(session())
        #expect(model.path.isEmpty)
        model.setupDidDismiss()
        #expect(model.path == [.table])
        #expect(model.hasActiveNight)
        #expect(throws: ActiveNightError.alreadyActive) { try model.start(session()) }
        let relaunched = AppModel(store: store)
        relaunched.resume()
        #expect(relaunched.path == [.table])
        let controller = try #require(relaunched.activeController)
        controller.rebuy(seat: controller.session.seats[0].id, amount: 90)
        try relaunched.endNight(context: context)
        #expect(relaunched.path.isEmpty)
        #expect(relaunched.hasActiveNight == false)
        #expect(store.exists == false)
        let nights = try context.fetch(FetchDescriptor<Night>())
        let night = try #require(nights.first)
        #expect(nights.count == 1)
        #expect(night.startingStack == 10)
        #expect(try night.results.first?.totalBuyIn == 100)
    }

    @Test func activeHandCannotEndAndCancelledSetupDoesNotNavigate() throws {
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let model = AppModel(store: store)
        model.setupDidDismiss()
        #expect(model.path.isEmpty)
        try model.start(session())
        model.activeController?.startHand()
        let context = try makeContext()
        #expect(throws: TableSessionError.handInProgress) { try model.endNight(context: context) }
        #expect(store.exists)
        #expect(try context.fetchCount(FetchDescriptor<Night>()) == 0)
    }

    @Test func corruptResumeIsVisibleAndCancelPreservesFile() throws {
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("bad".utf8).write(to: store.url)
        let model = AppModel(store: store)
        model.resume()
        #expect(model.corruptSaveMessage != nil)
        #expect(model.activeController == nil)
        #expect(model.path.isEmpty)
        model.corruptSaveMessage = nil
        #expect(store.exists)
        model.resume()
        model.deleteCorruptSave()
        #expect(model.hasActiveNight == false)
        #expect(store.exists == false)
    }

    @Test func failedStartDoesNotNavigateOrReplaceController() throws {
        let blocker = store.url.deletingLastPathComponent()
        try Data("not a directory".utf8).write(to: blocker)
        defer { try? FileManager.default.removeItem(at: blocker) }
        let model = AppModel(store: store)
        do { try model.start(session()); Issue.record("Expected a write error") }
        catch { #expect(error is CocoaError) }
        #expect(model.activeController == nil)
        #expect(model.path.isEmpty)
    }

    @Test func finishingAgainUpdatesExistingArchiveInsteadOfDuplicatingIt() throws {
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let context = try makeContext()
        let original = try session()
        context.insert(try NightArchive.makeNight(original))
        try context.save()
        // Represents history saved successfully, followed by active-file removal failure.
        try store.write(original)
        let model = AppModel(store: store)
        model.resume()
        let controller = try #require(model.activeController)
        controller.startHand()
        controller.apply(.fold)
        try model.endNight(context: context)
        let refreshed = ModelContext(context.container)
        let nights = try refreshed.fetch(FetchDescriptor<Night>())
        #expect(nights.count == 1)
        #expect(nights.first?.handsPlayed == 1)
        #expect(try nights.first?.results.map(\.net) == [1, -1])
    }

    @Test func legacyResumePersistsIdentityAndArchivesUnknownOriginalStack() throws {
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        var legacy = try TableSession(seats: [SessionSeat(name: "A", stack: 100), SessionSeat(name: "B", stack: 10)])
        legacy.nightID = nil
        try store.write(legacy)
        let model = AppModel(store: store)
        model.resume()
        #expect(model.path == [.table])
        #expect(try store.load().nightID != nil)
        #expect(model.activeController?.session.startingStack == nil)
        let context = try makeContext()
        try model.endNight(context: context)
        let night = try #require(context.fetch(FetchDescriptor<Night>()).first)
        #expect(night.startingStack == nil)
    }

    @Test func failedHistorySaveKeepsTheActiveNightRecoverable() throws {
        defer { try? FileManager.default.removeItem(at: store.url.deletingLastPathComponent()) }
        let context = try makeContext()
        let model = AppModel(store: store) { _, _ in
            throw CocoaError(.fileWriteNoPermission)
        }
        try model.start(session())
        #expect(throws: CocoaError.self) { try model.endNight(context: context) }
        #expect(model.activeController != nil)
        #expect(model.hasActiveNight)
        #expect(store.exists)
        #expect(try context.fetchCount(FetchDescriptor<Night>()) == 0)
    }

    private func session() throws -> TableSession {
        try TableSession(seats: [SessionSeat(name: "A", stack: 10), SessionSeat(name: "B", stack: 10)],
                         rebuysAllowed: true, startingStack: 10)
    }

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(for: Player.self, Night.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }
}
