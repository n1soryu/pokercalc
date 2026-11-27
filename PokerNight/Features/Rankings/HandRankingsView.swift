import PokerCore
import SwiftUI

struct HandRankingsView: View {
    @Environment(\.dismiss) private var dismiss

    private let rankings: [RankingRow] = [
        RankingRow(name: "Royal Flush", definition: "A, K, Q, J, and 10 in the same suit.", comparison: "The strongest possible poker hand.", cards: "As Ks Qs Js Ts"),
        RankingRow(name: "Straight Flush", definition: "Five cards in sequence, all in the same suit.", comparison: "Beats four of a kind.", cards: "9h 8h 7h 6h 5h"),
        RankingRow(name: "Four of a Kind", definition: "Four cards of the same rank.", comparison: "Beats a full house.", cards: "9s 9h 9d 9c Ah"),
        RankingRow(name: "Full House", definition: "Three of one rank and two of another.", comparison: "Beats a flush.", cards: "Ks Kh Kd 7s 7h"),
        RankingRow(name: "Flush", definition: "Five cards of the same suit, not in sequence.", comparison: "Beats a straight.", cards: "As Js 8s 5s 2s"),
        RankingRow(name: "Straight", definition: "Five cards in sequence, with mixed suits allowed.", comparison: "Beats three of a kind.", cards: "9s 8h 7d 6c 5s"),
        RankingRow(name: "Three of a Kind", definition: "Three cards of the same rank.", comparison: "Beats two pair.", cards: "Qs Qh Qd 8s 3c"),
        RankingRow(name: "Two Pair", definition: "Two cards of one rank and two of another.", comparison: "Beats one pair.", cards: "Js Jh 4d 4c 9s"),
        RankingRow(name: "Pair", definition: "Two cards of the same rank.", comparison: "Beats high card.", cards: "As Ah 9d 7c 3s"),
        RankingRow(name: "High Card", definition: "When no other hand is made, the highest card plays.", comparison: "The weakest hand category.", cards: "As Jd 8c 5h 2s")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xLarge) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text("Strongest to weakest")
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.textPrimary)
                        Text("A Hold'em hand uses the best five-card combination available from the five shared cards and the player's two private cards.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: Theme.Spacing.medium) {
                        ForEach(Array(rankings.enumerated()), id: \.element.id) { index, ranking in
                            RankingCard(position: index + 1, ranking: ranking)
                        }
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Label("How ties work", systemImage: "equal.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.actionPrimary)
                        Text("When players have the same hand type, compare the most important rank first, then the next rank or kicker. If the same five cards play, split the pot. Suits never break ties.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.large)
                    .background(Theme.surfaceSecondary, in: .rect(cornerRadius: Theme.Radius.panel))
                }
                .frame(maxWidth: 680)
                .padding(Theme.Spacing.large)
                .frame(maxWidth: .infinity)
            }
            .themedScreen()
            .navigationTitle("Hand Rankings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct RankingCard: View {
    let position: Int
    let ranking: RankingRow

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.medium) {
                Text("\(position)")
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.actionPrimary)
                    .frame(width: 30, alignment: .leading)
                VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                    Text(ranking.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(ranking.definition)
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 5) {
                ForEach(ranking.cards, id: \.self) { card in
                    CardView(card: card, size: .compact)
                }
            }

            Text(ranking.comparison)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.large)
        .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .stroke(Theme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct RankingRow: Identifiable {
    let id = UUID()
    let name: String
    let definition: String
    let comparison: String
    let cards: [Card]

    init(name: String, definition: String, comparison: String, cards: String) {
        self.name = name
        self.definition = definition
        self.comparison = comparison
        self.cards = Card.parse(cards)
    }
}
