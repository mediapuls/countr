import Foundation

/// Shared Codable model written by the main app to the app group UserDefaults.
/// Keep in sync with countr/Shared/WidgetData.swift.
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
