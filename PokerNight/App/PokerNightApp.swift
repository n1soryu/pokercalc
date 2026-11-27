import SwiftData
import SwiftUI

@main
struct PokerNightApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
                .tint(Theme.actionPrimary)
        }
        .modelContainer(for: [Player.self, Night.self])
    }
}
