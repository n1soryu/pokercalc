import Foundation
import Testing
@testable import PokerCore

struct EngineTests {
    private let a = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let b = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let c = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

    private func setup(_ stacks: [Int] = [200, 200, 200], button: Int = 0) -> HandSetup {
        HandSetup(
            seats: [SeatSetup(id: a, name: "A", stack: stacks[0]), SeatSetup(id: b, name: "B", stack: stacks[1]), SeatSetup(id: c, name: "C", stack: stacks[2])],
            buttonIndex: button,
            smallBlind: 5,
            bigBlind: 10
        )
    }

    private func totalTracked(_ state: HandState) -> Int {
        state.seats.reduce(0) { $0 + $1.stack + $1.committedTotal }
    }

    @Test
    func everyoneFoldsToBigBlind() throws {
        let state = try replay(setup(), [.action(.fold), .action(.fold)])
        #expect(state.handEndedWithoutShowdown)
        #expect(state.street == .complete)
        #expect(state.seats.first(where: { $0.id == c })?.stack == 205)
    }

    @Test
    func callersReachFlopWithActorLeftOfButton() throws {
        let state = try replay(setup(), [.action(.call), .action(.call), .action(.check)])
        #expect(state.street == .flop)
        #expect(state.currentActorIndex == 1)
    }

    @Test
    func bigBlindOptionRaiseReopensAction() throws {
        let state = try replay(setup(), [.action(.call), .action(.call), .action(.betOrRaise(to: 20))])
        #expect(state.street == .preflop)
        #expect(state.currentActorIndex == 0)
    }

    @Test
    func minimumRaiseUsesLastFullRaise() throws {
        let state = try replay(setup(), [.action(.call), .action(.call), .action(.betOrRaise(to: 25))])
        #expect(legalActions(state).minRaiseTo == 40)
    }

    @Test
    func shortAllInDoesNotReopenPriorActor() throws {
        let s = setup([200, 120, 300])
        let state = try replay(s, [.action(.call), .action(.call), .action(.check), .action(.betOrRaise(to: 100)), .action(.allIn)])
        #expect(legalActions(state).minRaiseTo == nil || legalActions(state).callAmount == 0)
    }

    @Test
    func unactedPlayerCanRaiseOverShortAllIn() throws {
        let s = setup([300, 300, 130])
        let state = try replay(s, [
            .action(.call), .action(.call), .action(.check),
            .action(.betOrRaise(to: 100)), .action(.allIn)
        ])
        #expect(state.currentActorIndex == 0)
        #expect(legalActions(state).minRaiseTo == 220)
        #expect(try apply(.action(.betOrRaise(to: 220)), to: state).currentActorIndex == 1)
    }

    @Test
    func buildsLayeredPots() {
        let built = buildPots(contributions: [a: 50, b: 150, c: 400], folded: [])
        #expect(built.pots == [
            Pot(amount: 150, eligible: [a, b, c].sorted { $0.uuidString < $1.uuidString }),
            Pot(amount: 200, eligible: [b, c].sorted { $0.uuidString < $1.uuidString })
        ])
        #expect(built.returned[c] == 250)
    }

    @Test
    func foldedContributionRemainsInPot() {
        let built = buildPots(contributions: [a: 40, b: 100, c: 100], folded: [a])
        #expect(built.pots == [Pot(amount: 240, eligible: [b, c].sorted { $0.uuidString < $1.uuidString })])
    }

    @Test
    func headsUpButtonPostsSmallBlindAndActsFirst() throws {
        let s = HandSetup(
            seats: [SeatSetup(id: a, name: "A", stack: 100), SeatSetup(id: b, name: "B", stack: 100)],
            buttonIndex: 0,
            smallBlind: 5,
            bigBlind: 10
        )
        let state = try replay(s, [])
        #expect(state.seats[0].committedThisStreet == 5)
        #expect(state.currentActorIndex == 0)
    }

    @Test
    func oddSplitGoesLeftOfButton() throws {
        let s = setup()
        var state = try replay(s, [])
        state.seats[0].stack -= 5
        state.seats[0].committedThisStreet += 5
        state.seats[0].committedTotal += 5
        state.seats[1].stack -= 5
        state.seats[1].committedThisStreet += 5
        state.seats[1].committedTotal += 5
        state.street = .showdown
        state.pots = [Pot(amount: 25, eligible: [a, b])]
        #expect(state.isPointConserved)
        let aBefore = state.seats.first(where: { $0.id == a })?.stack
        let bBefore = state.seats.first(where: { $0.id == b })?.stack
        let awarded = try apply(.award(potIndex: 0, winners: [a, b]), to: state)
        #expect(awarded.seats.first(where: { $0.id == b })?.stack == bBefore.map { $0 + 13 })
        #expect(awarded.seats.first(where: { $0.id == a })?.stack == aBefore.map { $0 + 12 })
        #expect(awarded.isPointConserved)
    }

    @Test
    func codableSetupAndEventsReplay() throws {
        let events: [HandEvent] = [.action(.call), .action(.call), .action(.check)]
        let data = try JSONEncoder().encode(events)
        let decoded = try JSONDecoder().decode([HandEvent].self, from: data)
        #expect(try replay(setup(), events) == replay(setup(), decoded))
    }

    @Test
    func shortSmallBlindStillLetsHandContinue() throws {
        let s = HandSetup(
            seats: [SeatSetup(id: a, name: "A", stack: 3), SeatSetup(id: b, name: "B", stack: 100), SeatSetup(id: c, name: "C", stack: 100)],
            buttonIndex: 0,
            smallBlind: 5,
            bigBlind: 10
        )
        let state = try replay(s, [.action(.call), .action(.call), .action(.check)])
        #expect(state.street == .flop)
        #expect(state.seats[0].status == .allIn)
    }

    @Test
    func allInPreflopSkipsToShowdown() throws {
        let s = HandSetup(
            seats: [SeatSetup(id: a, name: "A", stack: 20), SeatSetup(id: b, name: "B", stack: 20)],
            buttonIndex: 0,
            smallBlind: 5,
            bigBlind: 10
        )
        let state = try replay(s, [.action(.allIn), .action(.call)])
        #expect(state.street == .showdown)
        #expect(state.currentActorIndex == nil)
    }

    @Test
    func replayingPrefixRestoresPreviousStreet() throws {
        let events: [HandEvent] = [.action(.call), .action(.call), .action(.check)]
        let before = try replay(setup(), Array(events.dropLast()))
        let after = try replay(setup(), events)
        #expect(before.street == .preflop)
        #expect(before.currentActorIndex == 2)
        #expect(after.street == .flop)
        #expect(totalTracked(before) == totalTracked(after))
    }
}
