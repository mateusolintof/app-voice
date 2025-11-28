import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int // 0: Main, 1: Notes, 2: Settings
    
    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isShowing = false }
                    }
                
                HStack {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(PremiumTheme.mainGradient)
                            
                            Text("PocketMind")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 60)
                        
                        // Menu Items
                        VStack(alignment: .leading, spacing: 24) {
                            MenuRow(icon: "mic.fill", title: "Nova Gravação", isSelected: selectedTab == 0) {
                                selectedTab = 0
                                withAnimation { isShowing = false }
                            }
                            
                            MenuRow(icon: "note.text", title: "Minhas Notas", isSelected: selectedTab == 1) {
                                selectedTab = 1
                                withAnimation { isShowing = false }
                            }
                            
                            MenuRow(icon: "gearshape.fill", title: "Configurações", isSelected: selectedTab == 2) {
                                selectedTab = 2
                                withAnimation { isShowing = false }
                            }
                        }
                        
                        Spacer()
                        
                        // Footer
                        Text("Versão 3.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .frame(width: 280)
                    .background(Color(uiColor: .systemBackground))
                    .ignoresSafeArea()
                    
                    Spacer()
                }
                .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut, value: isShowing)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            .foregroundStyle(isSelected ? .blue : .primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
