import SwiftData
import SwiftUI

@main
struct PokerNightApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
        }
        .modelContainer(for: [Player.self, Night.self])
    }
}

private struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var context
    @State private var showingChecker = false
    @State private var showingRankings = false
    @State private var showingNewNight = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let controller = appModel.activeController {
                        NavigationLink("Resume night") {
                            TableView(controller: controller)
                        }
                    } else if ActiveNightStore.exists {
                        Button("Resume night") { appModel.resume() }
                    }
                    Button("New night") { showingNewNight = true }
                }
                Section {
                    NavigationLink("Past nights") { HistoryView() }
                    NavigationLink("Players") { PlayersView() }
                    Button("Hand rankings") { showingRankings = true }
                    Button("Showdown checker") { showingChecker = true }
                }
            }
            .navigationTitle("Poker Night")
            .sheet(isPresented: $showingChecker) { ShowdownCheckerView() }
            .sheet(isPresented: $showingRankings) { HandRankingsView() }
            .sheet(isPresented: $showingNewNight) {
                NightSetupView { session in
                    appModel.start(session)
                }
            }
        }
    }
}
