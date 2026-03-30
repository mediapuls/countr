import AppIntents

struct CountrShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: IncrementCounterIntent(),
            phrases: [
                "Add to \(\.$counter) in \(.applicationName)",
                "Increment \(\.$counter) in \(.applicationName)",
                "Log \(\.$counter) in \(.applicationName)"
            ],
            shortTitle: "Increment Counter",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: GetCounterIntent(),
            phrases: [
                "How many for \(\.$counter) in \(.applicationName)",
                "Check \(\.$counter) in \(.applicationName)",
                "What's \(\.$counter) at in \(.applicationName)"
            ],
            shortTitle: "Get Counter",
            systemImageName: "number.circle"
        )
        AppShortcut(
            intent: ResetCounterIntent(),
            phrases: [
                "Reset \(\.$counter) in \(.applicationName)"
            ],
            shortTitle: "Reset Counter",
            systemImageName: "arrow.counterclockwise"
        )
    }
}
