import Observation
import PokerCore
import SwiftData
import Foundation

@MainActor
@Observable
final class AppModel {
    enum Route: Hashable { case table, players, history }
    var path: [Route] = []
    private(set) var activeController: GameController?
    private(set) var hasSavedNight: Bool
    var corruptSaveMessage: String?
    var errorMessage: String?
    private let store: ActiveNightStore

    init(store: ActiveNightStore = ActiveNightStore()) {
        self.store = store
        hasSavedNight = store.exists
    }

    var hasActiveNight: Bool { activeController != nil || hasSavedNight }

    func resume() {
        do {
            if activeController == nil {
                var session = try store.load()
                if session.nightID == nil { session.nightID = UUID() }
                // Stabilize legacy archive identity before opening the table.
                try store.write(session)
                activeController = GameController(session: session, save: store.write)
            }
            path = [.table]
        } catch ActiveNightError.corrupt {
            corruptSaveMessage = ActiveNightError.corrupt.localizedDescription
        } catch {
            hasSavedNight = store.exists
            errorMessage = error.localizedDescription
        }
    }

    func start(_ session: TableSession) throws {
        guard !hasActiveNight, !store.exists else { throw ActiveNightError.alreadyActive }
        try store.write(session)
        hasSavedNight = true
        activeController = GameController(session: session, save: store.write)
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
            corruptSaveMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func endNight(context: ModelContext) throws {
        guard let session = activeController?.session else { throw TableSessionError.noCurrentHand }
        guard session.canEndNight else { throw TableSessionError.handInProgress }
        guard let id = session.nightID else { throw TableSessionError.invalidSetup }
        // A separate context makes save failure independent of unsaved roster edits.
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
        // If removal fails, retrying uses the same archive identity, avoiding duplicates.
        try store.remove()
        activeController = nil
        hasSavedNight = false
        path = []
    }
}
