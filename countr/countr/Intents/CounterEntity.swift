import AppIntents
import SwiftData

struct CounterEntity: AppEntity {
    static var defaultQuery = CounterEntityQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Counter")

    var id: String
    var name: String
    var count: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "Count: \(count)")
    }

    init(id: String, name: String, count: Int) {
        self.id = id
        self.name = name
        self.count = count
    }

    init(from counter: Counter) {
        self.id = counter.id.uuidString
        self.name = counter.name
        self.count = counter.count
    }
}

struct CounterEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CounterEntity] {
        let context = try ModelContext(ModelContainerHelper.createContainer())
        let descriptor = FetchDescriptor<Counter>()
        let counters = try context.fetch(descriptor)
        return counters
            .filter { identifiers.contains($0.id.uuidString) }
            .map { CounterEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [CounterEntity] {
        let context = try ModelContext(ModelContainerHelper.createContainer())
        let descriptor = FetchDescriptor<Counter>(sortBy: [SortDescriptor(\Counter.order)])
        let counters = try context.fetch(descriptor)
        return counters.map { CounterEntity(from: $0) }
    }
}
