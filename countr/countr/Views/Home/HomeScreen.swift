import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Counter.order) private var counters: [Counter]

    var body: some View {
        NavigationStack {
            Group {
                if counters.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "number.circle")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        Text("No counters yet")
                            .font(.headline)
                        Text("Tap + to create your first counter")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Counter list coming soon")
                }
            }
            .navigationTitle("countr")
        }
    }
}
