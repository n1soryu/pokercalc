import Foundation
import PokerCore

struct SetupPlayer: Identifiable, Equatable {
    let id: UUID
    let name: String
}

struct NightSetupDraft {
    var seatIDs: [UUID] = []
    var dealerID: UUID?
    var startingStackText = "10"
    var smallBlind = 1
    var bigBlind = 2
    var rebuysAllowed = false

    mutating func select(_ id: UUID, isSelected: Bool) {
        if isSelected, !seatIDs.contains(id) { seatIDs.append(id) }
        if !isSelected { seatIDs.removeAll { $0 == id } }
        if !seatIDs.contains(where: { $0 == dealerID }) { dealerID = seatIDs.first }
    }

    mutating func randomizeDealer() { dealerID = seatIDs.randomElement() }

    func makeSession(roster: [SetupPlayer]) throws -> TableSession {
        guard let stack = Int(startingStackText), (10...10000).contains(stack) else {
            throw SetupError.invalidStack
        }
        guard smallBlind > 0, bigBlind >= smallBlind, smallBlind <= 1000, bigBlind <= 2000 else {
            throw SetupError.invalidBlinds
        }
        guard seatIDs.count >= 2 else { throw SetupError.notEnoughPlayers }
        guard Set(seatIDs).count == seatIDs.count, Set(roster.map(\.id)).count == roster.count else {
            throw SetupError.invalidSeats
        }
        let seats = try seatIDs.map { id -> SessionSeat in
            guard let player = roster.first(where: { $0.id == id }) else { throw SetupError.invalidSeats }
            return SessionSeat(id: id, name: try PlayerName.validated(player.name, excluding: id, in: roster), stack: stack)
        }
        guard let dealerID, let button = seatIDs.firstIndex(of: dealerID) else { throw SetupError.invalidDealer }
        return try TableSession(seats: seats, smallBlind: smallBlind, bigBlind: bigBlind,
                                buttonIndex: button, rebuysAllowed: rebuysAllowed, startingStack: stack)
    }

    func validationMessage(roster: [SetupPlayer]) -> String? {
        do { _ = try makeSession(roster: roster); return nil }
        catch { return error.localizedDescription }
    }
}

enum PlayerName {
    static func validated(_ value: String, excluding id: UUID? = nil, in roster: [SetupPlayer]) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw SetupError.emptyName }
        guard !roster.contains(where: {
            $0.id != id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) else { throw SetupError.duplicateName }
        return name
    }
}

enum SetupError: LocalizedError {
    case emptyName, duplicateName, invalidStack, invalidBlinds, notEnoughPlayers, invalidSeats, invalidDealer

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Enter a player name."
        case .duplicateName: return "That player name is already in the roster. Use a distinct name."
        case .invalidStack: return "Enter a whole-number starting stack from 10 to 10000."
        case .invalidBlinds: return "Use positive blinds with the big blind at least as large as the small blind."
        case .notEnoughPlayers: return "Select at least two players."
        case .invalidSeats: return "Each selected player must appear once and still be in the roster."
        case .invalidDealer: return "Choose a first dealer from the selected seats."
        }
    }
}
