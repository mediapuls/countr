import Foundation

/// Shared data model used by both the widget and watch extensions.
/// This is a copy of countr/Shared/WidgetData.swift for the watchOS target.
struct WidgetCounterData: Codable, Identifiable, Hashable {
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
