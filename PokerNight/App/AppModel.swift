import Observation
import PokerCore
import SwiftData
import Foundation

@MainActor
@Observable
final class AppModel {
    enum Route: Hashable { case table, help, players, history }
    var path: [Route] = []
    private(set) var activeController: GameController?
    private(set) var hasSavedNight: Bool
    private(set) var isResuming = false
    private(set) var savedNightSummary: ActiveNightSummary?
    var corruptSaveMessage: String?
    var errorMessage: String?
    private let store: ActiveNightStore
    private let archiveNight: @MainActor (TableSession, ModelContext) throws -> Void

    init(
        store: ActiveNightStore = ActiveNightStore(),
        archiveNight: @escaping @MainActor (TableSession, ModelContext) throws -> Void = AppModel.archive
    ) {
        self.store = store
        self.archiveNight = archiveNight
        hasSavedNight = store.exists
    }

    var hasActiveNight: Bool { activeController != nil || hasSavedNight }
    var activeNightSummary: ActiveNightSummary? {
        activeController.map { ActiveNightSummary(session: $0.session) } ?? savedNightSummary
    }

    func prepareHome() async {
        guard activeController == nil, hasSavedNight, savedNightSummary == nil, !isResuming else { return }
        if let session = try? await loadSavedSession() {
            savedNightSummary = session.summary
        }
    }

    func resume() async {
        guard activeController == nil, !isResuming else { return }
        isResuming = true
        defer { isResuming = false }

        do {
            let savedSession = try await loadSavedSession()
            var session = savedSession

            if session.nightID == nil {
                session.nightID = UUID()
                // Stabilize legacy archive identity before opening the table.
                try await saveLegacySession(session)
            }
            activeController = GameController(session: session, save: store.write)
            savedNightSummary = session.summary
            path = [.table]
        } catch ActiveNightError.corrupt {
            corruptSaveMessage = ActiveNightError.corrupt.localizedDescription
        } catch {
            hasSavedNight = store.exists
            errorMessage = error.localizedDescription
        }
    }

    private func loadSavedSession() async throws -> TableSession {
        let store = store
        return try await Task.detached(priority: .userInitiated) {
            try store.load()
        }.value
    }

    private func saveLegacySession(_ session: TableSession) async throws {
        let store = store
        try await Task.detached(priority: .userInitiated) {
            try store.write(session)
        }.value
    }

    func start(_ session: TableSession) throws {
        guard !hasActiveNight, !store.exists else { throw ActiveNightError.alreadyActive }
        try store.write(session)
        hasSavedNight = true
        activeController = GameController(session: session, save: store.write)
        savedNightSummary = session.summary
    }

    // Called after the setup sheet finishes dismissing, so the push cannot race it.
    func setupDidDismiss() {
        if activeController != nil { path = [.table] }
    }

    func deleteCorruptSave() {
        corruptSaveMessage = nil
        do {
            try store.removeCorruptFile()
            hasSavedNight = store.exists
            savedNightSummary = nil
            corruptSaveMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func endNight(context: ModelContext) throws {
        guard let session = activeController?.session else { throw TableSessionError.noCurrentHand }
        guard session.canEndNight else { throw TableSessionError.handInProgress }
        try archiveNight(session, context)
        // If removal fails, retrying uses the same archive identity, avoiding duplicates.
        try store.remove()
        activeController = nil
        hasSavedNight = false
        savedNightSummary = nil
        path = []
    }

    private static func archive(_ session: TableSession, in context: ModelContext) throws {
        guard let id = session.nightID else { throw TableSessionError.invalidSetup }
        let archiveContext = ModelContext(context.container)
        let existing = try archiveContext.fetch(FetchDescriptor<Night>(predicate: #Predicate { $0.id == id }))
        let updated = try NightArchive.makeNight(session)
        if let night = existing.first {
            night.smallBlind = updated.smallBlind
            night.bigBlind = updated.bigBlind
            night.startingStack = updated.startingStack
            night.rebuysAllowed = updated.rebuysAllowed
            night.handsPlayed = updated.handsPlayed
            night.resultsData = updated.resultsData
        } else {
            archiveContext.insert(updated)
        }
        try archiveContext.save()
    }
}
