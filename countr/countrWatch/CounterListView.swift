import SwiftUI

struct CounterListView: View {
    @Environment(WatchDataService.self) var dataService

    var body: some View {
        NavigationStack {
            List(dataService.counters, id: \.id) { counter in
                NavigationLink(value: counter) {
                    HStack {
                        Circle()
                            .fill(colorFor(counter.colorName))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading) {
                            Text(counter.name)
                                .font(.headline)
                            if let goal = counter.goal {
                                Text("\(counter.count) / \(goal)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(counter.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let goal = counter.goal {
                            CircularProgressView(value: counter.count, goal: goal, color: colorFor(counter.colorName))
                                .frame(width: 30, height: 30)
                        }
                    }
                }
            }
            .navigationTitle("countr")
            .navigationDestination(for: WidgetCounterData.self) { counter in
                CounterDetailView(counter: counter)
            }
        }
    }

    func colorFor(_ name: String) -> Color {
        switch name {
        case "coral": return Color(red: 1.0, green: 0.45, blue: 0.40)
        case "orange": return .orange
        case "amber": return Color(red: 1.0, green: 0.75, blue: 0.0)
        case "yellow": return .yellow
        case "lime": return Color(red: 0.55, green: 0.82, blue: 0.15)
        case "green": return .green
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}
