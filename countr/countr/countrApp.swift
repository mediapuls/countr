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
    @State private var undoService = UndoService()
    @State private var celebrationService = CelebrationService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(hapticService)
                .environment(undoService)
                .environment(celebrationService)
                .overlay {
                    if celebrationService.isShowingConfetti {
                        ConfettiView().ignoresSafeArea()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = sharedModelContainer.mainContext
                let counters = (try? context.fetch(FetchDescriptor<Counter>())) ?? []
                ResetService.processResets(counters: counters, context: context)
                try? context.save()
                NotificationService.rescheduleAll(counters: counters)
            }
        }
    }
}
