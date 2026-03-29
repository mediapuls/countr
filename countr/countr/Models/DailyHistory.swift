import Foundation
import SwiftData

@Model
final class DailyHistory {
    var id: UUID = UUID()
    var counterId: UUID = UUID()
    var date: String = ""
    var total: Int = 0

    init(counterId: UUID, date: String, total: Int) {
        self.id = UUID()
        self.counterId = counterId
        self.date = date
        self.total = total
    }
}
