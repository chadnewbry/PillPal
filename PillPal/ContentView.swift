import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "pills.fill")
                }
                .tag(0)
                .accessibilityIdentifier("tab_today")

            WeekViewTab()
                .tabItem {
                    Label("Week", systemImage: "calendar")
                }
                .tag(1)
                .accessibilityIdentifier("tab_week")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }
                .tag(2)
                .accessibilityIdentifier("tab_history")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
                .accessibilityIdentifier("tab_settings")
        }
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
}
