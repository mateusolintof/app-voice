import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Hoje", systemImage: "sun.max.fill")
                }
                .tag(0)

            JournalView()
                .tabItem {
                    Label("Diario", systemImage: "book.fill")
                }
                .tag(1)

            RitualsView()
                .tabItem {
                    Label("Rituais", systemImage: "sparkles")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(PMDesign.brandPrimary)
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.object as? Int {
                withAnimation(PMDesign.springSnappy) {
                    selectedTab = tab
                }
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { !onboardingCompleted },
            set: { _ in }
        )) {
            OnboardingFlow(isCompleted: $onboardingCompleted)
        }
    }
}
