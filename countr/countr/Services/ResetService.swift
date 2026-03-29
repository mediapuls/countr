import Foundation
import SwiftData

enum ResetService {
    static func shouldReset(mode: ResetMode, lastResetDate: String, currentDate: String) -> Bool {
        guard mode != .manual else { return false }
        guard lastResetDate != currentDate else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current

        guard let last = formatter.date(from: lastResetDate),
              let current = formatter.date(from: currentDate) else { return false }

        let calendar = Calendar.current

        switch mode {
        case .manual: return false
        case .daily: return !calendar.isDate(last, inSameDayAs: current)
        case .weekly:
            let lastWeek = calendar.component(.weekOfYear, from: last)
            let lastYear = calendar.component(.yearForWeekOfYear, from: last)
            let currentWeek = calendar.component(.weekOfYear, from: current)
            let currentYear = calendar.component(.yearForWeekOfYear, from: current)
            return lastYear != currentYear || lastWeek != currentWeek
        case .monthly:
            let lastMonth = calendar.component(.month, from: last)
            let lastYear = calendar.component(.year, from: last)
            let currentMonth = calendar.component(.month, from: current)
            let currentYear = calendar.component(.year, from: current)
            return lastYear != currentYear || lastMonth != currentMonth
        case .yearly:
            return calendar.component(.year, from: last) != calendar.component(.year, from: current)
        }
    }

    static func processResets(counters: [Counter], context: ModelContext) {
        let today = Counter.todayString()
        for counter in counters {
            if shouldReset(mode: counter.resetMode, lastResetDate: counter.lastResetDate, currentDate: today) {
                if counter.count > 0 {
                    let history = DailyHistory(counterId: counter.id, date: counter.lastResetDate, total: counter.count)
                    context.insert(history)
                }
                counter.count = 0
                counter.lastResetDate = today
            }
        }
        trimHistory(counters: counters, context: context)
    }

    static func trimHistory(counters: [Counter], context: ModelContext) {
        for counter in counters {
            let counterId = counter.id
            var descriptor = FetchDescriptor<DailyHistory>(
                predicate: #Predicate { $0.counterId == counterId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            descriptor.fetchOffset = 365
            if let excess = try? context.fetch(descriptor) {
                for entry in excess { context.delete(entry) }
            }
        }
    }
}
