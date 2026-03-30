import AppIntents
import SwiftData

struct ResetCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Counter"
    static var description = IntentDescription("Reset a counter to zero")
    static var openAppWhenRun = false

    @Parameter(title: "Counter")
    var counter: CounterEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try ModelContext(ModelContainerHelper.createContainer())
        guard let id = UUID(uuidString: counter.id) else {
            throw IntentError.invalidParameter
        }
        let descriptor = FetchDescriptor<Counter>(predicate: #Predicate { $0.id == id })
        guard let dbCounter = try context.fetch(descriptor).first else {
            throw IntentError.entityNotFound
        }
        dbCounter.count = 0
        try context.save()
        return .result(dialog: "\(dbCounter.name) has been reset to 0")
    }
}
