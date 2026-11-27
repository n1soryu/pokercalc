import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var presentedSheet: HomeSheet?
    @State private var openTableAfterDismiss = false

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack(path: $appModel.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    PokerCalcHeader()
                    ActiveNightHero(
                        hasActiveNight: appModel.hasActiveNight,
                        summary: appModel.activeNightSummary,
                        isResuming: appModel.isResuming,
                        onPrimaryAction: primaryAction
                    )
                    HomeLinkSection(
                        title: "Learn poker",
                        subtitle: "Rules and quick references stay out of the way until you need them."
                    ) {
                        NavigationLink(value: AppModel.Route.help) {
                            HomeLinkRow(title: "How to play", subtitle: "A dealer-friendly guide to terms and table flow", systemImage: "book.pages")
                        }
                        Button { presentedSheet = .rankings } label: {
                            HomeLinkRow(title: "Hand rankings", subtitle: "Strongest to weakest, with card examples", systemImage: "list.number")
                        }
                        Button { presentedSheet = .checker } label: {
                            HomeLinkRow(title: "Showdown checker", subtitle: "Compare hands without changing the table", systemImage: "rectangle.portrait.on.rectangle.portrait")
                        }
                    }
                    HomeLinkSection(
                        title: "Your records",
                        subtitle: "Roster changes here do not change an active table."
                    ) {
                        NavigationLink(value: AppModel.Route.players) {
                            HomeLinkRow(title: "Players", subtitle: "Keep names ready for future nights", systemImage: "person.2")
                        }
                        NavigationLink(value: AppModel.Route.history) {
                            HomeLinkRow(title: "Past nights", subtitle: "Review saved results and table settings", systemImage: "clock.arrow.circlepath")
                        }
                    }
                }
                .frame(maxWidth: 680)
                .padding(.horizontal, Theme.Spacing.large)
                .padding(.vertical, Theme.Spacing.standard)
                .frame(maxWidth: .infinity)
            }
            .themedScreen()
            .navigationTitle("")
            .navigationDestination(for: AppModel.Route.self, destination: destination)
            .sheet(item: $presentedSheet, onDismiss: sheetDidDismiss, content: sheet)
            .alert(
                appModel.corruptSaveMessage == nil ? "PokerCalc" : "Unable to resume table",
                isPresented: alertIsPresented
            ) {
                if appModel.corruptSaveMessage != nil {
                    Button("Keep saved table", role: .cancel) { appModel.corruptSaveMessage = nil }
                    Button("Delete damaged table", role: .destructive) { appModel.deleteCorruptSave() }
                } else {
                    Button("OK") { appModel.errorMessage = nil }
                }
            } message: {
                Text(appModel.corruptSaveMessage ?? appModel.errorMessage ?? "")
            }
            .task { await appModel.prepareHome() }
        }
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { appModel.corruptSaveMessage != nil || appModel.errorMessage != nil },
            set: {
                if !$0 {
                    appModel.corruptSaveMessage = nil
                    appModel.errorMessage = nil
                }
            }
        )
    }

    private func primaryAction() {
        if appModel.hasActiveNight {
            Task { await appModel.resume() }
        } else {
            presentedSheet = .newNight
        }
    }

    private func sheetDidDismiss() {
        guard openTableAfterDismiss else { return }
        openTableAfterDismiss = false
        appModel.setupDidDismiss()
    }

    @ViewBuilder
    private func destination(_ route: AppModel.Route) -> some View {
        switch route {
        case .table:
            if let controller = appModel.activeController {
                TableView(controller: controller)
            }
        case .help:
            HowToPlayView()
        case .players:
            PlayersView()
        case .history:
            HistoryView()
        }
    }

    @ViewBuilder
    private func sheet(_ sheet: HomeSheet) -> some View {
        switch sheet {
        case .newNight:
            NightSetupView { session in
                try appModel.start(session)
                openTableAfterDismiss = true
            }
                .themedSheet()
        case .checker:
            ShowdownCheckerView()
                .themedSheet()
        case .rankings:
            HandRankingsView()
                .themedSheet()
        }
    }
}

private enum HomeSheet: String, Identifiable {
    case newNight
    case checker
    case rankings

    var id: String { rawValue }
}

private struct PokerCalcHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                Text("♠")
                    .font(.title2)
                    .foregroundStyle(Theme.actionPrimary)
                    .accessibilityHidden(true)
                Text("PokerCalc")
                    .font(Theme.Typography.display)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("The dealer's calm second set of eyes.")
                .font(.title3)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ActiveNightHero: View {
    let hasActiveNight: Bool
    let summary: ActiveNightSummary?
    let isResuming: Bool
    let onPrimaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            Label(
                hasActiveNight ? "Table saved and ready" : "Ready when the cards are",
                systemImage: hasActiveNight ? "checkmark.circle.fill" : "circle.dotted"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(hasActiveNight ? Theme.success : Theme.actionPrimary)

            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text(hasActiveNight ? "Return to the table" : "Start a night")
                    .font(Theme.Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                Text(hasActiveNight
                     ? "Your stacks, pots, and current hand are saved on this iPhone."
                     : "PokerCalc tracks points, pots, and legal actions while one dealer runs the phone.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let summary {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Spacing.xLarge) { summaryItems(summary) }
                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) { summaryItems(summary) }
                }
            }

            Button(action: onPrimaryAction) {
                if isResuming {
                    HStack(spacing: Theme.Spacing.small) {
                        ProgressView()
                        Text("Opening table…")
                    }
                } else {
                    Label(hasActiveNight ? "Resume table" : "Start a night", systemImage: hasActiveNight ? "arrow.right.circle.fill" : "play.fill")
                }
            }
            .buttonStyle(ThemedButtonStyle(kind: .strong))
            .disabled(isResuming)
        }
        .padding(Theme.Spacing.xLarge)
        .background(Theme.surfaceElevated, in: .rect(cornerRadius: Theme.Radius.hero))
        .overlay(alignment: .topTrailing) {
            Text(hasActiveNight ? "D" : "♣")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(Theme.actionPrimary.opacity(0.12))
                .padding(Theme.Spacing.large)
                .accessibilityHidden(true)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.hero)
                .stroke(Theme.border, lineWidth: 1)
        }
    }

    @ViewBuilder
    private func summaryItems(_ summary: ActiveNightSummary) -> some View {
        HeroMetric(label: "Players", value: "\(summary.playerCount)")
        HeroMetric(label: "Hand", value: "\(summary.handNumber)")
        HeroMetric(label: "Blinds", value: "\(summary.smallBlind)/\(summary.bigBlind)")
        HeroMetric(label: "Phase", value: summary.phase)
    }
}

private struct HeroMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct HomeLinkSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            VStack(spacing: 0) { content }
                .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.panel)
                        .stroke(Theme.border, lineWidth: 1)
                }
        }
    }
}

private struct HomeLinkRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: Theme.Spacing.standard) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.actionPrimary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: Theme.Spacing.small)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.standard)
        .padding(.vertical, Theme.Spacing.small)
        .contentShape(.rect)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 60)
        }
    }
}
