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
