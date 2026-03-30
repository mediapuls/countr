import SwiftData

enum ModelContainerHelper {
    static func createContainer() throws -> ModelContainer {
        let schema = Schema([
            Counter.self,
            CounterGroup.self,
            DailyHistory.self,
        ])

        #if targetEnvironment(simulator)
        // Simulator: use local store only (CloudKit doesn't work reliably)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
        #else
        // Device: use CloudKit sync
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.timotoaster.countr")
        )
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // Fall back to local store if CloudKit fails
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [localConfig])
        }
        #endif
    }
}
