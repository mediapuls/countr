import AppIntents
import SwiftData

struct IncrementCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Counter"
    static var description = IntentDescription("Add to a counter")
    static var openAppWhenRun = false

    @Parameter(title: "Counter")
    var counter: CounterEntity

    @Parameter(title: "Amount", default: 1)
    var amount: Int

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let context = try ModelContext(ModelContainerHelper.createContainer())
        guard let id = UUID(uuidString: counter.id) else {
            throw IntentError.invalidParameter
        }
        let descriptor = FetchDescriptor<Counter>(predicate: #Predicate { $0.id == id })
        guard let dbCounter = try context.fetch(descriptor).first else {
            throw IntentError.entityNotFound
        }
        let increment = amount > 0 ? amount : dbCounter.stepValue
        dbCounter.count += increment
        try context.save()
        return .result(value: dbCounter.count)
    }
}

enum IntentError: Error {
    case invalidParameter
    case entityNotFound
}
