import SwiftUI

struct TableHandHeader: View {
    let presentation: TablePresentation
    let blinds: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.standard) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.standard) {
                    phaseContent
                    Spacer()
                    blindsContent
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    phaseContent
                    blindsContent
                }
            }

            if let actorName = presentation.actorName {
                CurrentActorPlate(name: actorName, prompt: presentation.actionPrompt)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text(presentation.streetName)
                        .font(Theme.Typography.actor)
                        .foregroundStyle(Theme.textPrimary)
                    Text(presentation.actionPrompt)
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.large)
                .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.panel)
                        .stroke(Theme.border, lineWidth: 1)
                }
            }

            Text(presentation.streetExplanation)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }

    private var phaseContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            Text("Hand \(presentation.handNumber)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textTertiary)
            Text(presentation.streetName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var blindsContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            Text("Blinds")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            Text(blinds)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CurrentActorPlate: View {
    let name: String
    let prompt: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.standard) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.currentActorBorder)
                .frame(width: 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Label("To act", systemImage: "location.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.currentActorBorder)
                Text(name)
                    .font(Theme.Typography.actor)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(prompt)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.large)
        .background(Theme.currentActorSurface, in: .rect(cornerRadius: Theme.Radius.hero))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.hero)
                .stroke(Theme.currentActorBorder, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current actor, \(name). \(prompt)")
    }
}

struct BetweenHandsHeader: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label("Table paused safely", systemImage: "pause.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.success)
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct HandCompletePanel: View {
    let handNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label("Hand \(handNumber) complete", systemImage: "checkmark.seal.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.success)
            Text("The awarded points are back in the players' stacks. Undo is still available until you start the next hand.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.large)
        .background(Theme.surfaceSecondary, in: .rect(cornerRadius: Theme.Radius.panel))
        .accessibilityElement(children: .combine)
    }
}
