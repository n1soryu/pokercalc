import Foundation
import SwiftData

@Model
final class Player {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}

@Model
final class Night {
    @Attribute(.unique) var id: UUID
    var date: Date
    var smallBlind: Int
    var bigBlind: Int
    var startingStack: Int
    var rebuysAllowed: Bool
    var handsPlayed: Int
    var resultsData: Data

    init(date: Date = Date(), smallBlind: Int, bigBlind: Int, startingStack: Int, rebuysAllowed: Bool, handsPlayed: Int, resultsData: Data) {
        self.id = UUID()
        self.date = date
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.startingStack = startingStack
        self.rebuysAllowed = rebuysAllowed
        self.handsPlayed = handsPlayed
        self.resultsData = resultsData
    }
}

struct StoredNightResult: Codable, Identifiable {
    let id: UUID
    let name: String
    let totalBuyIn: Int
    let finalStack: Int
    let net: Int
}
