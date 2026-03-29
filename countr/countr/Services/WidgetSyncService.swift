import Foundation
import SwiftData
import WidgetKit

enum WidgetSyncService {
    /// Reads all counters from the model context and writes them to the shared
    /// app group UserDefaults so the widget extension can display them.
    static func sync(context: ModelContext) {
        let counters = (try? context.fetch(FetchDescriptor<Counter>(
            sortBy: [SortDescriptor(\.order)]
        ))) ?? []

        let widgetData = counters.map { counter in
            WidgetCounterData(
                id: counter.id,
                name: counter.name,
                count: counter.count,
                goal: counter.goal,
                colorName: counter.color.rawValue,
                resetMode: counter.resetMode.rawValue
            )
        }

        guard let defaults = UserDefaults(suiteName: WidgetCounterData.suiteName) else { return }
        if let encoded = try? JSONEncoder().encode(widgetData) {
            defaults.set(encoded, forKey: WidgetCounterData.userDefaultsKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
