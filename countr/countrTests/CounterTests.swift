import Testing
import Foundation
@testable import countr

@Test func counterInitializesWithDefaults() {
    let counter = Counter(name: "Water")
    #expect(counter.name == "Water")
    #expect(counter.count == 0)
    #expect(counter.stepValue == 1)
    #expect(counter.resetMode == .manual)
    #expect(counter.goal == nil)
    #expect(counter.color == .blue)
    #expect(counter.group == nil)
}

@Test func counterInitializesWithCustomValues() {
    let counter = Counter(
        name: "Exercise",
        resetMode: .daily,
        stepValue: 5,
        goal: 30,
        color: .green,
        reminderTime: "20:00"
    )
    #expect(counter.name == "Exercise")
    #expect(counter.stepValue == 5)
    #expect(counter.resetMode == .daily)
    #expect(counter.goal == 30)
    #expect(counter.color == .green)
    #expect(counter.reminderTime == "20:00")
}

@Test func counterTodayStringFormatsCorrectly() {
    let today = Counter.todayString()
    let parts = today.split(separator: "-")
    #expect(parts.count == 3)
    #expect(parts[0].count == 4)
    #expect(parts[1].count == 2)
    #expect(parts[2].count == 2)
}

@Test func counterGroupInitializes() {
    let group = CounterGroup(name: "Health", order: 0)
    #expect(group.name == "Health")
    #expect(group.isExpanded == true)
    #expect((group.counters ?? []).isEmpty)
}

@Test func dailyHistoryInitializes() {
    let id = UUID()
    let history = DailyHistory(counterId: id, date: "2026-03-29", total: 15)
    #expect(history.counterId == id)
    #expect(history.date == "2026-03-29")
    #expect(history.total == 15)
}

@Test func resetModeLabel() {
    #expect(ResetMode.daily.label == "Daily")
    #expect(ResetMode.manual.label == "Manual")
}

@Test func counterColorMapsToSwiftUIColor() {
    for counterColor in CounterColor.allCases {
        _ = counterColor.color
    }
}
