import ActivityKit
import Foundation

struct CountrActivityAttributes: ActivityAttributes {
    let counterName: String
    let goal: Int?
    let colorName: String

    struct ContentState: Codable, Hashable {
        let count: Int
    }
}
