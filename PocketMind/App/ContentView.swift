import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            JournalView()
                .tabItem {
                    Label("Diario", systemImage: "book.fill")
                }

            RitualsView()
                .tabItem {
                    Label("Rituais", systemImage: "sparkles")
                }

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.fill")
                }
        }
        .tint(.indigo)
    }
}
