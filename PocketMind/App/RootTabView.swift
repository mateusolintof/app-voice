import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Hoje", systemImage: "sun.max.fill")
                }

            SessionView()
                .tabItem {
                    Label("Sessão", systemImage: "waveform.and.mic")
                }

            PlanningView()
                .tabItem {
                    Label("Planejamento", systemImage: "list.bullet.clipboard")
                }

            ReviewView()
                .tabItem {
                    Label("Revisão", systemImage: "book.closed")
                }

            SettingsView()
                .tabItem {
                    Label("Config", systemImage: "gearshape")
                }
        }
        .tint(CognitiveTheme.action)
    }
}
