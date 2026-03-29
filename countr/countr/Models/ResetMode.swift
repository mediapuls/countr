import Foundation

enum ResetMode: String, Codable, CaseIterable, Identifiable {
    case manual
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }
}
