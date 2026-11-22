import Foundation

/// A seat participating in a hand.
public struct SeatSetup: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var stack: Int

    /// Creates a seat setup.
    public init(id: UUID = UUID(), name: String, stack: Int) {
        self.id = id
        self.name = name
        self.stack = stack
    }
}

/// The immutable setup used to replay a hand.
public struct HandSetup: Codable, Sendable, Equatable {
    public var seats: [SeatSetup]
    public var buttonIndex: Int
    public var smallBlind: Int
    public var bigBlind: Int

    /// Creates a hand setup.
    public init(seats: [SeatSetup], buttonIndex: Int, smallBlind: Int, bigBlind: Int) {
        self.seats = seats
        self.buttonIndex = buttonIndex
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
    }
}

/// An action announced by the dealer for the current actor.
public enum PlayerAction: Codable, Sendable, Equatable {
    case fold
    case check
    case call
    case betOrRaise(to: Int)
    case allIn
}

/// One event in the deterministic hand log.
public enum HandEvent: Codable, Sendable, Equatable {
    case action(PlayerAction)
    case award(potIndex: Int, winners: [UUID])
}

/// The current street of a hand.
public enum Street: String, Codable, Sendable, Equatable {
    case preflop
    case flop
    case turn
    case river
    case showdown
    case complete
}

/// The status of a seat in the current hand.
public enum SeatStatus: String, Codable, Sendable, Equatable {
    case active
    case folded
    case allIn
}

/// A seat's state after replaying the hand log.
public struct SeatState: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var stack: Int
    public var committedThisStreet: Int
    public var committedTotal: Int
    public var status: SeatStatus

    public var isEligible: Bool { status != .folded }
}

/// A pot and the seats eligible to win it.
public struct Pot: Codable, Sendable, Equatable {
    public let amount: Int
    public let eligible: [UUID]

    /// Creates a pot.
    public init(amount: Int, eligible: [UUID]) {
        self.amount = amount
        self.eligible = eligible
    }
}

/// The legal actions available to the current actor.
public struct LegalActions: Sendable, Equatable {
    public let canFold: Bool
    public let canCheck: Bool
    public let callAmount: Int
    public let minRaiseTo: Int?
    public let maxRaiseTo: Int

    /// Creates legal action metadata.
    public init(canFold: Bool, canCheck: Bool, callAmount: Int, minRaiseTo: Int?, maxRaiseTo: Int) {
        self.canFold = canFold
        self.canCheck = canCheck
        self.callAmount = callAmount
        self.minRaiseTo = minRaiseTo
        self.maxRaiseTo = maxRaiseTo
    }
}

/// The replayed state of a hand.
public struct HandState: Sendable, Equatable {
    public let setup: HandSetup
    public var seats: [SeatState]
    public var street: Street
    public var currentBet: Int
    public var lastFullRaiseSize: Int
    public var currentActorIndex: Int?
    public var pots: [Pot]
    public var handEndedWithoutShowdown: Bool

    var actedSinceRaise: Set<UUID>
    var awardedPotIndices: Set<Int>
}
