import PokerCore
import SwiftUI

struct RaiseView: View {
    @Binding var amount: Int
    let targets: RaiseTargets
    let context: RaiseContext
    let onSubmit: () -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isValid: Bool { targets.range.contains(amount) }
    private var addedAmount: Int { context.addedAmount(for: amount) }
    private var remainingStack: Int { context.remainingStack(after: amount) }
    private var actionTitle: String { context.callAmount == 0 ? "Bet to \(amount)" : "Raise to \(amount)" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xLarge) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                        Text(context.playerName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.actionPrimary)
                        Text(context.callAmount == 0 ? "Choose the bet total" : "Choose the raise total")
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Enter the total this player will have committed on the current street—not just the amount being added.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    RaiseSummary(context: context)

                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Raise to")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: Theme.Spacing.medium) {
                            TextField("Total", value: $amount, format: .number)
                                .keyboardType(.numberPad)
                                .font(.title.weight(.semibold).monospacedDigit())
                                .multilineTextAlignment(.center)
                                .frame(minHeight: 54)
                                .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.control))
                                .overlay {
                                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                                        .stroke(isValid ? Theme.borderStrong : Theme.destructive, lineWidth: isValid ? 1 : 2)
                                }
                                .accessibilityLabel("Raise-to total")
                                .accessibilityValue("\(amount) points")

                            Stepper("Adjust raise total", value: $amount, in: targets.range)
                                .labelsHidden()
                                .accessibilityValue("\(amount) points")
                        }
                        Text("Legal range: \(targets.range.lowerBound) to \(targets.range.upperBound)")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(isValid ? Theme.textSecondary : Theme.destructive)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                        Text("Quick totals")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        LazyVGrid(columns: quickColumns, spacing: Theme.Spacing.small) {
                            quickButton("Minimum", value: targets.range.lowerBound)
                            quickButton("Half pot", value: targets.halfPot)
                            quickButton("Pot", value: targets.pot)
                            quickButton("All-in", value: targets.range.upperBound)
                        }
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Theme.Spacing.medium) {
                            ResultMetric(label: "Added now", value: addedAmount)
                            ResultMetric(label: "Stack after", value: remainingStack)
                        }
                        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                            ResultMetric(label: "Added now", value: addedAmount)
                            ResultMetric(label: "Stack after", value: remainingStack)
                        }
                    }

                    Button(actionTitle, action: submit)
                        .buttonStyle(ThemedButtonStyle(kind: .strong))
                        .disabled(!isValid)
                }
                .frame(maxWidth: 620)
                .padding(Theme.Spacing.large)
                .frame(maxWidth: .infinity)
            }
            .themedScreen()
            .navigationTitle("Bet / Raise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var quickColumns: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    private func quickButton(_ title: String, value: Int) -> some View {
        Button("\(title) · \(value)") { amount = value }
            .buttonStyle(ThemedButtonStyle(kind: amount == value ? .primary : .outline))
            .accessibilityLabel("\(title), raise to \(value)")
            .accessibilityAddTraits(amount == value ? .isSelected : [])
    }

    private func submit() {
        guard isValid else { return }
        if onSubmit() { dismiss() }
    }
}

private struct RaiseSummary: View {
    let context: RaiseContext

    var body: some View {
        VStack(spacing: 0) {
            row("Current stack", context.currentStack)
            row("Committed this street", context.currentCommitment)
            row("Call amount", context.callAmount)
            row("Pot before action", context.currentPot)
            row("Minimum legal total", context.minimum)
            row("Maximum legal total", context.maximum)
        }
        .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                .stroke(Theme.border, lineWidth: 1)
        }
    }

    private func row(_ label: String, _ value: Int) -> some View {
        LabeledContent(label) {
            Text("\(value)")
                .monospacedDigit()
        }
        .font(.subheadline)
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, Theme.Spacing.standard)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) { Divider() }
    }
}

private struct ResultMetric: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
            Text("\(value)")
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.standard)
        .background(Theme.surfaceSecondary, in: .rect(cornerRadius: Theme.Radius.control))
        .accessibilityElement(children: .combine)
    }
}
