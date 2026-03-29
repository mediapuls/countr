import SwiftUI
import SwiftData
import Charts

struct ChartModal: View {
    let counter: Counter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var year: Int
    @State private var month: Int
    @State private var stats: StatsService.MonthStats?

    init(counter: Counter) {
        self.counter = counter
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        _year = State(initialValue: calendar.component(.year, from: now))
        _month = State(initialValue: calendar.component(.month, from: now))
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = Calendar(identifier: .iso8601).date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    private var isCurrentMonth: Bool {
        let calendar = Calendar(identifier: .iso8601)
        let now = Date()
        return year == calendar.component(.year, from: now) && month == calendar.component(.month, from: now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthNavigation
                    if let stats {
                        statsGrid(stats)
                        chart(stats)
                        dailyBreakdown(stats)
                    }
                }
                .padding()
            }
            .navigationTitle(counter.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { loadStats() }
        .onChange(of: year) { loadStats() }
        .onChange(of: month) { loadStats() }
    }

    private var monthNavigation: some View {
        HStack {
            Button { previousMonth() } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
            Spacer()
            Button { nextMonth() } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(isCurrentMonth)
        }
    }

    private func statsGrid(_ stats: StatsService.MonthStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statBox(title: "Total", value: "\(stats.total)")
            statBox(title: "Daily Avg", value: String(format: "%.1f", stats.dailyAvg))
            statBox(title: "Best Day", value: "\(stats.bestDay)")
            statBox(title: "Active Days", value: "\(stats.activeDays) / \(stats.totalDays)")
        }
    }

    private func statBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func chart(_ stats: StatsService.MonthStats) -> some View {
        Chart(stats.dailyData) { stat in
            LineMark(
                x: .value("Day", stat.dayLabel),
                y: .value("Count", stat.total)
            )
            .foregroundStyle(counter.color.color)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Day", stat.dayLabel),
                y: .value("Count", stat.total)
            )
            .foregroundStyle(counter.color.color.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: ["1", "7", "14", "21", "28"]) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .frame(height: 200)
    }

    private func dailyBreakdown(_ stats: StatsService.MonthStats) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Daily Breakdown")
                .font(.headline)
                .padding(.bottom, 4)
            let maxVal = stats.bestDay
            ForEach(stats.dailyData.filter { $0.total > 0 }) { stat in
                DailyBreakdownRow(date: stat.dayLabel, value: stat.total, maxValue: maxVal)
            }
        }
    }

    // MARK: - Navigation

    private func previousMonth() {
        if month == 1 {
            month = 12
            year -= 1
        } else {
            month -= 1
        }
    }

    private func nextMonth() {
        guard !isCurrentMonth else { return }
        if month == 12 {
            month = 1
            year += 1
        } else {
            month += 1
        }
    }

    // MARK: - Data

    private func loadStats() {
        let counterId = counter.id
        let descriptor = FetchDescriptor<DailyHistory>(
            predicate: #Predicate { $0.counterId == counterId },
            sortBy: [SortDescriptor(\.date)]
        )
        let history = (try? modelContext.fetch(descriptor)) ?? []
        stats = StatsService.monthStats(counterId: counterId, history: history, year: year, month: month)
    }
}
