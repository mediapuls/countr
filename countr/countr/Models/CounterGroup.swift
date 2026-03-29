import Foundation
import SwiftData

@Model
final class CounterGroup {
    var id: UUID = UUID()
    var name: String = ""
    var order: Int = 0
    var isExpanded: Bool = true
    var counters: [Counter] = []

    init(name: String, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.isExpanded = true
    }
}
