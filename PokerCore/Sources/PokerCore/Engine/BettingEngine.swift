import Foundation

/// Replays hand events into a deterministic state.
public func replay(_ setup: HandSetup, _ events: [HandEvent]) throws -> HandState {
    var state = try initialState(setup)
    for event in events {
        state = try apply(event, to: state)
    }
    return state
}

/// Returns the legal actions for the current actor.
public func legalActions(_ state: HandState) -> LegalActions {
    guard let actorIndex = state.currentActorIndex,
          state.street != .showdown,
          state.street != .complete else {
        return LegalActions(canFold: false, canCheck: false, callAmount: 0, minRaiseTo: nil, maxRaiseTo: 0)
    }
    let actor = state.seats[actorIndex]
    let callAmount = max(0, min(state.currentBet - actor.committedThisStreet, actor.stack))
    let maxRaiseTo = actor.committedThisStreet + actor.stack
    let minRaiseTo: Int?
    if state.actedSinceRaise.contains(actor.id) || maxRaiseTo <= state.currentBet {
        minRaiseTo = nil
    } else {
        let minimum = state.currentBet == 0 ? state.setup.bigBlind : state.currentBet + state.lastFullRaiseSize
        minRaiseTo = minimum <= maxRaiseTo ? minimum : nil
    }
    return LegalActions(
        canFold: true,
        canCheck: callAmount == 0,
        callAmount: callAmount,
        minRaiseTo: minRaiseTo,
        maxRaiseTo: maxRaiseTo
    )
}

/// Applies one event to a hand state.
public func apply(_ event: HandEvent, to original: HandState) throws -> HandState {
    var state = original
    switch event {
    case let .action(action):
        try apply(action, to: &state)
    case let .award(potIndex, winners):
        try award(potIndex: potIndex, winners: winners, in: &state)
    }
    return state
}

/// Errors raised by illegal betting events.
public enum BettingError: Error, Equatable, Sendable {
    case invalidSetup
    case handIsOver
    case noCurrentActor
    case illegalAction
    case checkNotAllowed
    case callNotAllowed
    case raiseNotAllowed
    case invalidRaiseAmount
    case invalidPotAward
}

private func initialState(_ setup: HandSetup) throws -> HandState {
    guard setup.seats.count >= 2,
          setup.seats.indices.contains(setup.buttonIndex),
          setup.smallBlind > 0,
          setup.bigBlind >= setup.smallBlind,
          setup.seats.filter({ $0.stack > 0 }).count >= 2 else {
        throw BettingError.invalidSetup
    }

    var seats = setup.seats.map {
        SeatState(id: $0.id, name: $0.name, stack: max(0, $0.stack), committedThisStreet: 0, committedTotal: 0, status: $0.stack > 0 ? .active : .folded)
    }
    let active = activeIndices(seats)
    let headsUp = active.count == 2
    let smallBlindIndex = headsUp ? setup.buttonIndex : nextActive(from: setup.buttonIndex, seats: seats)
    let bigBlindIndex = nextActive(from: smallBlindIndex, seats: seats)
    postBlind(setup.smallBlind, at: smallBlindIndex, seats: &seats)
    postBlind(setup.bigBlind, at: bigBlindIndex, seats: &seats)
    let actor = headsUp && seats[smallBlindIndex].status == .active
        ? smallBlindIndex
        : nextActor(from: bigBlindIndex, seats: seats)
    return HandState(
        setup: setup,
        seats: seats,
        street: .preflop,
        currentBet: seats.map(\.committedThisStreet).max() ?? 0,
        lastFullRaiseSize: setup.bigBlind,
        currentActorIndex: actor,
        pots: [],
        handEndedWithoutShowdown: false,
        actedSinceRaise: [],
        awardedPotIndices: []
    )
}

private func apply(_ action: PlayerAction, to state: inout HandState) throws {
    guard state.street != .complete, state.street != .showdown else { throw BettingError.handIsOver }
    guard let actorIndex = state.currentActorIndex else { throw BettingError.noCurrentActor }
    guard state.seats[actorIndex].status == .active else { throw BettingError.noCurrentActor }

    let actorID = state.seats[actorIndex].id
    let available = legalActions(state)
    switch action {
    case .fold:
        state.seats[actorIndex].status = .folded
        state.actedSinceRaise.insert(actorID)
    case .check:
        guard available.canCheck else { throw BettingError.checkNotAllowed }
        state.actedSinceRaise.insert(actorID)
    case .call:
        guard available.callAmount > 0 else { throw BettingError.callNotAllowed }
        commit(min(available.callAmount, state.seats[actorIndex].stack), at: actorIndex, state: &state)
        state.actedSinceRaise.insert(actorID)
    case let .betOrRaise(to):
        guard let minimum = available.minRaiseTo else { throw BettingError.raiseNotAllowed }
        guard to >= minimum, to <= available.maxRaiseTo, to > state.currentBet else { throw BettingError.invalidRaiseAmount }
        let increment = to - state.currentBet
        commit(to - state.seats[actorIndex].committedThisStreet, at: actorIndex, state: &state)
        state.currentBet = to
        state.lastFullRaiseSize = increment
        state.actedSinceRaise = [actorID]
    case .allIn:
        let target = available.maxRaiseTo
        if target <= state.currentBet {
            commit(min(available.callAmount, state.seats[actorIndex].stack), at: actorIndex, state: &state)
            state.actedSinceRaise.insert(actorID)
        } else {
            guard !state.actedSinceRaise.contains(actorID) else { throw BettingError.raiseNotAllowed }
            let increment = target - state.currentBet
            commit(target - state.seats[actorIndex].committedThisStreet, at: actorIndex, state: &state)
            state.currentBet = target
            state.seats[actorIndex].status = .allIn
            if increment >= state.lastFullRaiseSize {
                state.lastFullRaiseSize = increment
                state.actedSinceRaise = [actorID]
            } else {
                state.actedSinceRaise.insert(actorID)
            }
        }
    }

    if state.seats.filter({ $0.status != .folded }).count == 1 {
        finishByFold(&state)
        return
    }
    advanceAfterAction(&state)
}

private func advanceAfterAction(_ state: inout HandState) {
    let canAct = state.seats.filter { $0.status == .active }
    let matched = canAct.allSatisfy { $0.committedThisStreet == state.currentBet && state.actedSinceRaise.contains($0.id) }
    if matched {
        advanceStreetOrShowdown(&state)
    } else {
        state.currentActorIndex = nextActor(from: state.currentActorIndex ?? state.setup.buttonIndex, seats: state.seats)
    }
}

private func advanceStreetOrShowdown(_ state: inout HandState) {
    let canAct = state.seats.filter { $0.status == .active }
    if canAct.count <= 1 || state.seats.filter({ $0.status != .folded }).allSatisfy({ $0.status == .allIn }) {
        prepareShowdown(&state)
        return
    }
    switch state.street {
    case .preflop: state.street = .flop
    case .flop: state.street = .turn
    case .turn: state.street = .river
    case .river:
        prepareShowdown(&state)
        return
    case .showdown, .complete: return
    }
    for index in state.seats.indices {
        state.seats[index].committedThisStreet = 0
    }
    state.currentBet = 0
    state.lastFullRaiseSize = state.setup.bigBlind
    state.actedSinceRaise = []
    state.currentActorIndex = firstPostflopActor(state)
}

private func prepareShowdown(_ state: inout HandState) {
    returnUncalledAndBuildPots(state: &state)
    state.street = .showdown
    state.currentActorIndex = nil
}

private func finishByFold(_ state: inout HandState) {
    returnUncalledAndBuildPots(state: &state)
    state.handEndedWithoutShowdown = true
    state.street = .complete
    state.currentActorIndex = nil
    if let winner = state.seats.firstIndex(where: { $0.status != .folded }) {
        state.seats[winner].stack += state.pots.reduce(0) { $0 + $1.amount }
        state.pots = []
    }
}

private func award(potIndex: Int, winners: [UUID], in state: inout HandState) throws {
    guard state.street == .showdown,
          state.pots.indices.contains(potIndex),
          !winners.isEmpty,
          !state.awardedPotIndices.contains(potIndex),
          winners.allSatisfy({ state.pots[potIndex].eligible.contains($0) }) else {
        throw BettingError.invalidPotAward
    }
    let pot = state.pots[potIndex]
    let share = pot.amount / winners.count
    var remainder = pot.amount % winners.count
    let order = seatOrderStartingLeftOfButton(state)
    for id in winners.sorted(by: { (order[$0] ?? 0) < (order[$1] ?? 0) }) {
        guard let index = state.seats.firstIndex(where: { $0.id == id }) else { continue }
        state.seats[index].stack += share
        if remainder > 0 {
            state.seats[index].stack += 1
            remainder -= 1
        }
    }
    state.awardedPotIndices.insert(potIndex)
    if state.awardedPotIndices.count == state.pots.count {
        state.street = .complete
    }
}

private func returnUncalledAndBuildPots(state: inout HandState) {
    let contributions = Dictionary(uniqueKeysWithValues: state.seats.map { ($0.id, $0.committedTotal) })
    let folded = Set(state.seats.filter { $0.status == .folded }.map(\.id))
    let built = buildPots(contributions: contributions, folded: folded)
    for (id, amount) in built.returned {
        guard let index = state.seats.firstIndex(where: { $0.id == id }) else { continue }
        state.seats[index].stack += amount
        state.seats[index].committedTotal -= amount
    }
    let adjusted = Dictionary(uniqueKeysWithValues: state.seats.map { ($0.id, $0.committedTotal) })
    let finalPots = buildPots(contributions: adjusted, folded: folded).pots
    state.pots = finalPots
}

private func commit(_ amount: Int, at index: Int, state: inout HandState) {
    guard amount > 0 else { return }
    state.seats[index].stack -= amount
    state.seats[index].committedThisStreet += amount
    state.seats[index].committedTotal += amount
    if state.seats[index].stack == 0 {
        state.seats[index].status = .allIn
    }
}

private func postBlind(_ amount: Int, at index: Int, seats: inout [SeatState]) {
    let posted = min(amount, seats[index].stack)
    seats[index].stack -= posted
    seats[index].committedThisStreet = posted
    seats[index].committedTotal = posted
    if seats[index].stack == 0 { seats[index].status = .allIn }
}

private func activeIndices(_ seats: [SeatState]) -> [Int] {
    seats.indices.filter { seats[$0].status != .folded && seats[$0].stack + seats[$0].committedTotal > 0 }
}

private func nextActive(from index: Int, seats: [SeatState]) -> Int {
    for offset in 1...seats.count {
        let candidate = (index + offset) % seats.count
        if seats[candidate].status != .folded { return candidate }
    }
    return index
}

private func nextActor(from index: Int, seats: [SeatState]) -> Int {
    for offset in 1...seats.count {
        let candidate = (index + offset) % seats.count
        if seats[candidate].status == .active { return candidate }
    }
    return index
}

private func firstPostflopActor(_ state: HandState) -> Int? {
    guard let button = state.seats.indices.first(where: { $0 == state.setup.buttonIndex }) else { return nil }
    for offset in 1...state.seats.count {
        let index = (button + offset) % state.seats.count
        if state.seats[index].status == .active { return index }
    }
    return nil
}

private func seatOrderStartingLeftOfButton(_ state: HandState) -> [UUID: Int] {
    var order: [UUID: Int] = [:]
    for offset in 1...state.seats.count {
        let index = (state.setup.buttonIndex + offset) % state.seats.count
        order[state.seats[index].id] = offset
    }
    return order
}
