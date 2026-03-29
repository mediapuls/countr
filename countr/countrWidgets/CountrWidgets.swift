import WidgetKit
import SwiftUI

// MARK: - Shared data reader

private func loadCounters() -> [WidgetCounterData] {
    guard let defaults = UserDefaults(suiteName: WidgetCounterData.suiteName),
          let data = defaults.data(forKey: WidgetCounterData.userDefaultsKey),
          let counters = try? JSONDecoder().decode([WidgetCounterData].self, from: data)
    else { return [] }
    return counters
}

// MARK: - Timeline entry

struct CountrEntry: TimelineEntry {
    let date: Date
    let counters: [WidgetCounterData]
}

// MARK: - Timeline provider

struct CountrProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountrEntry {
        CountrEntry(date: .now, counters: [
            WidgetCounterData(id: UUID(), name: "Steps", count: 4200, goal: 10000, colorName: "blue", resetMode: "daily"),
            WidgetCounterData(id: UUID(), name: "Water", count: 5, goal: 8, colorName: "cyan", resetMode: "daily"),
            WidgetCounterData(id: UUID(), name: "Workout", count: 12, goal: nil, colorName: "green", resetMode: "manual"),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (CountrEntry) -> Void) {
        completion(CountrEntry(date: .now, counters: loadCounters()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountrEntry>) -> Void) {
        let entry = CountrEntry(date: .now, counters: loadCounters())
        // Refresh at most once an hour; the main app reloads via WidgetCenter
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Color helper

private extension WidgetCounterData {
    var resolvedColor: Color {
        switch colorName {
        case "coral":   Color(red: 1.0, green: 0.45, blue: 0.40)
        case "orange":  .orange
        case "amber":   Color(red: 1.0, green: 0.75, blue: 0.0)
        case "yellow":  .yellow
        case "lime":    Color(red: 0.55, green: 0.82, blue: 0.15)
        case "green":   .green
        case "teal":    .teal
        case "cyan":    .cyan
        case "blue":    .blue
        case "indigo":  .indigo
        case "purple":  .purple
        case "pink":    .pink
        default:        .blue
        }
    }

    var progressFraction: Double? {
        guard let goal, goal > 0 else { return nil }
        return min(1.0, Double(count) / Double(goal))
    }
}

// MARK: - Progress ring shape

private struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Small widget  (single counter)

struct SmallWidgetView: View {
    let entry: CountrEntry

    var body: some View {
        let counter = entry.counters.first

        VStack(alignment: .leading, spacing: 6) {
            if let counter {
                HStack {
                    Text(counter.name)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(counter.resolvedColor)
                        .lineLimit(1)
                    Spacer()
                }

                Spacer()

                ZStack {
                    if let fraction = counter.progressFraction {
                        ProgressRing(progress: fraction, color: counter.resolvedColor, lineWidth: 8)
                    }
                    VStack(spacing: 0) {
                        Text("\(counter.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        if let goal = counter.goal {
                            Text("/ \(goal)")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer()

                Text(counter.resetMode == "manual" ? "Manual" : counter.resetMode.capitalized)
                    .font(.caption2).foregroundStyle(.secondary)
            } else {
                Text("No counters").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Medium widget  (up to 3 counters)

private struct MediumCounterCell: View {
    let counter: WidgetCounterData

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let fraction = counter.progressFraction {
                    ProgressRing(progress: fraction, color: counter.resolvedColor, lineWidth: 5)
                }
                Text("\(counter.count)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .frame(width: 54, height: 54)

            Text(counter.name)
                .font(.caption2).fontWeight(.medium)
                .foregroundStyle(counter.resolvedColor)
                .lineLimit(1)
        }
    }
}

struct MediumWidgetView: View {
    let entry: CountrEntry

    var body: some View {
        let shown = Array(entry.counters.prefix(3))

        HStack(spacing: 0) {
            if shown.isEmpty {
                Text("No counters").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            } else {
                ForEach(shown) { counter in
                    MediumCounterCell(counter: counter)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 12)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Lock screen: circular accessory

struct LockCircularView: View {
    let entry: CountrEntry

    var body: some View {
        let counter = entry.counters.first

        ZStack {
            if let fraction = counter?.progressFraction {
                ProgressRing(progress: fraction, color: .white, lineWidth: 4)
            }
            if let counter {
                Text("\(counter.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            } else {
                Image(systemName: "number")
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Lock screen: inline accessory

struct LockInlineView: View {
    let entry: CountrEntry

    var body: some View {
        if let counter = entry.counters.first {
            Label {
                Text("\(counter.name): \(counter.count)")
            } icon: {
                Image(systemName: "number.circle.fill")
            }
        } else {
            Text("countr")
        }
    }
}

// MARK: - Lock screen: rectangular accessory

struct LockRectangularView: View {
    let entry: CountrEntry

    var body: some View {
        let counter = entry.counters.first

        VStack(alignment: .leading, spacing: 4) {
            if let counter {
                Text(counter.name).font(.caption).fontWeight(.semibold).lineLimit(1)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(counter.count)").font(.system(size: 20, weight: .bold, design: .rounded))
                    if let goal = counter.goal {
                        Text("/ \(goal)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let fraction = counter.progressFraction {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.secondary.opacity(0.25)).frame(height: 4)
                            Capsule().fill(.white).frame(width: geo.size.width * fraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            } else {
                Text("countr").font(.caption).foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Widget definitions

struct CountrSmallWidget: Widget {
    let kind = "CountrSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountrProvider()) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Counter")
        .description("Shows your top counter with progress ring.")
        .supportedFamilies([.systemSmall])
    }
}

struct CountrMediumWidget: Widget {
    let kind = "CountrMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountrProvider()) { entry in
            MediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Counters")
        .description("Shows up to three counters side by side.")
        .supportedFamilies([.systemMedium])
    }
}

struct CountrLockWidget: Widget {
    let kind = "CountrLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountrProvider()) { entry in
            // View selected by WidgetFamily at runtime via @Environment
            CountrLockAdaptiveView(entry: entry)
        }
        .configurationDisplayName("countr (Lock Screen)")
        .description("Displays your top counter on the lock screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}

private struct CountrLockAdaptiveView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountrEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    LockCircularView(entry: entry)
        case .accessoryInline:      LockInlineView(entry: entry)
        case .accessoryRectangular: LockRectangularView(entry: entry)
        default:                    LockCircularView(entry: entry)
        }
    }
}
