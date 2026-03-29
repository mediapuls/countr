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
