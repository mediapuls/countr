import Testing
import Foundation
@testable import countr

@Test func shouldResetDaily_sameDay_returnsFalse() {
    let result = ResetService.shouldReset(mode: .daily, lastResetDate: "2026-03-29", currentDate: "2026-03-29")
    #expect(result == false)
}

@Test func shouldResetDaily_nextDay_returnsTrue() {
    let result = ResetService.shouldReset(mode: .daily, lastResetDate: "2026-03-28", currentDate: "2026-03-29")
    #expect(result == true)
}

@Test func shouldResetDaily_multipleDaysLater_returnsTrue() {
    let result = ResetService.shouldReset(mode: .daily, lastResetDate: "2026-03-20", currentDate: "2026-03-29")
    #expect(result == true)
}

@Test func shouldResetWeekly_sameWeek_returnsFalse() {
    let result = ResetService.shouldReset(mode: .weekly, lastResetDate: "2026-03-23", currentDate: "2026-03-27")
    #expect(result == false)
}

@Test func shouldResetWeekly_nextWeek_returnsTrue() {
    let result = ResetService.shouldReset(mode: .weekly, lastResetDate: "2026-03-27", currentDate: "2026-03-30")
    #expect(result == true)
}

@Test func shouldResetMonthly_sameMonth_returnsFalse() {
    let result = ResetService.shouldReset(mode: .monthly, lastResetDate: "2026-03-01", currentDate: "2026-03-29")
    #expect(result == false)
}

@Test func shouldResetMonthly_nextMonth_returnsTrue() {
    let result = ResetService.shouldReset(mode: .monthly, lastResetDate: "2026-03-15", currentDate: "2026-04-01")
    #expect(result == true)
}

@Test func shouldResetYearly_sameYear_returnsFalse() {
    let result = ResetService.shouldReset(mode: .yearly, lastResetDate: "2026-01-01", currentDate: "2026-12-31")
    #expect(result == false)
}

@Test func shouldResetYearly_nextYear_returnsTrue() {
    let result = ResetService.shouldReset(mode: .yearly, lastResetDate: "2025-06-15", currentDate: "2026-01-01")
    #expect(result == true)
}

@Test func shouldResetManual_neverResets() {
    let result = ResetService.shouldReset(mode: .manual, lastResetDate: "2020-01-01", currentDate: "2026-12-31")
    #expect(result == false)
}
