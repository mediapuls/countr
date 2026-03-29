import Testing
import Foundation
@testable import countr

@Test func dailyStreak_consecutiveDays_returnsCorrectCount() {
    let history = [
        DailyHistory(counterId: UUID(), date: "2026-03-29", total: 5),
        DailyHistory(counterId: UUID(), date: "2026-03-28", total: 3),
        DailyHistory(counterId: UUID(), date: "2026-03-27", total: 1),
    ]
    let streak = StreakService.calculateStreak(mode: .daily, history: history, currentDate: "2026-03-29", currentCount: 5)
    #expect(streak == 3)
}

@Test func dailyStreak_gapBreaksStreak() {
    let history = [
        DailyHistory(counterId: UUID(), date: "2026-03-29", total: 5),
        DailyHistory(counterId: UUID(), date: "2026-03-27", total: 3),
    ]
    let streak = StreakService.calculateStreak(mode: .daily, history: history, currentDate: "2026-03-29", currentCount: 5)
    #expect(streak == 1)
}

@Test func dailyStreak_noHistory_withCurrentCount_returns1() {
    let streak = StreakService.calculateStreak(mode: .daily, history: [], currentDate: "2026-03-29", currentCount: 3)
    #expect(streak == 1)
}

@Test func dailyStreak_noHistory_zeroCount_returns0() {
    let streak = StreakService.calculateStreak(mode: .daily, history: [], currentDate: "2026-03-29", currentCount: 0)
    #expect(streak == 0)
}

@Test func weeklyStreak_consecutiveWeeks() {
    // ISO 8601 weeks start Monday. 2026-03-29 (Sun) = week 13
    // 2026-03-25 (Wed) = week 13 (same as current), 2026-03-16 = week 12, 2026-03-09 = week 11, 2026-03-02 = week 10
    let history = [
        DailyHistory(counterId: UUID(), date: "2026-03-25", total: 2),
        DailyHistory(counterId: UUID(), date: "2026-03-16", total: 4),
        DailyHistory(counterId: UUID(), date: "2026-03-09", total: 1),
        DailyHistory(counterId: UUID(), date: "2026-03-02", total: 3),
    ]
    let streak = StreakService.calculateStreak(mode: .weekly, history: history, currentDate: "2026-03-29", currentCount: 1)
    #expect(streak == 4)
}

@Test func monthlyStreak_consecutiveMonths() {
    let history = [
        DailyHistory(counterId: UUID(), date: "2026-03-15", total: 5),
        DailyHistory(counterId: UUID(), date: "2026-02-10", total: 3),
        DailyHistory(counterId: UUID(), date: "2026-01-20", total: 7),
    ]
    let streak = StreakService.calculateStreak(mode: .monthly, history: history, currentDate: "2026-03-29", currentCount: 5)
    #expect(streak == 3)
}

@Test func manualStreak_sameAsDaily() {
    let history = [
        DailyHistory(counterId: UUID(), date: "2026-03-29", total: 1),
        DailyHistory(counterId: UUID(), date: "2026-03-28", total: 1),
    ]
    let streak = StreakService.calculateStreak(mode: .manual, history: history, currentDate: "2026-03-29", currentCount: 1)
    #expect(streak == 2)
}
