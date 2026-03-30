import SwiftUI

struct CounterDetailView: View {
    let counter: WidgetCounterData

    var body: some View {
        VStack(spacing: 16) {
            Text(counter.name)
                .font(.headline)

            if let goal = counter.goal {
                CircularProgressView(value: counter.count, goal: goal, color: .blue)
                    .frame(width: 80, height: 80)
            }

            Text("\(counter.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))

            if let goal = counter.goal {
                Text("/ \(goal)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                Button {
                    // Decrement — will work with CloudKit sync
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                Button {
                    // Increment — will work with CloudKit sync
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
    }
}

struct CircularProgressView: View {
    let value: Int
    let goal: Int
    let color: Color

    private var progress: CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(value) / CGFloat(goal), 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
