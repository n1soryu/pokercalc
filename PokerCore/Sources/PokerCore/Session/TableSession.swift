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

/// The point totals used to verify that a session has neither created nor lost points.
public struct PointTotals: Sendable, Equatable {
    /// All points bought into the night.
    public let buyIns: Int
    /// Points currently in every stack.
    public let stacks: Int
    /// Points committed to an unfinished hand.
    public let committed: Int
    /// Points recorded when players cash out.
    public let cashedOut: Int

    /// All points currently accounted for by the session.
    public var accountedFor: Int { stacks + committed + cashedOut }
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
    /// Stable archive identity; absent in autosaves created before Phase 9.
    public var nightID: UUID?
    /// Configured initial stack, or nil when an older save did not record it.
    public private(set) var startingStack: Int?
    public private(set) var seats: [SessionSeat]
    public private(set) var smallBlind: Int
    public private(set) var bigBlind: Int
    public private(set) var buttonIndex: Int
    public private(set) var rebuysAllowed: Bool
    public private(set) var currentHand: CurrentHand?

    // Optional so sessions saved before table management still decode.
    private var betweenHandEdits: [BetweenHandEdit]?
    private var completedHands: Int?
    private var hasStarted: Bool

    /// Completed hands for the entire night; older saves use the best recorded seat count.
    public var handsPlayed: Int { completedHands ?? seats.map(\.handsPlayed).max() ?? 0 }

    /// The most recent table edit that Undo will reverse before reopening a completed hand.
    public var lastTableEdit: String? { betweenHandEdits?.last?.label }

    private enum BetweenHandEdit: Codable, Equatable, Sendable {
        case blinds(Int, Int)
        case rebuy(SessionSeat)
        case cashOut(SessionSeat)
        case addPlayer(UUID)

        var label: String {
            switch self {
            case .blinds: return "blind change"
            case .rebuy: return "rebuy"
            case .cashOut: return "cash out"
            case .addPlayer: return "added player"
            }
        }
    }

    private mutating func recordEdit(_ edit: BetweenHandEdit) {
        guard currentHand != nil else { return }
        if betweenHandEdits == nil { betweenHandEdits = [] }
        betweenHandEdits?.append(edit)
    }

    private func canAcceptBuyIn(_ amount: Int) -> Bool {
        guard amount > 0 else { return false }
        var remaining = Int.max - amount
        for seat in seats {
            guard seat.totalBuyIn <= remaining else { return false }
            remaining -= seat.totalBuyIn
        }
        return true
    }

    private var eligibleSeats: [SessionSeat] {
        seats.filter { $0.stack > 0 && $0.cashedOut == nil && !$0.sittingOut }
    }

    /// Whether the table is between hands with at least two eligible players.
    public var canStartHand: Bool { canEndNight && eligibleSeats.count >= 2 }

    /// Creates a session before the first hand.
    public init(
        seats: [SessionSeat],
        smallBlind: Int = 1,
        bigBlind: Int = 2,
        buttonIndex: Int = 0,
        rebuysAllowed: Bool = false,
        startingStack: Int? = nil
    ) throws {
        guard seats.count >= 2,
              seats.indices.contains(buttonIndex),
              smallBlind > 0,
              bigBlind >= smallBlind,
              seats.allSatisfy({ $0.stack >= 0 && $0.totalBuyIn >= $0.stack }),
              checkedSum(seats.map(\.totalBuyIn)) != nil else {
            throw TableSessionError.invalidSetup
        }
        self.nightID = UUID()
        self.startingStack = startingStack
        self.seats = seats
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        self.buttonIndex = buttonIndex
        self.rebuysAllowed = rebuysAllowed
        self.currentHand = nil
        self.completedHands = 0
        self.hasStarted = false
        assertPointConservation()
    }

    /// The replayed current hand state, if a hand exists.
    public var currentState: HandState? {
        guard let currentHand else { return nil }
        return try? replay(currentHand.setup, currentHand.events)
    }

    /// Whether final results can be recorded with no unfinished hand.
    public var canEndNight: Bool { currentHand == nil || currentState?.street == .complete }

    /// The session's current point totals, or nil when a decoded session cannot replay safely.
    public var pointTotals: PointTotals? {
        guard let stackTotal = checkedSum(seats.map(\.stack)),
              let buyInTotal = checkedSum(seats.map(\.totalBuyIn)),
              let cashedOutTotal = checkedSum(seats.compactMap(\.cashedOut)) else {
            return nil
        }
        let committed = currentState?.liveCommittedPoints ?? 0
        guard checkedSum([stackTotal, committed, cashedOutTotal]) != nil,
              buyInTotal >= 0 else { return nil }
        return PointTotals(buyIns: buyInTotal, stacks: stackTotal, committed: committed, cashedOut: cashedOutTotal)
    }

    /// Whether all buy-ins are accounted for by stacks, live commitments, and cash-outs.
    public var isPointConserved: Bool {
        guard let totals = pointTotals else { return false }
        return totals.buyIns == totals.accountedFor
    }

    /// Whether the current hand has an event to undo.
    public var canUndo: Bool { currentHand?.events.isEmpty == false }

    /// Starts the next hand and advances the button past busted seats.
    public mutating func startNextHand() throws {
        if let currentHand {
            guard let state = try? replay(currentHand.setup, currentHand.events), state.street == .complete else {
                throw TableSessionError.handInProgress
            }
        }
        let nextButton = hasStarted ? nextSeatWithChips(after: buttonIndex) : seatWithChips(at: buttonIndex)
        guard let nextButton else { throw TableSessionError.notEnoughPlayers }
        let activeSeats = eligibleSeats
        guard activeSeats.count >= 2 else { throw TableSessionError.notEnoughPlayers }
        guard let activeButton = activeSeats.firstIndex(where: { $0.id == seats[nextButton].id }) else {
            throw TableSessionError.notEnoughPlayers
        }

        for index in seats.indices {
            seats[index].sittingOut = seats[index].stack == 0 || seats[index].cashedOut != nil
        }
        let hand = CurrentHand(
            setup: HandSetup(
                seats: activeSeats.map { SeatSetup(id: $0.id, name: $0.name, stack: $0.stack) },
                buttonIndex: activeButton,
                smallBlind: smallBlind,
                bigBlind: bigBlind
            )
        )
        let initialState = try replay(hand.setup, hand.events)
        currentHand = hand
        betweenHandEdits = nil
        buttonIndex = nextButton
        hasStarted = true
        synchronizeStacks(with: initialState)
        assertPointConservation()
    }

    /// Applies an event to the current hand and synchronizes completed stacks.
    public mutating func apply(_ event: HandEvent) throws {
        guard var currentHand else { throw TableSessionError.noCurrentHand }
        let oldState = try replay(currentHand.setup, currentHand.events)
        currentHand.events.append(event)
        let newState = try replay(currentHand.setup, currentHand.events)
        self.currentHand = currentHand
        synchronize(with: oldState, newState: newState)
        assertPointConservation()
    }

    /// Reverses later table edits first, then the most recent event in the current hand.
    public mutating func undo() throws {
        guard var currentHand, !currentHand.events.isEmpty else { throw TableSessionError.nothingToUndo }
        if let edit = betweenHandEdits?.popLast() {
            switch edit {
            case let .blinds(small, big):
                smallBlind = small
                bigBlind = big
            case let .rebuy(previous), let .cashOut(previous):
                if let index = seats.firstIndex(where: { $0.id == previous.id }) {
                    seats[index] = previous
                }
            case let .addPlayer(id):
                seats.removeAll { $0.id == id }
            }
            if betweenHandEdits?.isEmpty == true { betweenHandEdits = nil }
            assertPointConservation()
            return
        }
        let oldState = try replay(currentHand.setup, currentHand.events)
        currentHand.events.removeLast()
        let newState = try replay(currentHand.setup, currentHand.events)
        self.currentHand = currentHand
        synchronize(with: oldState, newState: newState)
        assertPointConservation()
    }

    /// Changes blinds between hands.
    public mutating func setBlinds(smallBlind: Int, bigBlind: Int) throws {
        try requireBetweenHands()
        guard smallBlind > 0, bigBlind >= smallBlind else { throw TableSessionError.invalidBlinds }
        recordEdit(.blinds(self.smallBlind, self.bigBlind))
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
        assertPointConservation()
    }

    /// Adds a new player between hands.
    @discardableResult
    public mutating func addPlayer(name: String, buyIn: Int) throws -> UUID {
        try requireBetweenHands()
        guard canAcceptBuyIn(buyIn), !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TableSessionError.invalidPlayer
        }
        let seat = SessionSeat(name: name, stack: buyIn)
        recordEdit(.addPlayer(seat.id))
        seats.append(seat)
        assertPointConservation()
        return seat.id
    }

    /// Cashes out a player between hands.
    public mutating func cashOut(seat id: UUID) throws {
        try requireBetweenHands()
        guard let index = seats.firstIndex(where: { $0.id == id }), seats[index].cashedOut == nil else {
            throw TableSessionError.invalidPlayer
        }
        recordEdit(.cashOut(seats[index]))
        seats[index].cashedOut = seats[index].stack
        seats[index].stack = 0
        seats[index].sittingOut = true
        assertPointConservation()
    }

    /// Adds points to a player's stack when rebuys are enabled.
    public mutating func rebuy(seat id: UUID, amount: Int) throws {
        try requireBetweenHands()
        guard rebuysAllowed else { throw TableSessionError.rebuysDisabled }
        guard canAcceptBuyIn(amount), let index = seats.firstIndex(where: { $0.id == id }), seats[index].cashedOut == nil else {
            throw TableSessionError.invalidPlayer
        }
        recordEdit(.rebuy(seats[index]))
        seats[index].stack += amount
        seats[index].totalBuyIn += amount
        seats[index].sittingOut = false
        assertPointConservation()
    }

    /// Returns final stacks and net results for every seat.
    public func results() -> [SessionResult] {
        seats.map {
            let finalStack = $0.cashedOut ?? $0.stack
            return SessionResult(id: $0.id, name: $0.name, totalBuyIn: $0.totalBuyIn, finalStack: finalStack, net: finalStack - $0.totalBuyIn)
        }
    }

    private mutating func synchronize(with oldState: HandState, newState: HandState) {
        let previousHandsPlayed = handsPlayed
        for stateSeat in newState.seats {
            guard let index = seats.firstIndex(where: { $0.id == stateSeat.id }) else { continue }
            seats[index].stack = stateSeat.stack
        }
        let wasComplete = oldState.street == .complete
        let isComplete = newState.street == .complete
        if !wasComplete, isComplete {
            completedHands = previousHandsPlayed + 1
            for stateSeat in newState.seats {
                if let index = seats.firstIndex(where: { $0.id == stateSeat.id }) {
                    seats[index].stack = stateSeat.stack
                    seats[index].handsPlayed += 1
                }
            }
        } else if wasComplete, !isComplete {
            completedHands = max(0, previousHandsPlayed - 1)
            for stateSeat in newState.seats {
                if let index = seats.firstIndex(where: { $0.id == stateSeat.id }) {
                    seats[index].handsPlayed = max(0, seats[index].handsPlayed - 1)
                    seats[index].stack = stateSeat.stack
                }
            }
        }
    }

    private mutating func synchronizeStacks(with state: HandState) {
        for stateSeat in state.seats {
            guard let index = seats.firstIndex(where: { $0.id == stateSeat.id }) else { continue }
            seats[index].stack = stateSeat.stack
        }
    }

    private func assertPointConservation() {
        assert(isPointConserved, "PokerNight point conservation failed: \(String(describing: pointTotals))")
    }

    private func requireBetweenHands() throws {
        if !canEndNight {
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

private func checkedSum(_ values: [Int]) -> Int? {
    var total = 0
    for value in values {
        let result = total.addingReportingOverflow(value)
        guard !result.overflow else { return nil }
        total = result.partialValue
    }
    return total
}

/// Errors raised by a table session.
public enum TableSessionError: LocalizedError, Equatable, Sendable {
    case invalidSetup
    case invalidBlinds
    case invalidPlayer
    case notEnoughPlayers
    case handInProgress
    case noCurrentHand
    case nothingToUndo
    case rebuysDisabled

    /// A message suitable for the table's error alert.
    public var errorDescription: String? {
        switch self {
        case .invalidSetup: return "Check the seats, dealer and blinds."
        case .invalidBlinds: return "Use positive blinds with the big blind at least as large as the small blind."
        case .invalidPlayer: return "Check the player and amount. The player must still be at the table and the points must fit in the table total."
        case .notEnoughPlayers: return "At least two players need points to start a hand."
        case .handInProgress: return "Finish the current hand to manage the table."
        case .noCurrentHand: return "Start a hand first."
        case .nothingToUndo: return "There are no actions to undo in this hand."
        case .rebuysDisabled: return "Rebuys are off for this night."
        }
    }
}
