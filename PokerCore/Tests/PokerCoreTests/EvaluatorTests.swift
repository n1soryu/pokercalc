import Testing
@testable import PokerCore

struct EvaluatorTests {
    private func cards(_ text: String) -> [Card] {
        Card.parse(text)
    }

    @Test
    func twoPairUsesKicker() throws {
        let result = try Showdown.evaluate(
            board: cards("Kh 7d 7c 2s 9h"),
            players: [
                ShowdownPlayer(id: "a", name: "A", holeCards: cards("Ks Qd")),
                ShowdownPlayer(id: "b", name: "B", holeCards: cards("Kd Ac"))
            ]
        )
        #expect(result.winners.map(\.id) == ["b"])
        #expect(result.explanation == "Both have Two Pair, Kings and Sevens. The next-best card decides it: Ace beats Queen.")
    }

    @Test
    func royalFlushOnBoardSplits() throws {
        let result = try Showdown.evaluate(
            board: cards("As Ks Qs Js Ts"),
            players: [
                ShowdownPlayer(id: "a", name: "A", holeCards: cards("2h 3h")),
                ShowdownPlayer(id: "b", name: "B", holeCards: cards("4h 5h"))
            ]
        )
        #expect(result.winners.count == 2)
        #expect(result.winners[0].evaluatedHand.displayName == "Royal Flush")
        #expect(result.explanation == "The board plays for everyone, so the pot splits.")
    }

    @Test
    func fullHouseTopPairWins() throws {
        let result = try Showdown.evaluate(
            board: cards("9c 9d 5h 5s 2c"),
            players: [
                ShowdownPlayer(id: "a", name: "A", holeCards: cards("Kh Kd")),
                ShowdownPlayer(id: "b", name: "B", holeCards: cards("Ah 3c"))
            ]
        )
        #expect(result.winners.map(\.id) == ["a"])
    }

    @Test
    func straightBeatsTrips() throws {
        let result = try Showdown.evaluate(
            board: cards("Ah 2d 3c 9s Kd"),
            players: [
                ShowdownPlayer(id: "a", name: "A", holeCards: cards("4h 5s")),
                ShowdownPlayer(id: "b", name: "B", holeCards: cards("Kh Ks"))
            ]
        )
        #expect(result.winners.map(\.id) == ["a"])
        #expect(result.explanation == "Straight beats Three of a Kind.")
    }

    @Test
    func wheelLosesToSixHighStraight() {
        #expect(bestHand(from: cards("As 2d 3c 4h 5s")).tiebreakers == [.five])
        #expect(bestHand(from: cards("2s 3d 4c 5h 6s")).tiebreakers == [.six])
    }

    @Test
    func flushUsesSecondHighestCard() {
        let a = bestHand(from: cards("As Js 9s 4s 2s"))
        let b = bestHand(from: cards("Ks Qs 9s 4s 2s"))
        #expect(a > b)
    }

    @Test
    func quadsOnBoardUsesKicker() throws {
        let result = try Showdown.evaluate(
            board: cards("9c 9d 9h 9s 2c"),
            players: [
                ShowdownPlayer(id: "a", name: "A", holeCards: cards("Kh Kd")),
                ShowdownPlayer(id: "b", name: "B", holeCards: cards("Ah 3c"))
            ]
        )
        #expect(result.winners.map(\.id) == ["b"])
    }

    @Test
    func fullHouseUsesPairAfterTrips() {
        let kings = bestHand(from: cards("2h 2d 2c Ks Kh"))
        let queens = bestHand(from: cards("2h 2d 2c Qs Qh"))
        #expect(kings > queens)
    }

    @Test
    func incompleteBoardIsFlagged() throws {
        let result = try Showdown.evaluate(
            board: cards("Ah Kd Qc Js"),
            players: [
                ShowdownPlayer(id: "a", name: "A", holeCards: cards("Th 2s")),
                ShowdownPlayer(id: "b", name: "B", holeCards: cards("9h 8s"))
            ]
        )
        #expect(result.isIncompleteBoard)
    }

    @Test
    func duplicateCardThrows() {
        #expect(throws: ShowdownError.duplicateCards) {
            try Showdown.evaluate(
                board: cards("Ah Kd Qc Js Ts"),
                players: [
                    ShowdownPlayer(id: "a", name: "A", holeCards: cards("Ah 2s")),
                    ShowdownPlayer(id: "b", name: "B", holeCards: cards("3h 4s"))
                ]
            )
        }
    }
}
