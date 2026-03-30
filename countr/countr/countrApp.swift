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
    @State private var liveActivityService = LiveActivityService()
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("onboarding_complete") private var onboardingComplete: Bool = false
    @AppStorage("theme_mode") private var themeMode: String = "auto"

    private var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingComplete {
                    MainTabView()
                        .environment(hapticService)
                        .environment(undoService)
                        .environment(celebrationService)
                        .environment(liveActivityService)
                        .overlay {
                            if celebrationService.isShowingConfetti {
                                ConfettiView().ignoresSafeArea()
                            }
                        }
                } else {
                    OnboardingScreen()
                }
            }
            .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let context = sharedModelContainer.mainContext
                let counters = (try? context.fetch(FetchDescriptor<Counter>())) ?? []
                ResetService.processResets(counters: counters, context: context)
                try? context.save()
                NotificationService.rescheduleAll(counters: counters)
                WidgetSyncService.sync(context: context)
                // End live activity if the tracked counter was reset
                if let trackedId = liveActivityService.activeCounterId,
                   let trackedCounter = counters.first(where: { $0.id == trackedId }),
                   trackedCounter.count == 0 {
                    liveActivityService.endTracking()
                }
            }
        }
    }
}
