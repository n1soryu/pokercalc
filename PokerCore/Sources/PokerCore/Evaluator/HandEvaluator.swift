/// Evaluates the best five-card poker hand from five, six, or seven cards.
public func bestHand(from cards: [Card]) -> EvaluatedHand {
    precondition((5...7).contains(cards.count), "bestHand requires 5, 6, or 7 cards")
    precondition(Set(cards).count == cards.count, "Cards must be unique")

    var best: EvaluatedHand?
    for combination in combinations(of: cards, choosing: 5) {
        let candidate = evaluateFive(combination)
        if best == nil || best! < candidate {
            best = candidate
        }
    }
    return best!
}

private func combinations(of cards: [Card], choosing count: Int) -> [[Card]] {
    guard count > 0 else { return [[]] }
    guard cards.count >= count else { return [] }

    var result: [[Card]] = []
    for index in 0...(cards.count - count) {
        let head = cards[index]
        let tail = Array(cards[(index + 1)...])
        for suffix in combinations(of: tail, choosing: count - 1) {
            result.append([head] + suffix)
        }
    }
    return result
}

private func evaluateFive(_ cards: [Card]) -> EvaluatedHand {
    let ranks = cards.map(\.rank)
    let counts = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count)
    let groups = counts.sorted {
        if $0.value != $1.value { return $0.value > $1.value }
        return $0.key > $1.key
    }
    let flush = Set(cards.map(\.suit)).count == 1
    let straightHigh = straightHighRank(ranks)

    if let straightHigh, flush {
        return EvaluatedHand(category: .straightFlush, tiebreakers: [straightHigh], bestFive: orderedStraight(cards, high: straightHigh))
    }
    if groups[0].value == 4 {
        let quad = groups[0].key
        let kicker = groups[1].key
        return EvaluatedHand(category: .fourOfAKind, tiebreakers: [quad, kicker], bestFive: ordered(cards, ranks: [quad, quad, quad, quad, kicker]))
    }
    if groups[0].value == 3, groups[1].value == 2 {
        return EvaluatedHand(category: .fullHouse, tiebreakers: [groups[0].key, groups[1].key], bestFive: ordered(cards, ranks: [groups[0].key, groups[0].key, groups[0].key, groups[1].key, groups[1].key]))
    }
    if flush {
        let sortedRanks = ranks.sorted(by: >)
        return EvaluatedHand(category: .flush, tiebreakers: sortedRanks, bestFive: cards.sorted { $0.rank > $1.rank })
    }
    if let straightHigh {
        return EvaluatedHand(category: .straight, tiebreakers: [straightHigh], bestFive: orderedStraight(cards, high: straightHigh))
    }
    if groups[0].value == 3 {
        let trips = groups[0].key
        let kickers = groups.dropFirst().map(\.key).sorted(by: >)
        return EvaluatedHand(category: .threeOfAKind, tiebreakers: [trips] + kickers, bestFive: ordered(cards, ranks: [trips, trips, trips] + kickers))
    }
    if groups[0].value == 2, groups[1].value == 2 {
        let pairs = [groups[0].key, groups[1].key].sorted(by: >)
        let kicker = groups[2].key
        return EvaluatedHand(category: .twoPair, tiebreakers: pairs + [kicker], bestFive: ordered(cards, ranks: [pairs[0], pairs[0], pairs[1], pairs[1], kicker]))
    }
    if groups[0].value == 2 {
        let pair = groups[0].key
        let kickers = groups.dropFirst().map(\.key).sorted(by: >)
        return EvaluatedHand(category: .pair, tiebreakers: [pair] + kickers, bestFive: ordered(cards, ranks: [pair, pair] + kickers))
    }

    let sortedRanks = ranks.sorted(by: >)
    return EvaluatedHand(category: .highCard, tiebreakers: sortedRanks, bestFive: cards.sorted { $0.rank > $1.rank })
}

private func straightHighRank(_ ranks: [Rank]) -> Rank? {
    let unique = Set(ranks)
    if unique.count != 5 { return nil }
    let values = unique.map(\.rawValue).sorted()
    if values == [2, 3, 4, 5, 14] { return .five }
    guard let first = values.first, values == Array(first...(first + 4)) else { return nil }
    return Rank(rawValue: first + 4)
}

private func orderedStraight(_ cards: [Card], high: Rank) -> [Card] {
    let wanted: [Rank] = high == .five ? [.five, .four, .three, .two, .ace] : (0..<5).map { Rank(rawValue: high.rawValue - $0)! }
    return ordered(cards, ranks: wanted)
}

private func ordered(_ cards: [Card], ranks: [Rank]) -> [Card] {
    var remaining = cards
    return ranks.compactMap { rank in
        guard let index = remaining.firstIndex(where: { $0.rank == rank }) else { return nil }
        return remaining.remove(at: index)
    }
}
