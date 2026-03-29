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
