import SwiftUI
import SwiftData

struct StatsCounterCard: View {
    let counter: Counter
    let weekData: [StatsService.DayStat]
    let streak: Int
    let goalHits: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(counter.name)
                        .font(.headline)
                    Spacer()
                    if counter.resetMode != .manual {
                        Text(counter.resetMode.label)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(counter.color.color.opacity(0.15))
                            .foregroundStyle(counter.color.color)
                            .clipShape(Capsule())
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    Text("\(counter.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    if let goal = counter.goal {
                        Text("/ \(goal)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if streak >= 2 {
                        HStack(spacing: 2) {
                            Text("\u{1F525}")
                                .font(.caption)
                            Text("\(streak)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }

                if counter.resetMode != .manual && !weekData.isEmpty {
                    MiniLineChart(data: weekData, color: counter.color.color)
                }

                if let goal = counter.goal, goalHits > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Goal hit \(goalHits) time\(goalHits == 1 ? "" : "s") this month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(counter.color.color)
                    .frame(width: 4)
            }
        }
        .buttonStyle(.plain)
    }
}
