import Foundation
import SwiftData

// MARK: - Codable transfer types

struct CounterExport: Codable {
    let id: String
    let name: String
    let count: Int
    let stepValue: Int
    let resetMode: String
    let lastResetDate: String
    let goal: Int?
    let color: String
    let emoji: String?
    let reminderTime: String?
    let order: Int
    let groupId: String?
    let createdAt: Date
}

struct CounterGroupExport: Codable {
    let id: String
    let name: String
    let order: Int
    let isExpanded: Bool
}

struct DailyHistoryExport: Codable {
    let id: String
    let counterId: String
    let date: String
    let total: Int
}

struct BackupFile: Codable {
    let version: Int
    let counters: [CounterExport]
    let groups: [CounterGroupExport]
    // key is counterId string
    let histories: [String: [DailyHistoryExport]]
}

// MARK: - BackupService

enum BackupError: LocalizedError {
    case invalidStructure
    case unsupportedVersion(Int)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidStructure:
            return "The file does not appear to be a valid countr backup."
        case .unsupportedVersion(let v):
            return "Backup version \(v) is not supported by this app."
        case .decodingFailed(let error):
            return "Could not read backup: \(error.localizedDescription)"
        }
    }
}

struct BackupService {

    // MARK: Export

    static func exportData(context: ModelContext) throws -> Data {
        let counters = (try? context.fetch(FetchDescriptor<Counter>())) ?? []
        let groups = (try? context.fetch(FetchDescriptor<CounterGroup>())) ?? []
        let allHistory = (try? context.fetch(FetchDescriptor<DailyHistory>())) ?? []

        let groupExports: [CounterGroupExport] = groups.map { g in
            CounterGroupExport(
                id: g.id.uuidString,
                name: g.name,
                order: g.order,
                isExpanded: g.isExpanded
            )
        }

        let counterExports: [CounterExport] = counters.map { c in
            CounterExport(
                id: c.id.uuidString,
                name: c.name,
                count: c.count,
                stepValue: c.stepValue,
                resetMode: c.resetMode.rawValue,
                lastResetDate: c.lastResetDate,
                goal: c.goal,
                color: c.color.rawValue,
                emoji: c.emoji,
                reminderTime: c.reminderTime,
                order: c.order,
                groupId: c.group?.id.uuidString,
                createdAt: c.createdAt
            )
        }

        // Group history entries by counterId
        var historiesByCounter: [String: [DailyHistoryExport]] = [:]
        for h in allHistory {
            let key = h.counterId.uuidString
            let entry = DailyHistoryExport(
                id: h.id.uuidString,
                counterId: key,
                date: h.date,
                total: h.total
            )
            historiesByCounter[key, default: []].append(entry)
        }

        let backup = BackupFile(
            version: 1,
            counters: counterExports,
            groups: groupExports,
            histories: historiesByCounter
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(backup)
    }

    // MARK: Import

    static func importData(from data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup: BackupFile
        do {
            backup = try decoder.decode(BackupFile.self, from: data)
        } catch {
            throw BackupError.decodingFailed(error)
        }

        guard backup.version == 1 else {
            throw BackupError.unsupportedVersion(backup.version)
        }

        // Delete all existing data
        let existingCounters = (try? context.fetch(FetchDescriptor<Counter>())) ?? []
        let existingGroups = (try? context.fetch(FetchDescriptor<CounterGroup>())) ?? []
        let existingHistory = (try? context.fetch(FetchDescriptor<DailyHistory>())) ?? []

        for item in existingCounters { context.delete(item) }
        for item in existingGroups { context.delete(item) }
        for item in existingHistory { context.delete(item) }

        // Insert groups first so counters can reference them
        var groupMap: [String: CounterGroup] = [:]
        for g in backup.groups {
            let group = CounterGroup(name: g.name, order: g.order)
            if let uuid = UUID(uuidString: g.id) {
                group.id = uuid
            }
            group.isExpanded = g.isExpanded
            context.insert(group)
            groupMap[g.id] = group
        }

        // Insert counters
        for c in backup.counters {
            let group = c.groupId.flatMap { groupMap[$0] }
            let counter = Counter(
                name: c.name,
                resetMode: ResetMode(rawValue: c.resetMode) ?? .manual,
                stepValue: c.stepValue,
                goal: c.goal,
                color: CounterColor(rawValue: c.color) ?? .blue,
                reminderTime: c.reminderTime,
                order: c.order,
                group: group
            )
            if let uuid = UUID(uuidString: c.id) {
                counter.id = uuid
            }
            counter.count = c.count
            counter.lastResetDate = c.lastResetDate
            counter.emoji = c.emoji
            counter.createdAt = c.createdAt
            context.insert(counter)
        }

        // Insert histories
        for (_, entries) in backup.histories {
            for h in entries {
                guard let counterUUID = UUID(uuidString: h.counterId) else { continue }
                let history = DailyHistory(
                    counterId: counterUUID,
                    date: h.date,
                    total: h.total
                )
                if let uuid = UUID(uuidString: h.id) {
                    history.id = uuid
                }
                context.insert(history)
            }
        }

        try? context.save()
    }
}
