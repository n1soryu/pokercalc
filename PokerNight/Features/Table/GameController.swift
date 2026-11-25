import Observation
import PokerCore
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class GameController {
    var session: TableSession
    var errorMessage: String?

    private let save: (TableSession) throws -> Void

    init(session: TableSession, save: @escaping (TableSession) throws -> Void = ActiveNightStore().write) {
        self.save = save
        self.session = session
    }

    var state: HandState? { session.currentState }
    var legal: LegalActions { state.map(legalActions) ?? LegalActions(canFold: false, canCheck: false, callAmount: 0, minRaiseTo: nil, maxRaiseTo: 0) }

    func startHand() {
        update { try $0.startNextHand() }
    }

    func apply(_ action: PlayerAction) {
        if update({ try $0.apply(.action(action)) }) {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }

    func undo() {
        update { try $0.undo() }
    }

    func award(potIndex: Int, winners: [UUID]) {
        update { try $0.apply(.award(potIndex: potIndex, winners: winners)) }
    }

    func changeBlinds(small: Int, big: Int) {
        update { try $0.setBlinds(smallBlind: small, bigBlind: big) }
    }

    func rebuy(seat: UUID, amount: Int) {
        update { try $0.rebuy(seat: seat, amount: amount) }
    }

    func addPlayer(name: String, buyIn: Int) {
        update { try $0.addPlayer(name: name.trimmingCharacters(in: .whitespacesAndNewlines), buyIn: buyIn) }
    }

    func cashOut(seat: UUID) {
        update { try $0.cashOut(seat: seat) }
    }

    @discardableResult
    private func update(_ change: (inout TableSession) throws -> Void) -> Bool {
        do {
            var updated = session
            try change(&updated)
            try save(updated)
            session = updated
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
