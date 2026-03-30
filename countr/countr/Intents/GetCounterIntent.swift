import AppIntents
import SwiftData

struct GetCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Counter Value"
    static var description = IntentDescription("Check the current count")
    static var openAppWhenRun = false

    @Parameter(title: "Counter")
    var counter: CounterEntity

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let context = try ModelContext(ModelContainerHelper.createContainer())
        guard let id = UUID(uuidString: counter.id) else {
            throw IntentError.invalidParameter
        }
        let descriptor = FetchDescriptor<Counter>(predicate: #Predicate { $0.id == id })
        guard let dbCounter = try context.fetch(descriptor).first else {
            throw IntentError.entityNotFound
        }
        let dialog: IntentDialog
        if let goal = dbCounter.goal {
            dialog = "\(dbCounter.name) is at \(dbCounter.count) out of \(goal)"
        } else {
            dialog = "\(dbCounter.name) is at \(dbCounter.count)"
        }
        return .result(value: dbCounter.count, dialog: dialog)
    }
}
