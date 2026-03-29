import Foundation

/// Shared data model written to app group UserDefaults for widget consumption.
struct WidgetCounterData: Codable, Identifiable {
    let id: UUID
    let name: String
    let count: Int
    let goal: Int?
    let colorName: String
    let resetMode: String
}

extension WidgetCounterData {
    static let userDefaultsKey = "widget_counters"
    static let suiteName = "group.com.timotoaster.countr"
}
