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
    @State private var showingChecker = false
    @State private var showingRankings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Poker Night")
                    .font(.largeTitle.bold())
                Button("Showdown checker") {
                    showingChecker = true
                }
                .buttonStyle(.borderedProminent)
                Button("Hand rankings") {
                    showingRankings = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Poker Night")
            .sheet(isPresented: $showingChecker) {
                ShowdownCheckerView()
            }
            .sheet(isPresented: $showingRankings) {
                HandRankingsView()
            }
        }
    }
}
