import PokerCore
import SwiftUI

struct CardView: View {
    let card: Card
    var size: CardDisplaySize = .regular

    var body: some View {
        VStack(spacing: 2) {
            Text(card.rank.shortName)
                .font(.system(size: size.rankSize, weight: .semibold, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: size.suitSize, weight: .medium))
        }
        .foregroundStyle(card.suit == .hearts || card.suit == .diamonds ? Theme.suitRed : Theme.suitBlack)
        .frame(width: size.width, height: size.height)
        .background(Theme.cardFace, in: .rect(cornerRadius: Theme.Radius.compact))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.compact)
                .stroke(Theme.borderStrong.opacity(0.5), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.rank.name) of \(card.suit.rawValue)")
    }
}

enum CardDisplaySize {
    case regular
    case compact

    var width: CGFloat { self == .regular ? 52 : 42 }
    var height: CGFloat { self == .regular ? 72 : 58 }
    var rankSize: CGFloat { self == .regular ? 17 : 14 }
    var suitSize: CGFloat { self == .regular ? 22 : 18 }
}
