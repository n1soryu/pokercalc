import Foundation

/// Builds layered pots from total contributions.
public func buildPots(
    contributions: [UUID: Int],
    folded: Set<UUID>
) -> (pots: [Pot], returned: [UUID: Int]) {
    var returned: [UUID: Int] = [:]
    var adjusted = contributions.filter { $0.value > 0 }
    if let maximum = adjusted.values.max(), maximum > 0 {
        let highest = contributions.filter { $0.value == maximum }
        let otherLevels = contributions.values.filter { $0 < maximum }
        let secondHighest = otherLevels.max() ?? 0
        if highest.count == 1, maximum > secondHighest {
            let id = highest.keys.first!
            returned[id] = maximum - secondHighest
            adjusted[id] = secondHighest
        }
    }

    var pots: [Pot] = []
    let levels = Set(adjusted.values).sorted()
    var previousLevel = 0
    for level in levels {
        let participants = adjusted.filter { $0.value >= level }.map(\.key)
        let amount = (level - previousLevel) * participants.count
        let eligible = participants.filter { !folded.contains($0) }.sorted { $0.uuidString < $1.uuidString }
        if amount > 0 {
            let pot = Pot(amount: amount, eligible: eligible)
            if pots.last?.eligible == pot.eligible {
                let last = pots.removeLast()
                pots.append(Pot(amount: last.amount + pot.amount, eligible: pot.eligible))
            } else {
                pots.append(pot)
            }
        }
        previousLevel = level
    }
    return (pots, returned)
}
