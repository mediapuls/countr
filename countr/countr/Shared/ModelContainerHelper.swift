import SwiftData

enum ModelContainerHelper {
    static func createContainer() throws -> ModelContainer {
        let schema = Schema([
            Counter.self,
            CounterGroup.self,
            DailyHistory.self,
        ])
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.timotoaster.countr")
        )
        // Fall back to a local store if CloudKit is unavailable (e.g. simulator without iCloud)
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [localConfig])
        }
    }
}
