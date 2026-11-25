# PokerNight: Project Plan

**How to use this file.** This is the single source of truth for the PokerNight iPhone app: what it is, every decision, the full spec, the repo layout and the build plan. To resume work in any new chat (Copilot, Claude or anything else), paste this whole file in or point the assistant at it, and say which phase to work on. Keep it at the repo root as `PLAN.md`. The **Status** section is updated at the end of every phase, so this file always reflects where the project stands.

---

## 1. Status

**Current phase:** Phase 10 — implemented, committed and pushed on 2026-11-25; interactive Simulator, owner-device, and release-tag checks remain

- [x] Phase 0: Environment, Xcode project (XcodeGen), PokerCore package, cards, git
- [x] Phase 1: Hand evaluator and explanations (PokerCore)
- [x] Phase 2: Showdown checker and hand rankings UI
- [x] Phase 3: Betting engine (PokerCore)
- [x] Phase 4: Table session (PokerCore)
- [x] Phase 5: Initial table UI
- [x] Phase 6: Initial roster, night setup, and history UI
- [ ] Phase 7: Gameplay correctness and safety
- [ ] Phase 8: Between-hand table management and showdown integration
- [ ] Phase 9: Setup, navigation, end-night, and history completion
- [ ] Phase 10: Persistence hardening, accessibility, assets, and release validation

**Deviations from this plan** (append one line per deviation: date, phase, what changed, why):

- Theme pass added after Phase N.
- Theme: replaced custom palette with plain black, red, and white; navigation titles remain inline to prevent overlap.
- 2026-11-22: Major tweak — default starting stack changed to 10, with 10-point setup increments and ±10/±100/±1000 raise controls.
- 2026-11-22: Starting stack setup supports direct numeric entry with a 10-point stepper and a 10–10000 valid range.
- 2026-11-22: Fixed completed-hand action bar to offer “Start next hand” instead of displaying a zero-call action.
- 2026-11-24: Completion audit found that Phases 5–6 delivered the initial UI but did not implement every item in Sections 8.4–8.5. Added Phases 7–10 to finish the specification and harden the app.
- 2026-11-24, Phase 7 — The session could run PokerCore tests and type-check the app against the Simulator SDK. The generic Xcode build and interactive playtest remain pending due to local environment restrictions.

- 2026-11-24, Phase 8 — Owner authorized proceeding while Phase 7 owner verification is deferred. Both phase checkboxes remain open pending validation.
- 2026-11-24, Phase 8 — Undo reverses table edits made after hand completion in reverse order before undoing the award. This preserves cash-outs and rebuys when reopening a hand, including after resume. Starting the next hand clears the undo history.

- 2026-11-25, Phase 9 — Owner requested Phase 9 on top of the existing Phase 7–8 working tree. Earlier phase sign-offs remain pending; their changes were preserved.
- 2026-11-25, Phase 9 — Owner chose “Not recorded” for the original starting stack of legacy autosaves. New sessions store the configured stack separately from buy-ins; existing history retains its saved values.
- 2026-11-25, Phase 9 — Added a session-wide completed-hand counter because per-seat maximums undercount after complete player turnover. Legacy autosaves retain the best available per-seat count; previously unrecorded history cannot be reconstructed.
- 2026-11-25, Phases 7–9 — Owner asked to commit and push all pending work before interactive sign-off. Because the phase changes share files, they were committed together rather than as separate phase commits; the phase checkboxes remain open until manual verification is recorded.
- 2026-11-25, Phase 10 — Added a generated original card-and-chip icon because no source artwork existed. It uses only the project's black, white, and red palette and contains no text or third-party card art.

**Open questions** (append; remove when answered):

- (none yet)

**Project facts** (fill in as they become known):

- Apple Development Team ID: `ZMY7V3G25Z`
- Bundle ID: `com.uzayer.pokernight`
- Xcode version used: `Xcode 27.2 (build 27B52)`
- Latest theme commit: `d7d65eb` — plain black, red, and white theme
- Current implementation: Phases 0–10 are implemented and pushed to `origin/main`. Phases 7–9 were committed together on 2026-11-25 at the owner's request; their checkboxes remain open pending interactive Simulator sign-off. Phase 10 is committed and pushed, and awaits interactive Simulator, owner-device, and tag-authorization checks.
- Pre-Phase 7 verification on 2026-11-24: all 34 PokerCore tests pass; the iOS Simulator build succeeds without compiler warnings.
- Phase 7 automated verification on 2026-11-24: all 38 PokerCore tests passed, including live-pot shortcuts and limits, pot totals, end-night eligibility on every street, and undo/re-award across side pots and hand boundaries. All app Swift sources type-checked for the arm64 iOS Simulator with warnings treated as errors.
- Phase 7 build and manual verification on 2026-11-24: the Section 2 generic build was attempted. Xcode package resolution encountered restricted cache writes and, with a writable module cache, a denied manifest sandbox. CoreSimulatorService refused the connection. No interactive scenarios were verified. On a Mac with Simulator access, run the Section 2 build and Section 9 Phase 7 item 7, then record the device and outcome before checking off and committing the phase.
- Phase 8 automated verification on 2026-11-24: 41 PokerCore tests passed. Both controller tests passed with the same controller, store and test sources in a temporary macOS SwiftPM harness. App sources passed arm64 iOS Simulator SDK type-checking with warnings as errors. XcodeGen generated the iOS unit-test target. The generic build and Simulator test command both stopped at SwiftPM cache permissions during package resolution.
- Phase 8 owner verification: run the Section 2 generic build and the PokerNight scheme tests on an available iPhone Simulator. Exercise blinds, rebuy preview, add, cash-out cancellation/confirmation, one-player start blocking and recovery, disabled management while betting/at showdown, and separate main/side-pot checkers. Confirm checker edits leave winners untouched. Record the device and results here before phase sign-off.
- Phase 9 implementation on 2026-11-25: inline roster creation with trimmed/unique names, selected seat ordering with drag handles, explicit/random first dealer, validated setup, direct start/resume navigation, recoverable corrupt autosaves, an explicit final-results review, original starting-stack metadata, sorted history summaries/details, and confirmed history deletion. Starting another night is blocked until the existing night ends. Archive saves precede active-file removal; retries use a stable identity to avoid duplicate nights.
- Phase 9 automated verification on 2026-11-25: all 43 PokerCore tests passed. All 18 app test methods passed (25 runs including parameterized cases) on iPhone Duo / iOS 27.1, including setup order/dealer/validation, start/resume/end navigation, corrupt-save recovery isolation, exact starting-stack persistence after rebuy, legacy metadata, sorted results, archive retry deduplication, and disk-backed migration preserving existing history and roster. The Section 2 generic iOS Simulator build succeeded with no Swift compiler warnings; Xcode emitted its App Intents metadata-skipped warning because the app has no AppIntents dependency. XcodeGen regeneration and `git diff --check` passed. This run also exercised the existing Phase 8 controller tests; prior phases still need their interactive sign-off.
- Phase 9 manual verification remains pending: interactive Simulator control is unavailable because Device hub/Agent device access is disabled for this environment. The CUA app inventory also cannot open Simulator. Verify inline add/duplicate-name errors, drag seat ordering, dealer selection/randomization, invalid stack entry, one-step start, app relaunch/one-tap resume, corrupt-save cancel/delete, review cancel/confirm, history metadata/results, and deletion cancel/confirm on an iPhone Simulator. The Phase 7, 8 and 9 checkboxes remain open until this required verification is recorded; the code was committed and pushed at the owner's request.
- 2026-11-25 pre-push verification: all 43 PokerCore tests passed, all 18 app test methods passed (25 runs including parameterized cases) on iPhone Duo / iOS 27.1, the Section 2 generic iOS Simulator build succeeded, `xcodegen generate` regenerated the project, and `git diff --check` reported no whitespace errors.
- 2026-11-25 delivery: `master` was pushed to `origin/main` with upstream tracking. The remote's one-line README `Initial commit` was merged into the local history first because the two histories were unrelated; no remote content was overwritten.
- Phase 10 implementation and automated verification on 2026-11-25: active-night writes are atomic and reject unbalanced sessions; load rejects decodable-but-unbalanced saves as recoverable corruption; final-history save failures retain the active file; roster add, rename, and delete actions now show SwiftData save errors. PokerCore debug-asserts point conservation after every engine/session mutation and exposes audited point totals. Accessibility labels and state descriptions now cover cards, card-picker availability, table options, seats, blind/dealer/current-actor state, pots, winner selection, and start actions. The table and setup accommodate long names and large Dynamic Type; raise controls use a two-column grid. Added complete iPhone and App Store icon assets. Automated verification passed: 45 PokerCore tests, 20 app test methods (27 runs with parameterized cases) on iPhone Duo / iOS 27.1, generic iOS Simulator build, XcodeGen generation, asset compilation, and `git diff --check`.
- Phase 10 interactive/release checks pending: Device hub/Agent device access is unavailable, so the clean end-to-end Simulator playtest and VoiceOver/Dynamic Type visual inspection could not run here. On a Simulator, verify the full flow from empty install through roster/setup, multiple hands, management, relaunch/resume, awards, end night, and history; repeat table, raise, setup, and history screens at accessibility text sizes with VoiceOver. For the owner’s iPhone checklist, follow Section 5: connect/unlock/trust the phone, enable Developer Mode, select it in Xcode, run, and trust the developer profile if prompted. `master` tracks `origin/main` and was pushed with the Phase 10 code at `996581c`; the planned `v1.0-game-night` tag has not been created because release tagging was not requested.
- 2026-11-25 documentation: `README.md` now presents the app, features, build/test commands, project layout, device-install steps, and embedded app icon on the GitHub landing page.
- Audit baseline commit: `9778796` — Fix: end-of-hand action bar and zero call
- Git note: after the 2026-11-25 push, local `master` tracks `origin/main`; verify the branch is clean and pushed before calling a release complete.

### Remaining-work summary

Work in this order; the detailed definitions of done are in Section 9.

1. **Correctness first (Phase 7):** implemented and committed; finish the manual flow checklist for pot display, live-pot shortcuts, end-night safety, and undo recorded in Section 9.
2. **Complete the table workflow (Phase 8):** implemented and committed; manually verify blinds, rebuy, add player, cash out, between-hand guards, and the prefilled checker.
3. **Verify setup and history (Phase 9):** implementation is committed and pushed. Finish the interactive start/resume, setup ordering/dealer, corruption recovery, end-review, and history deletion checklist recorded above, then sign off the open Phase 7–9 checkboxes.
4. **Finish release checks (Phase 10):** implementation, automated verification, and push are complete. Run the documented interactive Simulator and owner-device checks, then authorize the planned tag if desired before marking the release complete.

---

## 2. Rules for any AI working on this project

1. This file is the source of truth. Read all of it before starting. Do not silently diverge from it. If you must deviate, log it under **Deviations** in Section 1.
2. Work on ONE phase at a time. When the phase meets its Definition of Done, update Section 1, commit, summarize what you did and any assumptions, then stop and wait.
3. **Definition of Done for every phase:**
   - `swift test` passes inside `PokerCore/` (whenever PokerCore exists).
   - The app builds: `xcodebuild -project PokerNight.xcodeproj -scheme PokerNight -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` succeeds.
   - Section 1 of this file is updated (checkbox, current phase, deviations, facts).
   - A git commit is made with the message `Phase N: <short summary>`.
4. The Xcode project is generated by XcodeGen from `project.yml`. **Never edit `PokerNight.xcodeproj` by hand.** After adding, removing or moving any source file, run `xcodegen generate`.
5. Never change an expected value in a test to make it pass. The numbers in this spec are correct. Fix the code. If you believe the spec itself is wrong, stop and ask.
6. No third-party runtime dependencies. No networking. No analytics. (XcodeGen is a dev tool and is allowed.)
7. If a rule is ambiguous, ask instead of guessing.
8. Never run commands that need `sudo` or a password. Print the exact command and ask the owner to run it.
9. Keep files small and focused. Doc-comment every public PokerCore API.
10. If you are a chat assistant without access to the repo, ask the owner to paste the specific files you need rather than assuming their contents.

---

## 3. Product summary

An iPhone app that replaces poker chips for a group of friends who are new to poker. One phone, run by one person (the dealer), tracks everyone's points through No-Limit Texas Hold'em hands. Players announce actions out loud ("call", "raise to 40") and the dealer taps them in.

Three parts:

1. **Table.** A strict betting engine: stacks, blinds, turn order, legal bet sizes, all-ins, side pots, undo.
2. **Showdown checker.** A sheet that opens over the game at any time without changing it. The dealer taps in the board and two or more players' hole cards; the app names the winner and explains why in plain English. It is a side tool: it does not award pots.
3. **Hand rankings chart.** A static reference.

Plus a saved roster of players and a log of past nights.

### Decisions (and why)

| Decision | Choice | Reason |
|---|---|---|
| Scope | Full chip replacement | The group has no chips. |
| Devices | One shared phone, one operator | No backend, works offline, fast pace. Passing the phone per action is too slow. |
| Variant | No-Limit Hold'em only | It's what the group plays. |
| Rules | Strict engine, with undo | Nobody argues about the math, but mis-taps happen, so undo is mandatory. |
| Formats | One mode; rebuys are a toggle | No meaningful difference between "cash" and "tournament" for this group. |
| Money | Points only | No settlement, no currency. |
| Evaluator | Side tool only | The dealer picks pot winners manually; the checker helps them decide. |
| History | Roster + session log | No lifetime stats. |
| Teaching aids | Hand rankings chart only | Keep it lean. |
| Distribution | Free Apple account, installed from Xcode | The install expires every 7 days; re-run from Xcode before game night. |

### Out of scope

Tournaments, blind timers, payouts, antes, straddles, running it twice, multi-device sync, money settlement, Omaha or other variants, lifetime stats, teaching features beyond the rankings chart.

### Defaults (owner may override)

- Whole-number points only. Default starting stack 10, valid starting-stack range 10–10000, default blinds 1/2.
- Simple moving button (next seat with chips). No dead-button rule.
- Odd leftover points in a split pot go one at a time to winners in seat order starting left of the button.

---

## 4. Tech stack and repo layout

- iOS 17+, SwiftUI, Observation (`@Observable`), SwiftData.
- App target: Swift language mode 5 (avoids strict-concurrency churn in UI code).
- `PokerCore` local Swift package: `swift-tools-version: 6.0`, platforms `.iOS(.v17)` and `.macOS(.v14)` so `swift test` runs on the Mac. Tests use Swift Testing (`import Testing`). Public types are value types, `Sendable`, and `Codable` where saved.
- Xcode project generated by **XcodeGen** from `project.yml`.
- A recent Xcode (16 or newer) is required for Swift 6 tools and Swift Testing.

```
PokerNight/                      repo root
├── PLAN.md                      this file
├── project.yml                  XcodeGen spec (source of truth for the Xcode project)
├── .gitignore
├── PokerNight/                  app sources
│   ├── App/                     PokerNightApp.swift, root navigation
│   ├── Features/
│   │   ├── Home/
│   │   ├── Players/
│   │   ├── NightSetup/
│   │   ├── Table/
│   │   ├── Showdown/            ShowdownCheckerView, card picker
│   │   ├── Rankings/
│   │   └── History/
│   ├── Shared/                  CardView, styles, haptics
│   ├── Persistence/             SwiftData models, ActiveNightStore (JSON autosave)
│   └── Assets.xcassets          AppIcon, AccentColor
├── PokerCore/
│   ├── Package.swift
│   ├── Sources/PokerCore/
│   │   ├── Cards/
│   │   ├── Evaluator/
│   │   ├── Engine/
│   │   └── Session/
│   └── Tests/PokerCoreTests/
└── PokerNight.xcodeproj         GENERATED, gitignored, never hand-edited
```

### project.yml

```yaml
name: PokerNight
options:
  bundleIdPrefix: com.uzayer
  deploymentTarget:
    iOS: "17.0"
  createIntermediateGroups: true
packages:
  PokerCore:
    path: PokerCore
settings:
  base:
    CODE_SIGN_STYLE: Automatic
    DEVELOPMENT_TEAM: ""          # filled in during Phase 0 (see Section 5)
targets:
  PokerNight:
    type: application
    platform: iOS
    sources:
      - PokerNight
    dependencies:
      - package: PokerCore
    settings:
      base:
        PRODUCT_NAME: PokerNight
        PRODUCT_BUNDLE_IDENTIFIER: com.uzayer.pokernight
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        SWIFT_VERSION: "5.0"
        TARGETED_DEVICE_FAMILY: "1"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_CFBundleDisplayName: "Poker Night"
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: UIInterfaceOrientationPortrait
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
schemes:
  PokerNight:
    build:
      targets:
        PokerNight: all
    run:
      config: Debug
```

If the bundle ID is rejected as taken when signing, change it to `com.uzayer.pokernight2` (or similar) in `project.yml`, regenerate, and record it in Section 1.

### .gitignore

```
PokerNight.xcodeproj/
DerivedData/
.build/
.swiftpm/
xcuserdata/
*.xcuserstate
.DS_Store
```

---

## 5. Environment and signing (used by Phase 0)

1. **Check Xcode.** Run `xcodebuild -version`. If it fails or says command line tools are selected instead of Xcode, the owner must install Xcode from the Mac App Store, open it once (accept the license, let it install components including an iOS Simulator runtime), then run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` themselves. Record the Xcode version in Section 1.
2. **Check Homebrew.** Run `brew --version`. If missing, ask the owner to install it from https://brew.sh (needs their password).
3. **Install XcodeGen.** `brew install xcodegen`.
4. **Check git.** `git --version`.
5. **Find the Team ID.** A free Apple account has a "Personal Team" with its own Team ID. Try:
   `security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject`
   The `OU=` value in the subject is the Team ID. If nothing is found, stop and ask the owner to: open Xcode > Settings > Accounts, add their Apple ID, then open `PokerNight.xcodeproj`, select the PokerNight target > Signing & Capabilities, and choose their "(Personal Team)". That creates the certificate. Then retry the command. Write the Team ID into `project.yml` (`DEVELOPMENT_TEAM`) and Section 1, and run `xcodegen generate` again.

### Running on the iPhone (owner does this)

1. Connect the iPhone by cable and unlock it. Tap "Trust This Computer" if asked.
2. On the iPhone: Settings > Privacy & Security > Developer Mode > On (the phone restarts).
3. In Xcode, open `PokerNight.xcodeproj`, choose the iPhone as the run destination at the top, press Run (Cmd-R).
4. The first time, the iPhone blocks the app: Settings > General > VPN & Device Management > tap the developer profile > Trust.
5. **Every 7 days** the install expires. Re-run from Xcode (steps 1 and 3) the day before poker night. Installing over the top keeps data; deleting the app wipes the roster and history.
6. A free account allows at most 3 sideloaded apps per device.

---

## 6. Architecture

- **All poker logic lives in `PokerCore`**, with no UI imports, fully unit tested. The app target is a thin UI layer.
- **Each hand is an event log plus a reducer.** A hand is a `HandSetup` plus an ordered list of `HandEvent`s. The current `HandState` is computed by replaying every event from the setup. This must be deterministic.
  - **Undo** removes the last event and replays.
  - **Autosave** encodes the whole `TableSession` (which contains the current hand's setup and events) to JSON after every change.
- **Invariant**, asserted in debug after every mutation and in every engine/session test: the sum of all stacks + all chips committed in the current hand + all cashed-out stacks equals the sum of all buy-ins.
- The engine tracks **no cards**. The dealer deals physical cards. Cards only exist in the Showdown checker.

---

## 7. PokerCore spec

### 7.1 Cards (Phase 0)

- `Suit`: spades, hearts, diamonds, clubs. Display symbols ♠ ♥ ♦ ♣.
- `Rank`: two through ace, raw values 2...14. `Comparable`. Display: 2-9, 10, J, Q, K, A. Singular and plural names ("Six" / "Sixes", "Ace" / "Aces").
- `Card`: rank + suit. `Hashable`, `Codable`, `Sendable`.
- Parsing helpers (public, used by tests): `Card("As")`, `Card("Td")`, `Card("7c")` (ranks 2-9 T J Q K A, suits s h d c) and `Card.parse("Kh 7d 7c") -> [Card]`.
- `Deck.all`: all 52 cards.

### 7.2 Hand evaluator (Phase 1)

- `HandCategory`: highCard, pair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush. `Comparable`. Display names; an ace-high straight flush displays as "Royal Flush".
- `EvaluatedHand`: `category`, `tiebreakers: [Rank]`, `bestFive: [Card]`. `Comparable`: category first, then tiebreakers item by item. Tiebreaker layouts:
  - highCard: 5 ranks descending
  - pair: [pair, k1, k2, k3]
  - twoPair: [highPair, lowPair, kicker]
  - threeOfAKind: [trips, k1, k2]
  - straight and straightFlush: [highest card]. A-2-3-4-5 (the wheel) is a 5-high straight.
  - flush: 5 ranks descending
  - fullHouse: [trips, pair]
  - fourOfAKind: [quads, kicker]
- `bestHand(from: [Card]) -> EvaluatedHand` accepts 5, 6 or 7 cards, tries every 5-card combination and keeps the best. Suits never break ties.
- `Showdown.evaluate(board:players:)` where each player has an id, name and 2 hole cards. Returns players ranked best to worst, the winner(s) (ties allowed), an explanation string, and for each player which of their best five came from their hand vs the board. Flags `isIncompleteBoard` when the board has 3 or 4 cards ("if the hand ended now").
- Throws on: duplicate cards anywhere, board size outside 3...5, a player without exactly 2 hole cards, fewer than 2 players.

**Explanations** come from the first point of difference between the winner and the runner-up:

- Different category: "Flush beats Straight."
- Same category, main rank differs: "Both have a Full House. Kings full beats Sevens full." / "Both have a pair, but Kings beat Sevens."
- A kicker decides: "Both have Two Pair, Kings and Sevens. The next-best card decides it: Ace beats Queen."
- Tie where every tied player's best five equals the five board cards: "The board plays for everyone, so the pot splits."
- Any other tie: "Both have the same five-card hand (suits don't matter), so the pot splits."
- Plurals must be correct ("Sixes", not "Sixs").

**Required evaluator tests:**

1. Board `Kh 7d 7c 2s 9h`; A `Ks Qd`; B `Kd Ac`. B wins: two pair Kings and Sevens, Ace kicker beats Queen.
2. Board `As Ks Qs Js Ts`; any two players. Split, board plays, Royal Flush.
3. Board `9c 9d 5h 5s 2c`; A `Kh Kd` (Kings and Nines, Five kicker); B `Ah 3c` (Nines and Fives, Ace kicker). A wins on the top pair.
4. Board `Ah 2d 3c 9s Kd`; A `4h 5s` (5-high straight); B `Kh Ks` (three Kings). A wins: "Straight beats Three of a Kind."
5. The wheel loses to a 6-high straight.
6. Flush vs flush decided by the second-highest card.
7. Four of a kind on the board; the kicker decides.
8. Full house vs full house decided by the pair.
9. Three-way showdown with a two-way split for the win.
10. A board of 4 cards (6 cards per player) works and is flagged incomplete.
11. A duplicate card throws.

### 7.3 Betting engine (Phase 3)

```swift
public struct SeatSetup: Codable, Sendable { public let id: UUID; public var name: String; public var stack: Int }
public struct HandSetup: Codable, Sendable { public var seats: [SeatSetup]; public var buttonIndex: Int; public var smallBlind: Int; public var bigBlind: Int }

public enum PlayerAction: Codable, Sendable, Equatable {
    case fold, check, call
    case betOrRaise(to: Int)   // total for this betting round: "raise TO", never "raise BY"
    case allIn                 // engine resolves to short call, bet or raise
}

public enum HandEvent: Codable, Sendable, Equatable {
    case action(PlayerAction)                    // always applies to the current actor
    case award(potIndex: Int, winners: [UUID])
}

public struct LegalActions: Sendable {
    public let canFold: Bool
    public let canCheck: Bool
    public let callAmount: Int
    public let minRaiseTo: Int?   // nil if raising is not allowed
    public let maxRaiseTo: Int
}

public func legalActions(_ state: HandState) -> LegalActions
public func apply(_ event: HandEvent, to state: HandState) throws -> HandState
public func replay(_ setup: HandSetup, _ events: [HandEvent]) throws -> HandState
```

`HandState` exposes: street (preflop, flop, turn, river, showdown, complete); per seat: stack, committed this street, committed total, status (active, folded, allIn); current bet; last full raise size; current actor index; pots (once betting ends); whether the hand ended without a showdown. Illegal events throw descriptive errors.

**Rules:**

- Blinds post automatically at hand start. A player who can't cover a blind posts what they have and is all-in.
- Preflop: first to act is left of the big blind. If action just calls around, the big blind gets the option to check or raise.
- Postflop: first to act is the first non-folded, non-all-in player left of the button.
- **Heads-up** (exactly 2 players with chips): the button posts the small blind, acts first preflop and acts last on every later street.
- No-limit sizing: min raise-to = current bet + last full raise size. At the start of preflop the last full raise size is the big blind. Postflop with no bet yet, the minimum bet is the big blind. Max raise-to = the player's stack + what they've already committed this street.
- **Short all-in does not reopen betting.** An all-in raise smaller than a full raise does not reopen action for players who already acted since the last full raise: they may only call or fold. Players who have not yet acted may raise, with min raise-to = the all-in amount + the last full raise size.
- A player may call all-in for less than the call amount.
- A betting round ends when every non-folded, non-all-in player has acted since the last full raise and has matched the current bet (or at most one such player remains and they've matched). The street then advances automatically.
- If everyone but one player folds, that player wins everything immediately. The hand is complete; no showdown and no award events.
- If at most one player can still act once bets are matched, skip the remaining betting and go straight to showdown.
- Before building pots, return any uncalled portion of a bet to its owner.
- **Pot building** is a separate pure function: `buildPots(contributions: [UUID: Int], folded: Set<UUID>) -> (pots: [Pot], returned: [UUID: Int])`. Pots are layered by distinct all-in contribution levels. Folded players' chips stay in the pots, but those players are never eligible. `Pot` has `amount` and `eligible: [UUID]`.
- **Showdown:** the dealer awards each pot to one or more eligible winners via `.award` events. Split pots divide evenly; leftover points go one at a time to winners in seat order starting left of the button. When every pot is awarded, the hand is complete.

**Required engine tests** (blinds 5/10 unless stated; assert the invariant after every event in every test using a shared helper):

1. Everyone folds to the big blind: the BB wins the blinds, no showdown.
2. Everyone calls and the BB checks the option: the flop's first actor is left of the button.
3. Everyone calls and the BB raises the option: action reopens to the callers.
4. Min-raise math: facing the 10 big blind, a raise to 25 (increment 15) makes the next min raise-to 40.
5. Short all-in: postflop, A bets 100 and B goes all-in for 120. A may only call or fold (a raise throws). C, who had not acted, may raise with min raise-to 220.
6. `buildPots` with contributions 50 / 150 / 400, nobody folded: main pot 150 (all three eligible), side pot 200 (the two bigger stacks), 250 returned to the biggest.
7. `buildPots` where A put in 40 then folded and B and C put in 100 each: one pot of 240, eligible B and C.
8. Heads-up: the button posts the SB, acts first preflop and last on the flop.
9. A small blind with only 3 points posts 3, is all-in, and the hand still plays correctly.
10. A pot of 25 split between two winners: 13 to the first winner left of the button, 12 to the other.
11. Undo across a street change restores the previous street, actor and amounts exactly.
12. All-in preflop with one caller: the streets skip straight to showdown.
13. Codable round-trip of setup + events replays to an identical state.

### 7.4 Table session (Phase 4)

`TableSession` (Codable) manages a whole night across hands:

- Seats: id, name, stack, totalBuyIn, sittingOut, cashedOut (with final stack). Also blinds, buttonIndex, rebuysAllowed, handsPlayed, and the current hand (setup + events) if any.
- `startNextHand()`: moves the button to the next seat with chips, sits out seats with 0 chips, requires at least 2 players with chips. Handles the switch to heads-up when players bust.
- `apply(_ event:)` and `undo()` delegate to the current hand. Undo works only within the current hand, including undoing an award before the next hand starts.
- When a hand completes, final stacks are written back to the seats and handsPlayed increments.
- Between hands only (throws mid-hand): `setBlinds`, `addPlayer(name:buyIn:)`, `cashOut(seat:)` (records the final stack and removes them from play), `rebuy(seat:amount:)` (only if rebuysAllowed; adds to stack and totalBuyIn).
- `results()`: per player totalBuyIn, finalStack, net = finalStack − totalBuyIn.
- Invariant checked in debug after every mutation (Section 6).

**Required session tests:** button movement past busted players; the switch to heads-up when players bust; rebuy (allowed and disallowed); cash-out; mid-hand guard on between-hand operations; results; Codable round-trip mid-hand.

---

## 8. App spec

### 8.1 Shared

- `CardView`: rank + suit symbol, red for hearts and diamonds, used everywhere.
- Large, high-contrast type. The app intentionally uses its forced dark theme. Portrait iPhone only.
- Light haptic on each player action.

### 8.2 Showdown checker (Phase 2)

- `ShowdownCheckerView` is presented as a **sheet**, so it opens over the game without changing it. It takes an optional list of player names to prefill.
- Card picker: a 4 × 13 grid of tappable cards. Cards already used anywhere are greyed out and disabled.
- Slots for the board (3 to 5 cards) and for 2 or more players (add and remove players, editable names defaulting to "Player 1", "Player 2", each with 2 card slots). Tapping a filled slot clears it.
- Result panel: players ranked, each with their hand name and best five cards (hole cards visually marked vs board cards), a clear winner banner, the explanation sentence, and an "if the hand ended now" note when the board is incomplete. A Reset button.

### 8.3 Hand rankings (Phase 2)

- `HandRankingsView`: 10 rows from Royal Flush down to High Card, each with an example hand drawn as cards and a one-line definition.
- Footnote: "Same hand type? Compare the highest card, then the next, and so on. Suits never break ties. You only ever use your best five cards."
- Until Phase 6, a temporary Home screen has buttons to open the checker and the chart.

### 8.4 Table (Phase 5)

- `TableView` driven by an `@Observable` `GameController` that owns the `TableSession`.
- Header: big text "<Name> to act" with the call amount, and the current street. When a street just changed, show a banner such as "Deal the flop".
- Seat list in seat order: name, stack, bet this street, D / SB / BB badges, folded and all-in styling, the current actor highlighted.
- Pot display: main pot and any side pots.
- Action bar driven by `legalActions`: Fold, Check or Call <amount>, Bet/Raise. Bet/Raise opens a sheet with a stepper or slider limited to the legal range and quick buttons: Min, Half pot, Pot, All-in. **Undo** is always visible and disabled when there's nothing to undo.
- Award screen at showdown: one section per pot, tap one or more eligible winners, confirm. A "Check hands" button opens the Showdown checker prefilled with the names still in that pot.
- Toolbar: Showdown checker (sheet over the table at any time), Hand rankings, and a menu with Change blinds, Rebuy, Add player, Cash out player, End night. Between-hand items are disabled mid-hand.
- Autosave: after every change, encode the `TableSession` to `Application Support/active-night.json` (`ActiveNightStore`). On launch, if the file exists, Home offers "Resume night".
- Keep the screen awake while a night is running (`UIApplication.shared.isIdleTimerDisabled = true`) and restore it on exit.

### 8.5 Roster, setup, history (Phase 6)

- SwiftData models:
  - `Player`: id, name, createdAt
  - `Night`: id, date, smallBlind, bigBlind, startingStack, rebuysAllowed, handsPlayed, results
  - `NightResult`: player id, player name, totalBuyIn, finalStack, net
- **Home:** Resume night (only if an active file exists), New night, Past nights, Players, Hand rankings, Showdown checker.
- **Players:** add, rename, delete.
- **New night:** pick players from the roster or add new ones inline, drag to set seat order, starting stack (default 10, in 10-point increments), blinds (default 1/2), rebuys toggle, first dealer (pick or random).
- **End night:** each player's net sorted best to worst, saves a `Night`, deletes the active-night file.
- **Past nights:** list by date showing the top result; a detail view with every player's net.

### 8.0 Visual theme

- Use `PokerNight/Shared/Theme/Theme.swift` as the only source of app colors.
- Semantic tokens: plain black for background and surfaces, red for accent/suits/destructive actions, and white for text and icons.
- No additional palette colors: global tint is white, list panels are black, borders are white, and red is reserved for suit marks and destructive emphasis.
- Navigation titles use inline display mode to prevent them from overlapping screen content.
- Reusable styles: `.themedScreen()`, `.themedSheet()`, `.panel()`, and `ThemedButtonStyle(kind:)` with primary, strong, outline, destructive, and quiet kinds.
- The app is forced dark, uses rounded font design app-wide, and forces monospaced digits for stacks, bets, pots, and amounts.
- No raw hex values or hardcoded SwiftUI colors outside `Theme.swift`; use semantic Theme tokens for every app visual.

---

## 9. Phases

Each phase must meet the Definition of Done in Section 2.

### Phase 0: Environment, Xcode project, PokerCore, cards, git

1. Run the environment checks in Section 5 (steps 1 to 4). Stop and ask the owner for anything that needs their action.
2. `git init` at the repo root; add the `.gitignore` from Section 4.
3. Create `PokerCore/` per Section 4 with `Package.swift` (one library target `PokerCore`, one test target `PokerCoreTests`) and the Cards code from 7.1, plus tests for parsing and deck uniqueness (52 distinct cards).
4. Create the app sources: `PokerNight/App/PokerNightApp.swift` with a placeholder Home view titled "Poker Night" that imports `PokerCore` and shows a few sample `CardView`s (proving the package links). Create `PokerNight/Assets.xcassets` with valid `Contents.json` files for `AppIcon` (single-size iOS icon slot, no image yet) and `AccentColor`.
5. Write `project.yml` from Section 4 and run `xcodegen generate`.
6. Run `swift test` in `PokerCore/` and the simulator build command from Section 2. Fix until both pass.
7. Find the Team ID (Section 5, step 5), write it into `project.yml` and Section 1, regenerate, and rebuild.
8. Tell the owner how to run on their iPhone (Section 5, "Running on the iPhone").
9. Update Section 1 and commit.

### Phase 1: Evaluator and explanations
Implement 7.2 with all required tests.

### Phase 2: Showdown checker and rankings UI
Implement 8.1, 8.2 and 8.3, including the temporary Home screen.

### Phase 3: Betting engine
Implement 7.3 with all required tests. This is the hardest phase; build the rules incrementally, test by test.

### Phase 4: Table session
Implement 7.4 with all required tests.

### Phase 5: Table UI
Implement 8.4.

### Phase 6: Roster, setup, history
Implement 8.5 and replace the temporary Home screen.

### Phase 7: Gameplay correctness and safety

This phase is the next work to do. It fixes issues that can mislead the dealer or produce invalid night results. Do not begin Phase 8 until every item below is complete.

1. **Extract testable table-amount calculations.** Put pot-display and raise-shortcut calculations in small pure functions or a focused value type outside the SwiftUI view body so they can be unit tested. Keep actual poker-rule state in `PokerCore`; UI presentation helpers may remain in the app target.
2. **Fix pot display double counting.** During an active betting street, the displayed pot is the sum of all seats' `committedTotal`. At showdown/completion, where `state.pots` contains the built pots, display the sum of `state.pots` only. Never add both representations of the same points. Continue to show individual side-pot amounts.
3. **Fix Half Pot and Pot quick actions.** During betting, calculate the live pot from `committedTotal`, not `state.pots`. Use raise-to amounts:
   - Let `P` be the live pot before the actor acts, `C` the actor's legal call amount, and `A` the actor's amount already committed on this street.
   - Pot: target raise-to = `A + C + (P + C)`.
   - Half Pot: target raise-to = `A + C + floor((P + C) / 2)`.
   - Clamp each shortcut to the legal `minRaiseTo...maxRaiseTo` range. Min and All-in continue to map exactly to the legal bounds.
   - Add tests for unopened betting, facing a bet, non-round values, values below the minimum, and values above the player's maximum.
4. **Make end-night safe.** A night may end only when there is no current hand or the current hand is complete. Disable End Night during preflop, flop, turn, river, and showdown. The user must finish the hand or undo it to a safe state; current-hand committed points must never disappear from final results. Add a testable `canEndNight` decision and tests for every street.
5. **Restore Undo throughout a hand.** Undo must be visible during betting, showdown, and after the hand becomes complete, and disabled only when the current hand has no events. It must allow an award event to be undone before the next hand starts. Starting the next hand remains the boundary after which the prior hand cannot be undone.
6. **Add regression coverage.** Add an app unit-test target if needed through `project.yml`; never edit the generated Xcode project. Test the extracted calculations and safety decisions. Retain all existing PokerCore tests.
7. **Verify the complete flow manually in the Simulator:** normal hand ending by folds; checked-down showdown; all-in side pots; split pot with an odd point; undo during betting; undo of a pot award; next hand; and attempted end-night during an active hand.

**Phase 7 definition of done:** all amount/safety regression tests pass, all 34+ PokerCore tests pass, the simulator build succeeds without new warnings, manual flow verification is recorded under Project facts, Section 1 is updated, and the phase is committed as `Phase 7: Fix gameplay calculations and safety`.

### Phase 8: Between-hand table management and showdown integration

1. Add a between-hand management menu/sheet exposing the already implemented `TableSession` operations:
   - Change small and big blinds with validation that big blind is at least small blind.
   - Rebuy an eligible, non-cashed-out player when `rebuysAllowed` is true; choose a positive whole-number amount and show the resulting stack/total buy-in.
   - Add a player with a non-empty name and positive buy-in.
   - Cash out an active player after a destructive confirmation that shows their final stack.
2. Change blinds, Rebuy, Add player, and Cash out must be enabled only between hands. Give disabled controls a clear explanatory message rather than silently doing nothing.
3. Persist immediately after every successful management operation. Surface errors through the existing table alert rather than swallowing them.
4. Keep the table usable when management changes leave fewer than two players able to play: show a clear state and prevent Start Hand until at least two eligible players have chips.
5. Allow `ShowdownCheckerView` to accept optional initial player names while preserving the generic Player 1/Player 2 behavior when no names are supplied.
6. Add **Check hands** to each unawarded showdown pot. Open the checker with exactly that pot's eligible player names prefilled. The checker remains a side tool and must not award or mutate the table.
7. Add focused tests for new controller operations and their persistence calls where practical. Manually verify each management operation and the prefilled checker.

**Phase 8 definition of done:** every Section 8.4 toolbar and showdown-integration item works, operations are correctly restricted to between hands, autosave occurs after every mutation, tests/build pass, Section 1 is updated, and the phase is committed as `Phase 8: Complete table management`.

### Phase 9: Setup, navigation, end-night, and history completion

1. **Complete New Night setup:**
   - Add a player to the roster inline without leaving setup, then allow immediate selection.
   - Show selected players in explicit seat order and support drag-to-reorder.
   - Choose the first dealer from the selected seats or randomize it.
   - Preserve the default stack of 10, valid 10–10000 range, 10-point stepper, direct numeric entry, blinds, and rebuys toggle.
   - Validate names, duplicate roster entries, stack, blinds, at least two selected players, seat order, and dealer selection before creating the session.
2. **Fix navigation:** starting a new night must dismiss setup and navigate directly to its table. Resuming an autosaved night must load and navigate in one tap. Avoid a second Resume tap and avoid leaving a newly created night sitting on Home.
3. **Handle corrupt autosave visibly:** if an active-night file exists but cannot be decoded, show a recoverable error with options to cancel or delete only that corrupt active-night file. Never silently fail and never delete roster/history data.
4. **Add an end-night results review:** only from the safe state defined in Phase 7, show every player's name, total buy-in, final stack, and net sorted best to worst. Require explicit confirmation before saving and deleting the active-night file.
5. **Store the original starting stack correctly.** Do not derive `Night.startingStack` from a player's potentially rebought `totalBuyIn`; retain the configured starting stack as session/night metadata or otherwise store the exact original value.
6. **Complete history:** each Past Nights row shows date, hands, blinds, and the top result. Detail shows every player's total buy-in, final stack, and signed net sorted best to worst. Add deletion with destructive confirmation for an accidentally saved night.
7. Add tests for setup/session construction, navigation state decisions, original starting-stack persistence, result sorting, and corrupt-autosave handling. Manually verify fresh start, app relaunch/resume, and end/history flows.

**Phase 9 definition of done:** every Section 8.5 item works, start/resume are one-step flows, history contains accurate metadata/results, corruption is recoverable, tests/build pass, Section 1 is updated, and the phase is committed as `Phase 9: Complete night setup and history`.

### Phase 10: Persistence hardening, accessibility, assets, and release validation

1. **Stop silently discarding persistence errors.** Make active-night save/load/remove and final SwiftData save failures visible and recoverable. A failed save must not be followed by deleting the only recoverable active-night data. Use atomic writes and preserve the last valid save where feasible.
2. **Enforce point conservation in debug builds and tests.** After every `TableSession` mutation, debug-assert that total stacks + current-hand commitments + cashed-out stacks equals total buy-ins, accounting correctly for completed/awarded pots. Add the same invariant helper to every engine/session mutation test, including management operations and undo. Do not weaken expected values to satisfy the invariant.
3. Add app-level tests for `GameController`, autosave encoding/decoding, end-night persistence, and critical error paths. Keep SwiftUI views thin; extract state/decisions for testing rather than attempting to unit-test `View` values directly.
4. Perform an accessibility pass:
   - Verify VoiceOver names and traits for card slots, card picker, dealer/blind badges, seat state, pot winners, menus, and icon-only controls.
   - Verify Dynamic Type, including accessibility sizes, without clipped action controls or horizontally truncated critical values.
   - Do not rely on red/white color alone for player state or selection.
   - Retain high contrast and the intentional forced-dark theme.
5. Review compact/small iPhone layouts and long player names. Make the table, award controls, raise controls, setup ordering, and history usable without inaccessible horizontal overflow.
6. Add an original Poker Night app icon to `AppIcon.appiconset` with all assets required by the current Xcode asset format. Do not use copyrighted card art or third-party trademarks.
7. Complete a clean end-to-end Simulator playtest from empty install through roster creation, setup, multiple hands, management operations, autosave relaunch, showdown awards, end night, and history. Record the tested simulator/device and date in Project facts.
8. Give the owner the physical-iPhone checklist from Section 5. Physical-device signing/trust steps require the owner; record the result when available, but do not use `sudo` or ask for credentials.
9. Verify Git delivery: clean worktree, latest commits pushed to the intended remote, an upstream configured for the main branch, and a known-good tag such as `v1.0-game-night`. Do not push or create a tag unless the owner has authorized that external/repository action.
10. Reconcile this entire document against the final implementation. Remove completed remaining-work bullets, update facts and deviations, mark Phase 10 complete, and set Current phase to Complete only when no required item remains.

**Phase 10 definition of done:** persistence failures are handled safely, conservation assertions/tests are comprehensive, accessibility and layout checks pass, the app has a real icon, a clean full-flow simulator test is documented, owner-only device steps are clearly handed off, Git release state is verified or explicitly recorded as awaiting owner authorization, all tests/build pass, and the phase is committed as `Phase 10: Harden and validate release`.

---

## 10. Troubleshooting

- **"xcode-select: error: tool 'xcodebuild' requires Xcode"**: Xcode isn't selected. The owner runs `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.
- **No simulator destination / missing iOS platform**: in Xcode > Settings > Components, install the iOS platform.
- **New file not found by the compiler**: run `xcodegen generate`.
- **"Signing requires a development team"** on device: the Team ID isn't set in `project.yml`. See Section 5, step 5.
- **"Untrusted Developer"** on the iPhone: Settings > General > VPN & Device Management > Trust.
- **App won't open after a week**: the free provisioning profile expired. Re-run from Xcode. Data is kept unless the app was deleted.
- **Bundle ID unavailable**: change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`, regenerate, and record it in Section 1.
