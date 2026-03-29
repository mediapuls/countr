//
//  countrApp.swift
//  countr
//
//  Created by Timo Haldi on 29.03.2026.
//

import SwiftUI
import SwiftData

@main
struct countrApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Counter.self,
            CounterGroup.self,
            DailyHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var hapticService = HapticService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(hapticService)
        }
        .modelContainer(sharedModelContainer)
    }
}
