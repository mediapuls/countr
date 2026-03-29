# Stats & Charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Stats tab with summary cards, per-counter stats cards with mini line charts, trend indicators, milestone badges, and a full chart modal with month navigation and daily breakdown.

**Architecture:** Uses SwiftUI Charts framework for all chart rendering. Stats screen reads from SwiftData (Counter + DailyHistory). Chart modal presents as fullScreenCover with month navigation. All calculations are pure functions for testability.

**Tech Stack:** Swift, SwiftUI, SwiftUI Charts, SwiftData

**Spec:** `docs/superpowers/specs/2026-03-29-countr-native-swift-design.md`

---

## File Structure

```
countr/countr/Views/Stats/
├── StatsScreen.swift              ← create: stats tab with summary + per-counter cards
├── SummaryCard.swift              ← create: total counters / logged today / best streak cards
├── StatsCounterCard.swift         ← create: per-counter card with mini chart + milestone
├── MiniLineChart.swift            ← create: small week chart using SwiftUI Charts
├── ChartModal.swift               ← create: full-screen month chart with navigation
└── DailyBreakdownRow.swift        ← create: single row in daily breakdown list

countr/countr/Services/
└── StatsService.swift             ← create: pure calculation functions for stats

countr/countrTests/
└── StatsServiceTests.swift        ← create: tests for stats calculations
```

---

### Task 1: Stats Service

**Files:**
- Create: `countr/countr/Services/StatsService.swift`
- Create: `countr/countrTests/StatsServiceTests.swift`

- [ ] **Step 1: Create StatsService with pure calculation functions**

```swift
// countr/countr/Services/StatsService.swift
import Foundation

enum StatsService {

    struct DayStat: Identifiable {
        let id = UUID()
        let date: String
        let dayLabel: String
        let total: Int
    }

    struct MonthStats {
        let total: Int
        let dailyAvg: Double
        let bestDay: Int
        let activeDays: Int
        let totalDays: Int
        let dailyData: [DayStat]
    }

    // MARK: - Summary calculations

    static func totalLoggedToday(counters: [Counter]) -> Int {
        counters.reduce(0) { $0 + $1.count }
    }

    static func bestStreak(counters: [Counter], allHistory: [UUID: [DailyHistory]]) -> Int {
        let today = Counter.todayString()
        var best = 0
        for counter in counters {
            let history = allHistory[counter.id] ?? []
            let streak = StreakService.calculateStreak(
                mode: counter.resetMode,
                history: history,
                currentDate: today,
                currentCount: counter.count
            )
            best = max(best, streak)
        }
        return best
    }

    static func trendPercentage(counters: [Counter], allHistory: [UUID: [DailyHistory]]) -> Double? {
        let calendar = Calendar(identifier: .iso8601)
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        // This week's total (Mon-today)
        guard let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return nil }
        let thisWeekDates = datesInRange(from: thisWeekStart, to: today, formatter: formatter)

        // Last week's total (same number of days)
        guard let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart),
              let lastWeekEnd = calendar.date(byAdding: .day, value: thisWeekDates.count - 1, to: lastWeekStart) else { return nil }
        let lastWeekDates = datesInRange(from: lastWeekStart, to: lastWeekEnd, formatter: formatter)

        var thisWeekTotal = 0
        var lastWeekTotal = 0

        for counter in counters {
            let history = allHistory[counter.id] ?? []
            let historyMap = Dictionary(grouping: history, by: { $0.date }).mapValues { $0.first?.total ?? 0 }

            for date in thisWeekDates {
                thisWeekTotal += historyMap[date] ?? 0
            }
            // Add today's live count
            let todayStr = formatter.string(from: today)
            if thisWeekDates.contains(todayStr) {
                thisWeekTotal += counter.count - (historyMap[todayStr] ?? 0)
            }

            for date in lastWeekDates {
                lastWeekTotal += historyMap[date] ?? 0
            }
        }

        guard lastWeekTotal > 0 else { return nil }
        return Double(thisWeekTotal - lastWeekTotal) / Double(lastWeekTotal) * 100
    }

    // MARK: - Month stats for chart modal

    static func monthStats(counterId: UUID, history: [DailyHistory], year: Int, month: Int) -> MonthStats {
        let calendar = Calendar(identifier: .iso8601)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        dayFormatter.timeZone = .current

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let monthStart = calendar.date(from: components),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return MonthStats(total: 0, dailyAvg: 0, bestDay: 0, activeDays: 0, totalDays: 0, dailyData: [])
        }

        let totalDays = monthRange.count
        let historyMap = Dictionary(grouping: history.filter { $0.counterId == counterId }, by: { $0.date })
            .mapValues { $0.first?.total ?? 0 }

        var dailyData: [DayStat] = []
        var total = 0
        var bestDay = 0
        var activeDays = 0

        for day in 1...totalDays {
            components.day = day
            guard let date = calendar.date(from: components) else { continue }
            let dateStr = formatter.string(from: date)
            let dayLabel = dayFormatter.string(from: date)
            let value = historyMap[dateStr] ?? 0

            dailyData.append(DayStat(date: dateStr, dayLabel: dayLabel, total: value))
            total += value
            bestDay = max(bestDay, value)
            if value > 0 { activeDays += 1 }
        }

        let dailyAvg = totalDays > 0 ? Double(total) / Double(totalDays) : 0

        return MonthStats(
            total: total,
            dailyAvg: dailyAvg,
            bestDay: bestDay,
            activeDays: activeDays,
            totalDays: totalDays,
            dailyData: dailyData
        )
    }

    // MARK: - Current week data for mini chart

    static func currentWeekData(counterId: UUID, history: [DailyHistory], currentCount: Int) -> [DayStat] {
        let calendar = Calendar(identifier: .iso8601)
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }

        let historyMap = Dictionary(grouping: history.filter { $0.counterId == counterId }, by: { $0.date })
            .mapValues { $0.first?.total ?? 0 }

        let todayStr = formatter.string(from: today)
        var data: [DayStat] = []

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: weekStart) else { continue }
            let dateStr = formatter.string(from: date)
            var value = historyMap[dateStr] ?? 0
            if dateStr == todayStr { value = max(value, currentCount) }
            data.append(DayStat(date: dateStr, dayLabel: dayLabels[i], total: value))
        }

        return data
    }

    // MARK: - Goal milestone count

    static func goalHitCount(counterId: UUID, goal: Int, history: [DailyHistory], month: Int, year: Int) -> Int {
        let prefix = String(format: "%04d-%02d", year, month)
        return history.filter { $0.counterId == counterId && $0.date.hasPrefix(prefix) && $0.total >= goal }.count
    }

    // MARK: - Helpers

    private static func datesInRange(from start: Date, to end: Date, formatter: DateFormatter) -> Set<String> {
        let calendar = Calendar(identifier: .iso8601)
        var dates = Set<String>()
        var current = start
        while current <= end {
            dates.insert(formatter.string(from: current))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
```

- [ ] **Step 2: Write tests**

```swift
// countr/countrTests/StatsServiceTests.swift
import Testing
import Foundation
@testable import countr

@Test func totalLoggedToday_sumsAllCounts() {
    let c1 = Counter(name: "A")
    c1.count = 5
    let c2 = Counter(name: "B")
    c2.count = 3
    let total = StatsService.totalLoggedToday(counters: [c1, c2])
    #expect(total == 8)
}

@Test func totalLoggedToday_emptyCounters_returnsZero() {
    let total = StatsService.totalLoggedToday(counters: [])
    #expect(total == 0)
}

@Test func goalHitCount_countsMatchingDays() {
    let id = UUID()
    let history = [
        DailyHistory(counterId: id, date: "2026-03-01", total: 10),
        DailyHistory(counterId: id, date: "2026-03-05", total: 5),
        DailyHistory(counterId: id, date: "2026-03-10", total: 8),
        DailyHistory(counterId: id, date: "2026-03-15", total: 3),
    ]
    let count = StatsService.goalHitCount(counterId: id, goal: 5, history: history, month: 3, year: 2026)
    #expect(count == 3) // 10, 5, 8 all >= 5
}

@Test func monthStats_calculatesCorrectly() {
    let id = UUID()
    let history = [
        DailyHistory(counterId: id, date: "2026-03-01", total: 10),
        DailyHistory(counterId: id, date: "2026-03-02", total: 5),
        DailyHistory(counterId: id, date: "2026-03-03", total: 0),
    ]
    let stats = StatsService.monthStats(counterId: id, history: history, year: 2026, month: 3)
    #expect(stats.total == 15)
    #expect(stats.bestDay == 10)
    #expect(stats.activeDays == 2)
    #expect(stats.totalDays == 31)
    #expect(stats.dailyData.count == 31)
}

@Test func currentWeekData_returns7Days() {
    let id = UUID()
    let data = StatsService.currentWeekData(counterId: id, history: [], currentCount: 0)
    #expect(data.count == 7)
    #expect(data[0].dayLabel == "M")
    #expect(data[6].dayLabel == "S")
}
```

- [ ] **Step 3: Run tests, commit**

Build, run tests. Commit: `feat: add stats calculation service with week and month data`

---

### Task 2: Summary Card Component

**Files:**
- Create: `countr/countr/Views/Stats/SummaryCard.swift`

- [ ] **Step 1: Create SummaryCard**

```swift
// countr/countr/Views/Stats/SummaryCard.swift
import SwiftUI

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    var trend: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            if let trend {
                HStack(spacing: 2) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text("\(abs(Int(trend)))% vs last week")
                        .font(.caption2)
                }
                .foregroundStyle(trend >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Build, commit**

Commit: `feat: add summary card component for stats screen`

---

### Task 3: Mini Line Chart

**Files:**
- Create: `countr/countr/Views/Stats/MiniLineChart.swift`

- [ ] **Step 1: Create MiniLineChart using SwiftUI Charts**

```swift
// countr/countr/Views/Stats/MiniLineChart.swift
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
```

- [ ] **Step 2: Build, commit**

Commit: `feat: add mini line chart component using SwiftUI Charts`

---

### Task 4: Stats Counter Card

**Files:**
- Create: `countr/countr/Views/Stats/StatsCounterCard.swift`

- [ ] **Step 1: Create StatsCounterCard**

```swift
// countr/countr/Views/Stats/StatsCounterCard.swift
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
```

- [ ] **Step 2: Build, commit**

Commit: `feat: add stats counter card with mini chart and milestone badge`

---

### Task 5: Daily Breakdown Row & Chart Modal

**Files:**
- Create: `countr/countr/Views/Stats/DailyBreakdownRow.swift`
- Create: `countr/countr/Views/Stats/ChartModal.swift`

- [ ] **Step 1: Create DailyBreakdownRow**

```swift
// countr/countr/Views/Stats/DailyBreakdownRow.swift
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
```

- [ ] **Step 2: Create ChartModal**

```swift
// countr/countr/Views/Stats/ChartModal.swift
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
```

- [ ] **Step 3: Build, commit**

Commit: `feat: add chart modal with month navigation and daily breakdown`

---

### Task 6: Stats Screen & Wire to Tab

**Files:**
- Create: `countr/countr/Views/Stats/StatsScreen.swift`
- Modify: `countr/countr/Views/MainTabView.swift`

- [ ] **Step 1: Create StatsScreen**

```swift
// countr/countr/Views/Stats/StatsScreen.swift
import SwiftUI
import SwiftData

struct StatsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Counter.order) private var counters: [Counter]

    @State private var allHistory: [UUID: [DailyHistory]] = [:]
    @State private var selectedCounter: Counter?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summarySection
                    countersSection
                }
                .padding()
            }
            .navigationTitle("Stats")
            .task { loadAllHistory() }
            .fullScreenCover(item: $selectedCounter) { counter in
                ChartModal(counter: counter)
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        let totalToday = StatsService.totalLoggedToday(counters: Array(counters))
        let best = StatsService.bestStreak(counters: Array(counters), allHistory: allHistory)
        let trend = StatsService.trendPercentage(counters: Array(counters), allHistory: allHistory)

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            SummaryCard(title: "Counters", value: "\(counters.count)", icon: "number")
            SummaryCard(title: "Today", value: "\(totalToday)", icon: "calendar", trend: trend)
            SummaryCard(title: "Best Streak", value: "\(best)", icon: "flame")
        }
    }

    // MARK: - Per-counter cards

    private var countersSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(counters) { counter in
                let history = allHistory[counter.id] ?? []
                let weekData = StatsService.currentWeekData(
                    counterId: counter.id,
                    history: history,
                    currentCount: counter.count
                )
                let streak = StreakService.calculateStreak(
                    mode: counter.resetMode,
                    history: history,
                    currentDate: Counter.todayString(),
                    currentCount: counter.count
                )
                let calendar = Calendar(identifier: .iso8601)
                let now = Date()
                let goalHits = counter.goal.map {
                    StatsService.goalHitCount(
                        counterId: counter.id,
                        goal: $0,
                        history: history,
                        month: calendar.component(.month, from: now),
                        year: calendar.component(.year, from: now)
                    )
                } ?? 0

                StatsCounterCard(
                    counter: counter,
                    weekData: weekData,
                    streak: streak,
                    goalHits: goalHits
                ) {
                    selectedCounter = counter
                }
            }
        }
    }

    // MARK: - Data

    private func loadAllHistory() {
        var result: [UUID: [DailyHistory]] = [:]
        for counter in counters {
            let counterId = counter.id
            let descriptor = FetchDescriptor<DailyHistory>(
                predicate: #Predicate { $0.counterId == counterId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            result[counterId] = (try? modelContext.fetch(descriptor)) ?? []
        }
        allHistory = result
    }
}
```

- [ ] **Step 2: Wire StatsScreen into MainTabView**

Replace `Text("Stats")` placeholder in MainTabView with `StatsScreen()`.

- [ ] **Step 3: Build, run all tests, commit**

Commit: `feat: add stats screen with summary cards, counter stats, and chart modal`

---

## Summary

After completing this plan:
- Stats tab shows summary cards (total counters, logged today with trend, best streak)
- Per-counter cards show count, goal, streak, milestone badges, and mini week chart
- Tapping a card opens a full chart modal with month navigation
- Chart modal shows line chart, stats grid, and daily breakdown
- All calculation logic is in StatsService with tests
