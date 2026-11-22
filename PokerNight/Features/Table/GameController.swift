import Observation
import PokerCore
import UIKit

@MainActor
@Observable
final class GameController {
    var session: TableSession
    var errorMessage: String?

    init(session: TableSession) {
        self.session = session
    }

    var state: HandState? { session.currentState }
    var legal: LegalActions { state.map(legalActions) ?? LegalActions(canFold: false, canCheck: false, callAmount: 0, minRaiseTo: nil, maxRaiseTo: 0) }

    func startHand() {
        do {
            try session.startNextHand()
            persist()
        } catch { errorMessage = error.localizedDescription }
    }

    func apply(_ action: PlayerAction) {
        do {
            try session.apply(.action(action))
            persist()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch { errorMessage = error.localizedDescription }
    }

    func undo() {
        do {
            try session.undo()
            persist()
        } catch { errorMessage = error.localizedDescription }
    }

    func award(potIndex: Int, winners: [UUID]) {
        do {
            try session.apply(.award(potIndex: potIndex, winners: winners))
            persist()
        } catch { errorMessage = error.localizedDescription }
    }

    func persist() {
        ActiveNightStore.save(session)
    }
}
