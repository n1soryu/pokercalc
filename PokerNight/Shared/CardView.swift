import PokerCore
import SwiftUI

struct CardView: View {
    let card: Card

    var body: some View {
        VStack(spacing: 2) {
            Text(card.rank.shortName)
                .font(.headline)
            Text(card.suit.symbol)
                .font(.title2)
        }
        .foregroundStyle(card.suit == .hearts || card.suit == .diamonds ? Theme.suitRed : Theme.textPrimary)
        .frame(width: 52, height: 72)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Theme.textSecondary, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.rank.name) of \(card.suit.rawValue)")
    }
}
