import SwiftUI

enum CounterColor: String, Codable, CaseIterable, Identifiable {
    case coral, orange, amber, yellow, lime, green
    case teal, cyan, blue, indigo, purple, pink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .coral: Color(red: 1.0, green: 0.45, blue: 0.40)
        case .orange: Color.orange
        case .amber: Color(red: 1.0, green: 0.75, blue: 0.0)
        case .yellow: Color.yellow
        case .lime: Color(red: 0.55, green: 0.82, blue: 0.15)
        case .green: Color.green
        case .teal: Color.teal
        case .cyan: Color.cyan
        case .blue: Color.blue
        case .indigo: Color.indigo
        case .purple: Color.purple
        case .pink: Color.pink
        }
    }
}
