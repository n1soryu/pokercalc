import PokerCore
import SwiftUI

struct HandRankingsView: View {
    private let rankings: [RankingRow] = [
        RankingRow(name: "Royal Flush", definition: "A, K, Q, J, 10 all in the same suit.", cards: "As Ks Qs Js Ts"),
        RankingRow(name: "Straight Flush", definition: "Five cards in sequence, all in the same suit.", cards: "9h 8h 7h 6h 5h"),
        RankingRow(name: "Four of a Kind", definition: "Four cards of the same rank.", cards: "9s 9h 9d 9c Ah"),
        RankingRow(name: "Full House", definition: "Three of one rank and two of another.", cards: "Ks Kh Kd 7s 7h"),
        RankingRow(name: "Flush", definition: "Five cards of the same suit.", cards: "As Js 8s 5s 2s"),
        RankingRow(name: "Straight", definition: "Five cards in sequence.", cards: "9s 8h 7d 6c 5s"),
        RankingRow(name: "Three of a Kind", definition: "Three cards of the same rank.", cards: "Qs Qh Qd 8s 3c"),
        RankingRow(name: "Two Pair", definition: "Two cards of one rank and two of another.", cards: "Js Jh 4d 4c 9s"),
        RankingRow(name: "Pair", definition: "Two cards of the same rank.", cards: "As Ah 9d 7c 3s"),
        RankingRow(name: "High Card", definition: "When no other hand type is made, the highest card plays.", cards: "As Jd 8c 5h 2s")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rankings) { ranking in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ranking.name)
                                .font(.headline)
                            HStack(spacing: 4) {
                                ForEach(ranking.cards, id: \.self) { card in
                                    CardView(card: card)
                                        .scaleEffect(0.72)
                                        .frame(width: 38, height: 52)
                                }
                            }
                            Text(ranking.definition)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    Text("Same hand type? Compare the highest card, then the next, and so on. Suits never break ties. You only ever use your best five cards.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Hand Rankings")
        }
    }
}

private struct RankingRow: Identifiable {
    let id = UUID()
    let name: String
    let definition: String
    let cards: [Card]

    init(name: String, definition: String, cards: String) {
        self.name = name
        self.definition = definition
        self.cards = Card.parse(cards)
    }
}
