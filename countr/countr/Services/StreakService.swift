import Foundation

enum StreakService {
    static func calculateStreak(mode: ResetMode, history: [DailyHistory], currentDate: String, currentCount: Int) -> Int {
        switch mode {
        case .daily, .manual:
            return dailyStreak(history: history, currentDate: currentDate, currentCount: currentCount)
        case .weekly:
            return periodicStreak(history: history, currentDate: currentDate, currentCount: currentCount, component: .weekOfYear, yearComponent: .yearForWeekOfYear)
        case .monthly:
            return periodicStreak(history: history, currentDate: currentDate, currentCount: currentCount, component: .month, yearComponent: .year)
        case .yearly:
            return periodicStreak(history: history, currentDate: currentDate, currentCount: currentCount, component: .year, yearComponent: nil)
        }
    }

    private static func dailyStreak(history: [DailyHistory], currentDate: String, currentCount: Int) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        guard let today = formatter.date(from: currentDate) else { return 0 }

        var activeDates = Set<String>()
        for entry in history where entry.total > 0 { activeDates.insert(entry.date) }
        if currentCount > 0 { activeDates.insert(currentDate) }

        var streak = 0
        var checkDate = today
        while true {
            let dateStr = formatter.string(from: checkDate)
            if activeDates.contains(dateStr) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        return streak
    }

    private static func periodicStreak(history: [DailyHistory], currentDate: String, currentCount: Int, component: Calendar.Component, yearComponent: Calendar.Component?) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        guard let today = formatter.date(from: currentDate) else { return 0 }

        struct Period: Hashable { let year: Int; let value: Int }

        var activePeriods = Set<Period>()
        for entry in history where entry.total > 0 {
            if let date = formatter.date(from: entry.date) {
                let periodValue = calendar.component(component, from: date)
                let yearValue = yearComponent.map { calendar.component($0, from: date) } ?? 0
                activePeriods.insert(Period(year: yearValue, value: periodValue))
            }
        }
        if currentCount > 0 {
            let periodValue = calendar.component(component, from: today)
            let yearValue = yearComponent.map { calendar.component($0, from: today) } ?? 0
            activePeriods.insert(Period(year: yearValue, value: periodValue))
        }

        var streak = 0
        var checkDate = today
        while true {
            let periodValue = calendar.component(component, from: checkDate)
            let yearValue = yearComponent.map { calendar.component($0, from: checkDate) } ?? 0
            if activePeriods.contains(Period(year: yearValue, value: periodValue)) {
                streak += 1
                switch component {
                case .weekOfYear: checkDate = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate)!
                case .month: checkDate = calendar.date(byAdding: .month, value: -1, to: checkDate)!
                case .year: checkDate = calendar.date(byAdding: .year, value: -1, to: checkDate)!
                default: break
                }
            } else { break }
        }
        return streak
    }
}
