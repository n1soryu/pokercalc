import Testing
@testable import PokerCore

struct CardTests {
    @Test
    func parsesCompactCards() {
        #expect(Card("As") == Card(rank: .ace, suit: .spades))
        #expect(Card("Td") == Card(rank: .ten, suit: .diamonds))
        #expect(Card.parse("Kh 7d 7c") == [
            Card(rank: .king, suit: .hearts),
            Card(rank: .seven, suit: .diamonds),
            Card(rank: .seven, suit: .clubs)
        ])
    }

    @Test
    func rejectsInvalidNotation() {
        #expect(Card("ZZ") == nil)
        #expect(Card("Asx") == nil)
    }

    @Test
    func deckHasFiftyTwoUniqueCards() {
        #expect(Deck.all.count == 52)
        #expect(Set(Deck.all).count == 52)
    }
}
