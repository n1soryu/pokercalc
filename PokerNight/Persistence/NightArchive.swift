import PokerCore
import SwiftData
import Foundation

enum NightArchive {
    static func results(for session: TableSession) -> [StoredNightResult] {
        sorted(session.results().map {
            StoredNightResult(id: $0.id, name: $0.name, totalBuyIn: $0.totalBuyIn, finalStack: $0.finalStack, net: $0.net)
        })
    }

    static func sorted(_ results: [StoredNightResult]) -> [StoredNightResult] {
        // Preserve seat order for ties, including players with identical names in old saves.
        results.enumerated().sorted {
            $0.element.net == $1.element.net ? $0.offset < $1.offset : $0.element.net > $1.element.net
        }.map(\.element)
    }

    @MainActor
    static func makeNight(_ session: TableSession) throws -> Night {
        guard session.canEndNight else { throw TableSessionError.handInProgress }
        return Night(id: session.nightID ?? UUID(), smallBlind: session.smallBlind, bigBlind: session.bigBlind,
                     startingStack: session.startingStack, rebuysAllowed: session.rebuysAllowed,
                     handsPlayed: session.handsPlayed,
                     resultsData: try JSONEncoder().encode(results(for: session)))
    }
}

extension Night {
    var results: [StoredNightResult] {
        get throws { NightArchive.sorted(try JSONDecoder().decode([StoredNightResult].self, from: resultsData)) }
    }
}
