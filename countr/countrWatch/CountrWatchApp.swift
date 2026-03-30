import SwiftUI

@main
struct CountrWatchApp: App {
    @State private var dataService = WatchDataService()

    var body: some Scene {
        WindowGroup {
            CounterListView()
                .environment(dataService)
        }
    }
}
