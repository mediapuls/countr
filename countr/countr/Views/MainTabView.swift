import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                HomeScreen()
            }
            Tab("Stats", systemImage: "chart.bar.fill", value: 1) {
                StatsScreen()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                SettingsScreen()
            }
        }
    }
}
