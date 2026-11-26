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
                .tint(Theme.accent)
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    welcomeHeader
                    nightCard
                    toolsSection
                    manageSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .themedScreen()
            .navigationTitle("")
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

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now, format: .dateTime.weekday(.wide))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text("Poker Night")
                .font(.system(size: 38, weight: .bold, design: .serif))
                .foregroundStyle(Theme.textPrimary)
            Text("Keep the table moving.")
                .font(.title3)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var nightCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label(appModel.hasActiveNight ? "Night in progress" : "Ready for a game", systemImage: appModel.hasActiveNight ? "circle.fill" : "moon.stars.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(appModel.hasActiveNight ? Theme.success : Theme.accent)
                Spacer()
                Image(systemName: "suit.club.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.textTertiary)
            }
            Text(appModel.hasActiveNight ? "Pick up where you left off." : "Set the seats, deal the first hand, and let the app handle the math.")
                .font(.title3.weight(.medium))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if appModel.hasActiveNight {
                Button {
                    Task { await appModel.resume() }
                } label: {
                    if appModel.isResuming {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Opening table…")
                        }
                    } else {
                        Text("Resume table")
                    }
                }
                .buttonStyle(ThemedButtonStyle(kind: .strong))
                .disabled(appModel.isResuming)
            } else {
                Button("Set up a night") { showingNewNight = true }
                    .buttonStyle(ThemedButtonStyle(kind: .strong))
            }
        }
        .padding(20)
        .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 22))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 120, height: 120)
                .offset(x: 34, y: -44)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("At the table")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 12) {
                homeTool("Showdown", subtitle: "Compare hands", icon: "rectangle.portrait.on.rectangle.portrait") { showingChecker = true }
                homeTool("Rankings", subtitle: "Learn the order", icon: "list.number") { showingRankings = true }
            }
        }
    }

    private var manageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keep things tidy")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 12) {
                NavigationLink(value: AppModel.Route.players) { homeToolLabel("Players", icon: "person.2.fill") }
                NavigationLink(value: AppModel.Route.history) { homeToolLabel("Past nights", icon: "clock.arrow.circlepath") }
            }
        }
    }

    private func homeTool(_ title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title2).foregroundStyle(Theme.accent)
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func homeToolLabel(_ title: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundStyle(Theme.textTertiary)
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(16)
        .background(Theme.surfaceMuted, in: RoundedRectangle(cornerRadius: 16))
    }
}
