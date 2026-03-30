import ActivityKit
import SwiftUI
import WidgetKit

// Re-declare attributes for the extension target
struct CountrActivityAttributes: ActivityAttributes {
    let counterName: String
    let goal: Int?
    let colorName: String
    struct ContentState: Codable, Hashable {
        let count: Int
    }
}

struct CountrLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountrActivityAttributes.self) { context in
            // Lock screen / StandBy banner
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.counterName)
                        .font(.headline)
                    if let goal = context.attributes.goal {
                        Text("\(context.state.count) / \(goal)")
                            .font(.title)
                            .fontWeight(.bold)
                    } else {
                        Text("\(context.state.count)")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                Spacer()
                if let goal = context.attributes.goal {
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 4)
                            .opacity(0.2)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(context.state.count) / CGFloat(goal), 1.0))
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 44, height: 44)
                }
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.counterName)
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let goal = context.attributes.goal {
                        Text("\(context.state.count)/\(goal)")
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("\(context.state.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let goal = context.attributes.goal {
                        ProgressView(value: min(Double(context.state.count) / Double(goal), 1.0))
                            .tint(.blue)
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text(context.attributes.counterName)
                        .font(.caption)
                        .lineLimit(1)
                }
            } compactTrailing: {
                Text("\(context.state.count)")
                    .font(.caption)
                    .fontWeight(.bold)
            } minimal: {
                Text("\(context.state.count)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
        }
    }
}
