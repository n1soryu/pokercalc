import SwiftUI

struct HowToPlayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Text("Run the table with confidence")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                    Text("PokerCalc handles the points and legal actions. You deal the physical cards, announce each action, and tap what happened.")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                }

                HelpSection(title: "A hand, from start to finish") {
                    HelpTerm(term: "Hand", explanation: "One complete deal, from posting blinds until a winner receives the pot.", systemImage: "hand.raised")
                    HelpTerm(term: "Pre-flop", explanation: "Players act after receiving their two private cards.", systemImage: "rectangle.portrait.on.rectangle.portrait")
                    HelpTerm(term: "Flop", explanation: "The first three shared cards.", systemImage: "3.circle")
                    HelpTerm(term: "Turn", explanation: "The fourth shared card.", systemImage: "4.circle")
                    HelpTerm(term: "River", explanation: "The fifth and final shared card.", systemImage: "5.circle")
                    HelpTerm(term: "Showdown", explanation: "Remaining players compare hands and the dealer awards each pot.", systemImage: "eye")
                }

                HelpSection(title: "Positions and forced bets") {
                    HelpTerm(term: "Dealer button", explanation: "Marks the nominal dealer position. It moves clockwise after each hand.", systemImage: "d.circle")
                    HelpTerm(term: "Small blind", explanation: "The smaller forced bet posted before cards are dealt.", systemImage: "s.circle")
                    HelpTerm(term: "Big blind", explanation: "The larger forced bet that sets the minimum opening bet.", systemImage: "b.circle")
                }

                HelpSection(title: "Player actions") {
                    HelpTerm(term: "Check", explanation: "Stay in without adding points when there is no bet to match.", systemImage: "checkmark")
                    HelpTerm(term: "Call", explanation: "Match the current bet, or put in the rest of the stack if it is smaller.", systemImage: "equal")
                    HelpTerm(term: "Bet / Raise", explanation: "Put more points into the pot. PokerCalc shows the legal minimum and maximum.", systemImage: "arrow.up")
                    HelpTerm(term: "Fold", explanation: "Give up the hand. Points already committed stay in the pot.", systemImage: "xmark")
                    HelpTerm(term: "All-in", explanation: "Commit the player's entire remaining stack.", systemImage: "circle.fill")
                }

                HelpSection(title: "Pots and winning") {
                    HelpTerm(term: "Pot", explanation: "All points committed to the hand that the winner can receive.", systemImage: "circle.hexagongrid")
                    HelpTerm(term: "Side pot", explanation: "A separate pot created when an all-in player cannot match every later point.", systemImage: "square.stack.3d.up")
                    HelpTerm(term: "Best five", explanation: "A hand always uses the best five-card combination from the shared cards and the player's two private cards.", systemImage: "5.square")
                    HelpTerm(term: "Split pot", explanation: "Tied winners share the pot. Suits never break a tie.", systemImage: "arrow.left.and.right")
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    Label("Dealer tip", systemImage: "lightbulb")
                        .font(.headline)
                        .foregroundStyle(Theme.warning)
                    Text("Say the action and amount aloud before tapping. If the wrong action is recorded, use Undo before starting the next hand.")
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.Spacing.large)
                .background(Theme.surfaceSecondary, in: .rect(cornerRadius: Theme.Radius.panel))
            }
            .frame(maxWidth: 680)
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .themedScreen()
        .navigationTitle("How to play")
    }
}

private struct HelpSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            VStack(spacing: 0) { content }
                .background(Theme.surfacePrimary, in: .rect(cornerRadius: Theme.Radius.panel))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.panel)
                        .stroke(Theme.border, lineWidth: 1)
                }
        }
    }
}

private struct HelpTerm: View {
    let term: String
    let explanation: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.standard) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.actionPrimary)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                Text(term)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(explanation)
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.standard)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 56)
        }
        .accessibilityElement(children: .combine)
    }
}
