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

    @discardableResult
    func startHand() -> Bool {
        update { try $0.startNextHand() }
    }

    @discardableResult
    func apply(_ action: PlayerAction) -> Bool {
        let succeeded = update { try $0.apply(.action(action)) }
        if succeeded {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        return succeeded
    }

    @discardableResult
    func undo() -> Bool {
        update { try $0.undo() }
    }

    @discardableResult
    func award(potIndex: Int, winners: [UUID]) -> Bool {
        update { try $0.apply(.award(potIndex: potIndex, winners: winners)) }
    }

    @discardableResult
    func changeBlinds(small: Int, big: Int) -> Bool {
        update { try $0.setBlinds(smallBlind: small, bigBlind: big) }
    }

    @discardableResult
    func rebuy(seat: UUID, amount: Int) -> Bool {
        update { try $0.rebuy(seat: seat, amount: amount) }
    }

    @discardableResult
    func addPlayer(name: String, buyIn: Int) -> Bool {
        update { try $0.addPlayer(name: name.trimmingCharacters(in: .whitespacesAndNewlines), buyIn: buyIn) }
    }

    @discardableResult
    func cashOut(seat: UUID) -> Bool {
        update { try $0.cashOut(seat: seat) }
    }

    @discardableResult
    private func update(_ change: (inout TableSession) throws -> Void) -> Bool {
        do {
            var updated = session
            try change(&updated)
            try save(updated)
            session = updated
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
