import SwiftUI

struct NightResultRow: View {
    let result: StoredNightResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.name).font(.headline)
            LabeledContent("Total buy-in", value: "\(result.totalBuyIn)")
            LabeledContent("Final stack", value: "\(result.finalStack)")
            LabeledContent("Net") {
                Text(result.signedNet)
                    .foregroundStyle(result.net < 0 ? Theme.suitRed : Theme.textPrimary)
            }
        }
        .monospacedDigit()
        .padding(.vertical, 4)
    }
}

extension StoredNightResult {
    var signedNet: String { net >= 0 ? "+\(net)" : "\(net)" }
}
