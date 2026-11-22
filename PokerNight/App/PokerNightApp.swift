import PokerCore
import SwiftUI

@main
struct PokerNightApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

private struct HomeView: View {
    private let sampleCards = [
        Card(rank: .ace, suit: .spades),
        Card(rank: .king, suit: .hearts),
        Card(rank: .ten, suit: .diamonds)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Poker Night")
                    .font(.largeTitle.bold())
                HStack(spacing: 12) {
                    ForEach(sampleCards, id: \.self) { card in
                        CardView(card: card)
                    }
                }
                Text("Your table starts here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Poker Night")
        }
    }
}
