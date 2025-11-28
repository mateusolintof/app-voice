import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    
    var body: some View {
        ZStack {
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    RecordingView(showMenu: $showMenu)
                case 1:
                    NotesListView(showMenu: $showMenu)
                case 2:
                    SettingsView()
                        .overlay(alignment: .topLeading) {
                            Button(action: { withAnimation { showMenu.toggle() } }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .padding(.leading, 16)
                                    .padding(.top, 48)
                            }
                        }
                default:
                    Text("Error")
                }
            }
            .disabled(showMenu) // Disable interaction when menu is open
            .offset(x: showMenu ? 200 : 0) // Slide effect
            .scaleEffect(showMenu ? 0.9 : 1) // Scale effect
            .rotation3DEffect(.degrees(showMenu ? -10 : 0), axis: (x: 0, y: 1, z: 0))
            .ignoresSafeArea()
            
            // Side Menu
            SideMenuView(isShowing: $showMenu, selectedTab: $selectedTab)
        }
        .background(Color.black) // Background for the 3D effect
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text("Toque no microfone para começar")
                .font(.headline)
                .foregroundStyle(.gray)
            
            Text("Sua voz será transcrita automaticamente.")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processando...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
