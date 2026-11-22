import Foundation

/// A player's persistent seat in a poker night.
public struct SessionSeat: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var stack: Int
    public var totalBuyIn: Int
    public var sittingOut: Bool
    public var cashedOut: Int?
    public var handsPlayed: Int

    /// Creates a session seat.
    public init(id: UUID = UUID(), name: String, stack: Int, totalBuyIn: Int? = nil) {
        self.id = id
        self.name = name
        self.stack = stack
        self.totalBuyIn = totalBuyIn ?? stack
        self.sittingOut = false
        self.cashedOut = nil
        self.handsPlayed = 0
    }
}

/// A player's final night result.
public struct SessionResult: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let totalBuyIn: Int
    public let finalStack: Int
    public let net: Int
}

/// A serialized hand currently belonging to a table session.
public struct CurrentHand: Codable, Sendable, Equatable {
    public let setup: HandSetup
    public var events: [HandEvent]

    /// Creates an empty current hand.
    public init(setup: HandSetup, events: [HandEvent] = []) {
        self.setup = setup
        self.events = events
    }
}

/// The complete state of a poker night.
public struct TableSession: Codable, Sendable, Equatable {
    public private(set) var seats: [SessionSeat]
    public private(set) var smallBlind: Int
    public private(set) var bigBlind: Int
    public private(set) var buttonIndex: Int
    public private(set) var rebuysAllowed: Bool
    public private(set) var currentHand: CurrentHand?

    private var hasStarted: Bool

    /// Creates a session before the first hand.
    public init(
        seats: [SessionSeat],
        smallBlind: Int = 1,
        bigBlind: Int = 2,
        buttonIndex: Int = 0,
        rebuysAllowed: Bool = false
    ) throws {
        guard seats.count >= 2,
              seats.indices.contains(buttonIndex),
              smallBlind > 0,
              bigBlind >= smallBlind else {
            throw TableSessionError.invalidSetup
        }
        self.seats = seats
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.buttonIndex = buttonIndex
        self.rebuysAllowed = rebuysAllowed
        self.currentHand = nil
        self.hasStarted = false
    }

    /// The replayed current hand state, if a hand exists.
    public var currentState: HandState? {
        guard let currentHand else { return nil }
        return try? replay(currentHand.setup, currentHand.events)
    }

    /// Starts the next hand and advances the button past busted seats.
    public mutating func startNextHand() throws {
        if let currentHand {
            guard let state = try? replay(currentHand.setup, currentHand.events), state.street == .complete else {
                throw TableSessionError.handInProgress
            }
        }
        let nextButton = hasStarted ? nextSeatWithChips(after: buttonIndex) : seatWithChips(at: buttonIndex)
        guard let nextButton else { throw TableSessionError.notEnoughPlayers }
        let activeSeats = seats.filter { $0.stack > 0 && $0.cashedOut == nil && !$0.sittingOut }
        guard activeSeats.count >= 2 else { throw TableSessionError.notEnoughPlayers }
        guard let activeButton = activeSeats.firstIndex(where: { $0.id == seats[nextButton].id }) else {
            throw TableSessionError.notEnoughPlayers
        }

        for index in seats.indices {
            seats[index].sittingOut = seats[index].stack == 0 || seats[index].cashedOut != nil
        }
        currentHand = CurrentHand(
            setup: HandSetup(
                seats: activeSeats.map { SeatSetup(id: $0.id, name: $0.name, stack: $0.stack) },
                buttonIndex: activeButton,
                smallBlind: smallBlind,
                bigBlind: bigBlind
            )
        )
        buttonIndex = nextButton
        hasStarted = true
    }

    /// Applies an event to the current hand and synchronizes completed stacks.
    public mutating func apply(_ event: HandEvent) throws {
        guard var currentHand else { throw TableSessionError.noCurrentHand }
        let oldState = try replay(currentHand.setup, currentHand.events)
        currentHand.events.append(event)
        let newState = try replay(currentHand.setup, currentHand.events)
        self.currentHand = currentHand
        synchronize(with: oldState, newState: newState)
    }

    /// Removes the most recent event from the current hand.
    public mutating func undo() throws {
        guard var currentHand, !currentHand.events.isEmpty else { throw TableSessionError.nothingToUndo }
        let oldState = try replay(currentHand.setup, currentHand.events)
        currentHand.events.removeLast()
        let newState = try replay(currentHand.setup, currentHand.events)
        self.currentHand = currentHand
        synchronize(with: oldState, newState: newState)
    }

    /// Changes blinds between hands.
    public mutating func setBlinds(smallBlind: Int, bigBlind: Int) throws {
        try requireBetweenHands()
        guard smallBlind > 0, bigBlind >= smallBlind else { throw TableSessionError.invalidBlinds }
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
    }

    /// Adds a new player between hands.
    @discardableResult
    public mutating func addPlayer(name: String, buyIn: Int) throws -> UUID {
        try requireBetweenHands()
        guard buyIn > 0, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TableSessionError.invalidPlayer
        }
        let seat = SessionSeat(name: name, stack: buyIn)
        seats.append(seat)
        return seat.id
    }

    /// Cashes out a player between hands.
    public mutating func cashOut(seat id: UUID) throws {
        try requireBetweenHands()
        guard let index = seats.firstIndex(where: { $0.id == id }), seats[index].cashedOut == nil else {
            throw TableSessionError.invalidPlayer
        }
        seats[index].cashedOut = seats[index].stack
        seats[index].stack = 0
        seats[index].sittingOut = true
    }

    /// Adds points to a player's stack when rebuys are enabled.
    public mutating func rebuy(seat id: UUID, amount: Int) throws {
        try requireBetweenHands()
        guard rebuysAllowed else { throw TableSessionError.rebuysDisabled }
        guard amount > 0, let index = seats.firstIndex(where: { $0.id == id }), seats[index].cashedOut == nil else {
            throw TableSessionError.invalidPlayer
        }
        seats[index].stack += amount
        seats[index].totalBuyIn += amount
        seats[index].sittingOut = false
    }

    /// Returns final stacks and net results for every seat.
    public func results() -> [SessionResult] {
        seats.map {
            let finalStack = $0.cashedOut ?? $0.stack
            return SessionResult(id: $0.id, name: $0.name, totalBuyIn: $0.totalBuyIn, finalStack: finalStack, net: finalStack - $0.totalBuyIn)
        }
    }

    private mutating func synchronize(with oldState: HandState, newState: HandState) {
        for stateSeat in newState.seats {
            guard let index = seats.firstIndex(where: { $0.id == stateSeat.id }) else { continue }
            seats[index].stack = stateSeat.stack
        }
        let wasComplete = oldState.street == .complete
        let isComplete = newState.street == .complete
        if !wasComplete, isComplete {
            for stateSeat in newState.seats {
                if let index = seats.firstIndex(where: { $0.id == stateSeat.id }) {
                    seats[index].stack = stateSeat.stack
                    seats[index].handsPlayed += 1
                }
            }
        } else if wasComplete, !isComplete {
            for stateSeat in newState.seats {
                if let index = seats.firstIndex(where: { $0.id == stateSeat.id }) {
                    seats[index].handsPlayed = max(0, seats[index].handsPlayed - 1)
                    seats[index].stack = stateSeat.stack
                }
            }
        }
    }

    private func requireBetweenHands() throws {
        if let currentHand, let state = try? replay(currentHand.setup, currentHand.events), state.street != .complete {
            throw TableSessionError.handInProgress
        }
    }

    private func seatWithChips(at index: Int) -> Int? {
        guard seats.indices.contains(index), seats[index].stack > 0, seats[index].cashedOut == nil else { return nextSeatWithChips(after: index) }
        return index
    }

    private func nextSeatWithChips(after index: Int) -> Int? {
        guard !seats.isEmpty else { return nil }
        for offset in 1...seats.count {
            let candidate = (index + offset) % seats.count
            if seats[candidate].stack > 0, seats[candidate].cashedOut == nil, !seats[candidate].sittingOut {
                return candidate
            }
        }
        return nil
    }
}

/// Errors raised by a table session.
public enum TableSessionError: Error, Equatable, Sendable {
    case invalidSetup
    case invalidBlinds
    case invalidPlayer
    case notEnoughPlayers
    case handInProgress
    case noCurrentHand
    case nothingToUndo
    case rebuysDisabled
}
