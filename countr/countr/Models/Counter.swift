import Foundation
import SwiftData

@Model
final class Counter {
    var id: UUID = UUID()
    var name: String = ""
    var count: Int = 0
    var stepValue: Int = 1
    var resetMode: ResetMode = ResetMode.manual
    var lastResetDate: String = ""
    var goal: Int?
    var color: CounterColor = CounterColor.blue
    var emoji: String?
    var reminderTime: String?
    var order: Int = 0
    @Relationship(inverse: \CounterGroup.counters)
    var group: CounterGroup?
    var createdAt: Date = Date()

    init(
        name: String,
        resetMode: ResetMode = .manual,
        stepValue: Int = 1,
        goal: Int? = nil,
        color: CounterColor = .blue,
        reminderTime: String? = nil,
        order: Int = 0,
        group: CounterGroup? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.count = 0
        self.stepValue = stepValue
        self.resetMode = resetMode
        self.lastResetDate = Self.todayString()
        self.goal = goal
        self.color = color
        self.reminderTime = reminderTime
        self.order = order
        self.group = group
        self.createdAt = Date()
    }

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }
}
