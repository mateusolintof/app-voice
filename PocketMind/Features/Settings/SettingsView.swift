import SwiftUI

struct SettingsView: View {
    @AppStorage("openAIKey") private var openAIKey = ""
    @AppStorage("googleCalendarKey") private var googleCalendarKey = ""
    @AppStorage("linearKey") private var linearKey = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Keys")) {
                    SecureField("OpenAI API Key", text: $openAIKey)
                    SecureField("Google Calendar API Key", text: $googleCalendarKey)
                    SecureField("Linear API Key", text: $linearKey)
                }
                
                Section(header: Text("About")) {
                    Text("PocketMind v1.0")
                    Text("Personal AI Assistant")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
