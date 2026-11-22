import Observation
import PokerCore
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var activeController: GameController?

    func resume() {
        guard let session = try? ActiveNightStore.load() else { return }
        activeController = GameController(session: session)
    }

    func start(_ session: TableSession) {
        activeController = GameController(session: session)
        ActiveNightStore.save(session)
    }

    func endNight(context: ModelContext) {
        guard let controller = activeController else { return }
        let session = controller.session
        let results = session.results().map {
            StoredNightResult(id: $0.id, name: $0.name, totalBuyIn: $0.totalBuyIn, finalStack: $0.finalStack, net: $0.net)
        }
        guard let data = try? JSONEncoder().encode(results) else { return }
        let handsPlayed = session.seats.map(\.handsPlayed).max() ?? 0
        let night = Night(
            smallBlind: session.smallBlind,
            bigBlind: session.bigBlind,
            startingStack: session.seats.first?.totalBuyIn ?? 0,
            rebuysAllowed: session.rebuysAllowed,
            handsPlayed: handsPlayed,
            resultsData: data
        )
        context.insert(night)
        ActiveNightStore.remove()
        activeController = nil
    }
}
