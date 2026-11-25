import Testing
import PokerCore

struct GameplaySafetyTests {
    private func session(_ stacks: [Int], smallBlind: Int = 1, bigBlind: Int = 2) throws -> TableSession {
        try TableSession(
            seats: stacks.enumerated().map { SessionSeat(name: "Seat \($0.offset)", stack: $0.element) },
            smallBlind: smallBlind, bigBlind: bigBlind
        )
    }

    @Test func shortcutsUseLiveCommitmentsAndRoundDown() throws {
        var night = try session([50, 50, 50])
        try night.startNextHand()
        try night.apply(.action(.call))
        // Small blind has posted 1. Pot is 5, call is 1.
        let blind = try #require(night.currentState.flatMap(RaiseTargets.init))
        #expect(blind.range == 4...50)
        #expect(blind.halfPot == 5)
        #expect(blind.pot == 8)
        try night.apply(.action(.call))
        try night.apply(.action(.check))
        let flop = try #require(night.currentState)
        #expect(flop.potTotal == 6)
        let opening = try #require(RaiseTargets(flop))
        #expect(opening.halfPot == 3)
        #expect(opening.pot == 6)
        try night.apply(.action(.betOrRaise(to: 3)))
        try night.apply(.action(.call))
        // Pot is 12, call is 3. Half of 15 rounds down to 7.
        let facing = try #require(night.currentState.flatMap(RaiseTargets.init))
        #expect(facing.halfPot == 10)
        #expect(facing.pot == 18)
    }

    @Test func shortcutsClampToBothLegalBounds() throws {
        var shortBlind = try session([50, 50, 2], bigBlind: 10)
        try shortBlind.startNextHand()
        let minimum = try #require(shortBlind.currentState.flatMap(RaiseTargets.init))
        #expect(minimum.range == 12...50)
        #expect(minimum.halfPot == 12)
        #expect(minimum.pot == 12)

        var shortActor = try session([50, 4, 50])
        try shortActor.startNextHand()
        try shortActor.apply(.action(.call))
        try shortActor.apply(.action(.call))
        try shortActor.apply(.action(.check))
        let maximum = try #require(shortActor.currentState.flatMap(RaiseTargets.init))
        #expect(maximum.range == 2...2)
        #expect(maximum.halfPot == 2)
        #expect(maximum.pot == 2)
    }

    @Test func endNightAndUndoFollowTheCurrentHandAcrossEveryStreet() throws {
        var night = try session([20, 20])
        #expect(night.canEndNight)
        #expect(!night.canUndo)
        try night.startNextHand()
        #expect(!night.canEndNight)
        #expect(!night.canUndo)
        let initial = night.currentState
        try night.apply(.action(.fold))
        #expect(night.canEndNight)
        #expect(night.canUndo)
        #expect(night.currentState?.potTotal == 0) // Fold win has already cleared the pots.
        try night.undo()
        #expect(night.currentState == initial)
        #expect(!night.canEndNight)
        try night.apply(.action(.call))
        #expect(night.canUndo)
        let called = night.currentState
        try night.undo()
        #expect(night.currentState == initial)
        try night.apply(.action(.call))
        #expect(night.currentState == called)
        try night.apply(.action(.check))
        for street in [Street.flop, .turn, .river] {
            #expect(night.currentState?.street == street)
            #expect(!night.canEndNight)
            #expect(night.canUndo)
            try night.apply(.action(.check))
            try night.apply(.action(.check))
        }
        let showdown = try #require(night.currentState)
        #expect(showdown.street == .showdown)
        #expect(showdown.potTotal == 4)
        #expect(!night.canEndNight)
        #expect(night.canUndo)
        let award = HandEvent.award(potIndex: 0, winners: [night.seats[0].id])
        try night.apply(award)
        #expect(night.canEndNight)
        #expect(night.canUndo)
        #expect(night.currentState?.potTotal == 4)
        #expect(night.results().map(\.finalStack) == [22, 18])
        try night.undo()
        #expect(night.currentState == showdown)
        #expect(!night.canEndNight)
        try night.apply(award)
        try night.startNextHand()
        #expect(!night.canUndo)
        #expect(!night.canEndNight)
        #expect(throws: TableSessionError.nothingToUndo) { try night.undo() }
    }

    @Test func splitAndSidePotAwardsReplayInOrderAfterUndo() throws {
        var night = try session([5, 10, 20])
        try night.startNextHand()
        for _ in 0..<3 { try night.apply(.action(.allIn)) }
        let showdown = try #require(night.currentState)
        #expect(showdown.pots.map(\.amount) == [15, 10])
        #expect(showdown.unawardedPotIndices == [0, 1])
        #expect(showdown.eligibleNames(for: showdown.pots[0]) == ["Seat 0", "Seat 1", "Seat 2"])
        #expect(showdown.eligibleNames(for: showdown.pots[1]) == ["Seat 1", "Seat 2"])
        #expect(showdown.potTotal == 25)
        #expect(showdown.nextPotToAward == 0)
        let main = HandEvent.award(potIndex: 0, winners: [night.seats[0].id, night.seats[1].id])
        let side = HandEvent.award(potIndex: 1, winners: [night.seats[2].id])
        try night.apply(main)
        let partial = try #require(night.currentState)
        #expect(partial.unawardedPotIndices == [1])
        #expect(partial.nextPotToAward == 1)
        #expect(partial.potTotal == 25)
        #expect(!night.canEndNight)
        try night.undo()
        #expect(night.currentState == showdown)
        try night.apply(main)
        try night.apply(side)
        #expect(night.currentState?.nextPotToAward == nil)
        #expect(night.currentState?.potTotal == 25)
        #expect(night.results().map(\.finalStack) == [7, 8, 20])
        try night.undo()
        #expect(night.currentState == partial)
        #expect(!night.canEndNight)
    }
}
