import SwiftData
import SwiftUI

@main
struct PokerNightApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
                .preferredColorScheme(.dark)
                .tint(Theme.textPrimary)
                .fontDesign(.rounded)
        }
        .modelContainer(for: [Player.self, Night.self])
    }
}

private struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var showingChecker = false
    @State private var showingRankings = false
    @State private var showingNewNight = false

    var body: some View {
        @Bindable var appModel = appModel
        NavigationStack(path: $appModel.path) {
            List {
                Section {
                    if appModel.hasActiveNight {
                        Button("Resume night") { appModel.resume() }
                    }
                    Button("New night") { showingNewNight = true }
                        .disabled(appModel.hasActiveNight)
                    if appModel.hasActiveNight {
                        Text("Resume and end the current night before starting another.")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
                .listRowBackground(Theme.surface)
                Section {
                    NavigationLink("Past nights", value: AppModel.Route.history)
                    NavigationLink("Players", value: AppModel.Route.players)
                    Button("Hand rankings") { showingRankings = true }
                    Button("Showdown checker") { showingChecker = true }
                }
                .listRowBackground(Theme.surface)
            }
            .themedScreen()
            .navigationTitle("Poker Night")
            .sheet(isPresented: $showingChecker) { ShowdownCheckerView().themedSheet() }
            .sheet(isPresented: $showingRankings) { HandRankingsView().themedSheet() }
            .navigationDestination(for: AppModel.Route.self) { route in
                switch route {
                case .table:
                    if let controller = appModel.activeController { TableView(controller: controller) }
                case .players: PlayersView()
                case .history: HistoryView()
                }
            }
            .alert(appModel.corruptSaveMessage == nil ? "Poker Night" : "Unable to resume night", isPresented: Binding(
                get: { appModel.corruptSaveMessage != nil || appModel.errorMessage != nil },
                set: { if !$0 { appModel.corruptSaveMessage = nil; appModel.errorMessage = nil } }
            )) {
                if appModel.corruptSaveMessage != nil {
                    Button("Cancel", role: .cancel) { appModel.corruptSaveMessage = nil }
                    Button("Delete corrupt saved night", role: .destructive) { appModel.deleteCorruptSave() }
                } else {
                    Button("OK") { appModel.errorMessage = nil }
                }
            } message: { Text(appModel.corruptSaveMessage ?? appModel.errorMessage ?? "") }
            .sheet(isPresented: $showingNewNight, onDismiss: appModel.setupDidDismiss) {
                NightSetupView { session in
                    try appModel.start(session)
                }
                .themedSheet()
            }
        }
    }
}
