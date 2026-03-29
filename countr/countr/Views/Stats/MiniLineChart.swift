import SwiftUI
import Charts

struct MiniLineChart: View {
    let data: [StatsService.DayStat]
    let color: Color

    var body: some View {
        Chart(data) { stat in
            LineMark(
                x: .value("Day", stat.dayLabel),
                y: .value("Count", stat.total)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Day", stat.dayLabel),
                y: .value("Count", stat.total)
            )
            .foregroundStyle(color.opacity(0.1))
            .interpolationMethod(.catmullRom)

            if stat.total > 0 {
                PointMark(
                    x: .value("Day", stat.dayLabel),
                    y: .value("Count", stat.total)
                )
                .foregroundStyle(color)
                .symbolSize(20)
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 60)
    }
}
