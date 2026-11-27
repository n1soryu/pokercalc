# PokerCalc UI/UX Redesign Plan

Date: 2026-11-27

Status: Implemented; automated verification passed. This source-grounded plan was written after auditing the repository and before changing implementation code. Hands-on light/dark, VoiceOver, Dynamic Type, and principal-flow sign-off remains pending.

## Product definition

PokerCalc is a calm, trustworthy scorekeeper and pot-calculation companion for a dealer or host running a No-Limit Texas Hold'em night from one shared iPhone. The live table is the product. Roster, history, setup, rankings, and the showdown checker support that table rather than competing with it.

The redesign keeps the target, module, bundle identifier, SwiftData model names, active-save directory, and PokerCore package names stable. Only user-facing branding becomes PokerCalc. This preserves installation continuity, saved history, active-night resume, and source compatibility.

## 1. Current UI inventory

- `PokerNightApp.swift` contains both the app entry point and the complete home screen. It applies a forced dark scheme and a global rounded font design.
- Home contains a welcome header, one active/new-night card, two table tools, and two management links.
- `Theme.swift` provides a single fixed dark green/gold palette, screen and sheet modifiers, a panel modifier, and five button styles.
- `NightSetupView.swift` is one always-editing Form with roster selection, inline roster creation, drag ordering, dealer choice, stack, blinds, rebuy choice, and start action.
- `TableView.swift` is a 444-line feature file containing the table, actor header, pot summary, seat rows, award panels, action controls, raise sheet, and supporting presentation state.
- Live actions are placed at the end of the scrolling table, so they can move below the visible area.
- `TableManagementView.swift` uses one Form implementation for blinds, rebuy, add-player, and cash-out operations.
- `ShowdownCheckerView.swift` includes board and hole-card entry, card selection, evaluation, best-five display, and reset.
- `HandRankingsView.swift` shows ten panel rows with five-card examples and one footer explanation.
- `PlayersView.swift` supports inline add and rename, with swipe-to-delete and no explicit deletion confirmation.
- `HistoryView.swift` supports a summary list, detail screen, and swipe-triggered confirmed deletion.
- `EndNightReviewView.swift` shows original stack, sorted results, and a destructive confirmation action.
- The app icon is original card-and-chip artwork without text. It is not tied to the PokerNight name, but its black/red casino emphasis no longer matches the intended product personality.

## 2. Current navigation and state-flow inventory

```text
App launch
└── HomeView (NavigationStack driven by AppModel.path)
    ├── New night sheet
    │   └── create + autosave TableSession
    │       └── dismiss, then push TableView
    ├── Resume table
    │   └── asynchronously decode active-night.json
    │       └── create GameController, then push TableView
    ├── Showdown checker sheet
    ├── Hand rankings sheet
    ├── Players push
    └── Past nights push

TableView
├── Showdown checker sheet
├── Hand rankings sheet
├── Bet / Raise sheet
├── Table management sheet
└── End-night review sheet
    └── archive to SwiftData, remove active save, return Home
```

- `AppModel` owns navigation, active-controller lifetime, asynchronous resume, corrupt-save recovery, archive-before-delete ordering, and active-night existence.
- `GameController` copies `TableSession`, applies a mutation, writes the complete updated session, and only then publishes it. A write failure therefore leaves the visible session unchanged.
- `TableSession` owns night metadata, seat state, current hand, hand event log, between-hand edits, undo boundaries, point conservation, and results.
- `HandState` and `legalActions` remain the authority for current actor, street, commitments, pots, and legal betting actions.
- SwiftData persists roster and archived nights. `ActiveNightStore` persists an atomic JSON autosave in the existing `PokerNight/active-night.json` application-support directory.
- The showdown checker is independent of the live table and evaluates only the cards entered into it.

## 3. Problems and opportunities found in the source

### Product and navigation

- The home experience knows only whether an autosave exists. On relaunch it cannot show player count, hand number, blinds, or phase before resume.
- Home presents four supporting destinations as similarly shaped cards, which weakens the start/resume decision.
- The table toolbar combines education, checker, table administration, and end-night actions in one menu. Frequency and risk are not reflected in the hierarchy.
- Multiple Boolean sheet states in Home and Table make presentation conflicts easier and the screen logic harder to scan.
- Supporting sheets do not consistently provide an explicit Done or Close action; dismissal can depend on the system gesture.

### Live table

- Current actor, pot, players, and actions are present, but the primary action controls scroll with all other content.
- Street is sometimes a transient instruction banner rather than a stable piece of state. Pre-flop has no beginner explanation.
- Hand number is not presented despite session-wide completed-hand tracking.
- Every seat uses a nearly identical rounded panel. Actor emphasis is mostly a color/border change and the overall screen reads as a stack of dashboard cards.
- Folded rows reduce the entire row to 40% opacity, weakening useful stack and commitment information.
- Seat copy uses “Bet” and “Total” without enough context for beginners.
- Main-pot and side-pot information is split across the pot summary and award panels without a clear “award this next” progression.
- Undo only describes between-hand edits; live poker actions do not communicate what will be reversed.

### Betting and transition states

- Raise controls expose legal bounds indirectly but do not explain stack, current commitment, amount added, or resulting stack.
- The raise stepper uses a fixed increment of 10 even when a smaller exact legal target matters; the slider is difficult to use precisely.
- Completed-hand state reuses the normal scrolling table rather than acting as a deliberate transition with results, corrections, next-hand action, and between-hand tools.
- Management forms dismiss after calling the controller even if persistence fails, because controller mutations return no success result.

### Learning and supporting utilities

- The showdown checker does not state prominently that it cannot award pots or change the table.
- Before the input is complete, the checker does not explain exactly what is still needed.
- Rankings are accurate but are primarily a list, not a reference with best-five and tie-rule teaching structure.
- There is no dedicated Help / How to play destination for the requested vocabulary and rules education.
- Players relies on swipe deletion, has no explicit destructive confirmation, and does not explain roster versus active-table membership.
- History also exposes deletion through a swipe action even though the product calls for explicit controls.
- Empty states are technically present but provide little directional guidance.

### Visual system and accessibility

- `preferredColorScheme(.dark)` and `UIUserInterfaceStyle: Dark` independently force dark mode.
- Theme colors are fixed rather than semantic light/dark values. Required warning, destructive, disabled, border, focus, current-actor, and secondary-action roles are incomplete.
- Global rounded typography makes editorial headings, control labels, and data all share one voice.
- Several important headings use fixed point sizes rather than Dynamic Type text styles.
- Action pairs are fixed horizontal rows and can become crowded with large accessibility text.
- Card slots and rank examples use fixed dimensions; these are acceptable as card illustrations but surrounding text and controls must reflow rather than clip.
- The existing accessibility labels are a strong base, especially for seats, cards, picker availability, and winner selection.

### Documentation drift

- `PLAN.md` says the product is intentionally forced dark, limits teaching to rankings, and describes old black/red/white and green/gold theme decisions in different sections.
- The phase checkboxes remain open while the status text says Phases 0–10 are implemented.
- README branding, theme description, and icon alt text still say PokerNight.

## 4. Proposed PokerCalc information architecture

PokerCalc will use a single NavigationStack hub rather than a tab bar.

- Home is the launch and recovery hub.
- When an active night exists, Resume table is the singular dominant action and includes a compact night summary.
- When no active night exists, Start a night is the singular dominant action.
- Learn poker groups How to play, Hand rankings, and Showdown checker.
- Your records groups Players and Past nights.
- The live table keeps Showdown checker and Rankings directly reachable, while administrative operations appear only in a clearly named Table settings sheet or between-hand section.
- The active table remains a pushed destination so the normal Back action returns to the recovery hub without ending or mutating the night.

This structure keeps a predictable back path, avoids a persistent tab bar during dealer operation, and treats the active night as the primary object.

## 5. Proposed screen hierarchy

```text
PokerCalc Home
├── Active-night hero OR start-night hero
├── Learn poker
│   ├── How to play
│   ├── Hand rankings
│   └── Showdown checker
└── Your records
    ├── Players
    └── Past nights

Table
├── Hand/street context
├── Current actor focus plate
├── Persistent legal-action dock
├── Pot summary
├── Player states
├── Showdown pot awards OR hand-complete transition
├── Between-hand tools
└── Table menu
    ├── Table settings / management
    └── End night
```

Setup remains one screen with three conceptual groups—Players, Table rules, Dealer and start—because the source model is compact and a wizard would add navigation without removing real complexity.

## 6. Proposed design-token system

All app visuals will resolve through semantic values in `Theme.swift` or narrowly focused shared styles.

- Color: `background`, `surfacePrimary`, `surfaceSecondary`, `surfaceElevated`, `textPrimary`, `textSecondary`, `textTertiary`, `actionPrimary`, `actionSecondary`, `actionDestructive`, `success`, `warning`, `cardFace`, `suitRed`, `suitBlack`, `currentActorSurface`, `currentActorBorder`, `disabled`, `border`, `borderStrong`, and `focus`.
- Spacing: 4, 8, 12, 16, 20, 24, and 32 points, expressed as named static values.
- Radius: 10 for compact card/control elements, 14 for buttons, 18 for primary panels, and 24 only for hero/focus surfaces.
- Borders: 1 point for structure, 2 points for selection/current actor, and no decorative border where spacing or surface contrast already groups content.
- Motion: approximately 120 ms press feedback and 220 ms meaningful state transitions. No ambient motion. Reduce Motion removes transforms and keeps opacity/state changes immediate.
- Touch: controls remain at least 44 points tall, with at least 8 points between adjacent actions.

## 7. Typography system

- Editorial display: system serif design for the PokerCalc wordmark, current actor, and major transition headings. Use Dynamic Type-relative styles rather than fixed sizes.
- Utility headings: default system design with semibold weight.
- Body and guidance: default system body, callout, and footnote roles for maximum familiarity.
- Controls: default system body/headline roles, never decorative type.
- Numeric data: the same semantic text styles with monospaced digits for points, blinds, pots, commitments, and results.
- Player names: headline or title3 depending on context, two-line wrapping where necessary, never forced single-line truncation for critical state.

The global rounded font override will be removed. Serif is a deliberate identity accent, not the default voice of every control.

## 8. Light-mode palette

- Canvas / background: `#F5F5F7`, a neutral paper-gray rather than cream.
- Primary surface: `#FFFFFF`.
- Secondary surface: `#ECECF1`.
- Elevated surface: `#FFFFFF` with a structural border rather than a heavy shadow.
- Primary text / suit black: `#17171C`.
- Secondary text: `#52525E`.
- Tertiary text: `#6D6D79` (4.69:1 against the light canvas).
- Primary action: `#343568`, a calm ink-indigo.
- Primary action text: `#FFFFFF`.
- Current actor surface: `#E8E8FA`; border: `#4B4D91`.
- Destructive / red suits: `#B9384E`.
- Success: `#28735F`.
- Warning: `#9A5A12`.
- Card face: `#FFFEFB`.

## 9. Dark-mode palette

- Canvas / background: `#111118`.
- Primary surface: `#1B1B24`.
- Secondary surface: `#242431`.
- Elevated surface: `#2B2B39`.
- Primary text: `#F6F3EF`.
- Secondary text: `#C6C3CE`.
- Tertiary text: `#9793A3`.
- Primary action: `#AEB2FF`.
- Primary action text: `#171722`.
- Current actor surface: `#303052`; border: `#BFC2FF`.
- Destructive / red suits: `#FF7A8B`.
- Success: `#72C6AA`.
- Warning: `#F0B15A`.
- Card face: `#F4F0E8`.

The palettes are paired by semantic intent rather than inverted. Dark surfaces stay distinguishable without glowing, while the current actor remains obvious through placement, label, shape, and border as well as color.

## 10. Shape and surface hierarchy

- Home hero: one large, softly rounded focus surface with a restrained dealer-button/suit motif.
- Section rows: flatter grouped rows with dividers, not a grid of identical cards.
- Table actor focus: a distinctive card-edge plate with a strong leading marker and explicit “To act” label.
- Player rows: quiet score-sheet rows with separators. Only the current actor becomes an elevated focus surface.
- Pot: a compact numeric ledger treatment, not a casino chip pile.
- Buttons: filled primary, tonal secondary, bordered neutral, text/quiet, and separated destructive styles.
- Sheets and Forms: preserve native structure; theme row surfaces, labels, and call-to-action placement rather than recreating every system control.

## 11. Icon and imagery strategy

- Use SF Symbols for actions and navigation, always paired with text when discoverability matters.
- Use code-native suit marks as editorial punctuation and identity cues.
- Use a dealer-button motif for current dealer/current actor contexts, not as decoration on every screen.
- Keep `CardView` code-native and improve its hierarchy and contrast.
- The app icon should move from generic casino red/black toward the new ink-indigo identity and communicate cards plus calculation/scorekeeping. It must remain original, text-free, and legible at small sizes.
- No generated bitmap artwork is required for in-app screens. App-icon raster assets are the only likely bitmap output.

## 12. Table-screen priority hierarchy

1. Persistent street and hand number.
2. Current actor focus plate with call/check context.
3. Persistent legal-action dock above the bottom safe area.
4. Pot total and side-pot count/details.
5. Player stacks and state rows.
6. Current-street and total-hand commitments.
7. Pot awarding, completion correction, and next-hand transition.
8. Checker, rankings, and low-frequency administration.

At accessibility Dynamic Type sizes, action rows become vertical. The action dock stays visible but never overlays scroll content because it uses a safe-area inset.

## 13. Beginner education strategy

- Add a skimmable How to play screen covering hand, streets, dealer button, blinds, actions, pot, side pot, showdown, and best-five rules.
- Put the poker term first and a one-sentence explanation second.
- Add the current street's concise explanation near the table header.
- Explain current action meaning in the live action dock, such as “Call 20 — match the current bet.”
- Add short, contextual explanations to setup fields and between-hand operations.
- Make Rankings a reference plus best-five/tie-rule primer.
- Make Showdown Checker explicitly non-mutating and always end results with “Return to the table to select winners” when launched during play.
- Do not introduce a blocking carousel or mandatory onboarding state.

## 14. Accessibility strategy

- Keep every critical action as a `Button`, Stepper, Toggle, Picker, TextField, or other native semantic control.
- Maintain 44-point minimum touch targets and at least 8-point separation.
- Use labels, icons, shape, position, and borders in addition to color for actor, folded, all-in, winner selection, success, warning, and destructive states.
- Keep existing card, seat, blind, dealer, pot, and winner accessibility labels and refine them as layouts change.
- Group table summaries in the same order they are visually read: phase, actor, action context, pot, players, secondary details.
- Add explicit accessibility values for selected winners, raise amount, legal bounds, and table state.
- Announce consequential state changes, such as street progression, hand completion, and persistence errors, where native presentation does not already do so.
- Respect Reduce Motion in the shared button and actor-emphasis styles.
- Preserve full text in error messages and always include recovery guidance.

## 15. Responsive and Dynamic Type strategy

- Use semantic text styles and relative serif designs rather than fixed point sizes for primary content.
- Use `ViewThatFits` or Dynamic Type-aware layout selection for horizontal action pairs, metadata rows, and result summaries.
- Let player names wrap to two or more lines where critical; give them layout priority over decorative icons.
- Keep the table a single column on compact iPhone widths and at accessibility text sizes.
- Reflow supporting content into two columns only where a regular-width proposal clearly benefits and reading order remains intact.
- Avoid horizontal scrolling for actions, player data, setup, or history.
- Preserve the existing portrait-only product choice unless interactive validation demonstrates a need to support landscape; layouts will still avoid screen-size assumptions.
- Use safe-area insets for the live action dock, never hardcoded bottom padding.

## 16. Proposed implementation passes

### Pass 1 — Foundation and branding

- Add dynamic semantic theme tokens, spacing/type/shape roles, and reusable section/button/status styles.
- Remove both dark-mode locks and the global rounded-font override.
- Change the display name and visible copy to PokerCalc while retaining target/module/bundle/persistence identifiers.
- Refresh the accent asset and app icon to the new identity.

### Pass 2 — Home, navigation, and help

- Split Home from the app entry file.
- Add source-backed active-night summary loading without mutating the session.
- Implement the single-primary-action home hierarchy.
- Add How to play and consolidate learning destinations.
- Move to enum-driven sheet presentation where it reduces conflicting state.

### Pass 3 — Live table foundation

- Split the monolithic Table file into focused presentation components.
- Add hand/street presentation helpers and test them.
- Implement actor focus, pot ledger, score-sheet player rows, and safe-area action dock.
- Keep legal actions and every mutation routed through GameController/PokerCore.

### Pass 4 — Betting, awards, completion, and management

- Redesign raise entry around legal range, current stack, current commitment, added amount, resulting stack, and legal presets.
- Clarify pot-award order and checker separation.
- Add a deliberate completed-hand transition and clear next-hand action.
- Separate between-hand tools from live actions and keep unavailable reasons visible.
- Make management sheets dismiss only after successful persistence.

### Pass 5 — Learning and supporting features

- Redesign Showdown Checker, Rankings, and How to play.
- Redesign setup into conceptual groups.
- Redesign Players and History with explicit, confirmed deletion controls and directional empty states.
- Polish end-night review and error recovery.

### Pass 6 — Accessibility, validation, and documentation

- Review Dynamic Type, VoiceOver order/labels, light/dark contrast, Reduce Motion, long names, and compact widths.
- Run all automated tests and builds after each meaningful group.
- Reconcile PLAN and README with actual behavior and clearly preserve owner-only interactive validation as pending where it cannot be automated.

## 17. Test and validation plan

- Preserve and repeatedly run all 45 PokerCore tests.
- Preserve all app tests; add tests for any extracted presentation/state decisions rather than testing SwiftUI view values.
- Add coverage for active-night summaries, hand-number/street copy, undo descriptions where introduced, and management success/failure dismissal decisions.
- Run `xcodegen generate` after adding or moving source files or changing project configuration.
- Run app tests on an available named iOS Simulator.
- Run the generic iOS Simulator build with code signing disabled.
- Run `git diff --check`.
- Search for raw colors, forced color schemes, stale visible PokerNight copy, fixed critical text sizes, and gesture-only destructive actions.
- Manually inspect light and dark appearances, smallest supported iPhone width, long player names, accessibility Dynamic Type sizes, VoiceOver reading order, and Reduce Motion.
- Manually exercise: fresh setup, resume, legal actions, illegal-action prevention, raise presets, all-in side pots, pot awards, split pot, undo during betting, undo award, between-hand management, next hand, end-night review, history, corrupt-save recovery, rankings, and checker non-mutation.

Baseline recorded before implementation: 45 PokerCore tests pass and the generic iOS Simulator build succeeds on 2026-11-27.

## 18. Risks and behavior changes

- Display-name change is safe. Target name, executable/module name, bundle identifier, SwiftData types, and application-support save directory remain stable.
- Loading a home summary adds read-only autosave I/O. It must remain asynchronous and must not rewrite, delete, or claim corruption without the existing recovery flow.
- A persistent action dock changes layout structure but not legal-action calculation. It must be verified against small heights and accessibility sizes.
- Richer undo labels may require reading the existing public hand event log. They must never change event ordering or undo behavior.
- Management dismissal behavior may require GameController mutations to return success; this is an API-shape change inside the UI layer, not a poker-rule change.
- App icon replacement changes only assets. It does not affect identifiers or persisted data.
- Interactive visual and VoiceOver sign-off remains a required owner/device check if simulator control is unavailable; documentation must not claim it is complete solely from a successful build.

## Design self-critique

The first automated design-system suggestion was a generic web “hero + features + CTA” structure, pink accent, and downloadable font pairing. Those recommendations do not fit a native offline dealer utility and are rejected. PokerCalc instead uses native system type, a single state-aware home hero, an ink-indigo action color, restrained card/dealer motifs, and a score-sheet table structure. Warmth comes from tactile spacing, serif editorial moments, and card-face tones—not from the common cream/terracotta template or casino green.
