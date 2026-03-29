import SwiftUI

struct DailyBreakdownRow: View {
    let date: String
    let value: Int
    let maxValue: Int

    private var barWidth: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value) / CGFloat(maxValue)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(date)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 45, alignment: .leading)
            GeometryReader { geo in
                Capsule()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: geo.size.width * barWidth)
            }
            .frame(height: 8)
            Text("\(value)")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 35, alignment: .trailing)
        }
        .frame(height: 24)
    }
}
