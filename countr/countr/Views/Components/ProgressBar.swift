import SwiftUI

struct ProgressBar: View {
    let value: Int
    let goal: Int
    let color: Color

    private var progress: CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(value) / CGFloat(goal), 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.2))
                Capsule().fill(color)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
        .accessibilityValue("\(value) of \(goal)")
    }
}
