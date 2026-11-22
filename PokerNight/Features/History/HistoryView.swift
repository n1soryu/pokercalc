import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: \Night.date, order: .reverse) private var nights: [Night]

    var body: some View {
        List(nights) { night in
            NavigationLink {
                NightDetailView(night: night)
            } label: {
                VStack(alignment: .leading) {
                    Text(night.date, format: .dateTime.year().month().day())
                    Text("\(night.handsPlayed) hands · Blinds \(night.smallBlind)/\(night.bigBlind)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay {
            if nights.isEmpty { ContentUnavailableView("No past nights", systemImage: "clock") }
        }
        .navigationTitle("Past Nights")
    }
}

private struct NightDetailView: View {
    let night: Night

    var results: [StoredNightResult] {
        (try? JSONDecoder().decode([StoredNightResult].self, from: night.resultsData)) ?? []
    }

    var body: some View {
        List(results.sorted { $0.net > $1.net }) { result in
            HStack {
                Text(result.name)
                Spacer()
                Text(result.net >= 0 ? "+\(result.net)" : "\(result.net)")
                    .foregroundStyle(result.net >= 0 ? .green : .red)
            }
        }
        .navigationTitle("Night Details")
    }
}
