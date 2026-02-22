import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("openAIKey") private var openAIKey = ""
    @AppStorage("googleCalendarKey") private var googleCalendarKey = ""
    @AppStorage("linearKey") private var linearKey = ""

    @State private var confrontationLevel: Double = 4
    @State private var selectedModes: Set<InterventionMode> = [.blended]
    @State private var saveMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    apiCard
                    profileCard

                    if !saveMessage.isEmpty {
                        Text(saveMessage)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(CognitiveTheme.mutedInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(CognitiveTheme.canvas.ignoresSafeArea())
            .navigationTitle("Config")
            .onAppear(perform: loadProfile)
        }
    }

    private var apiCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integrações")
                .font(.system(.title3, design: .serif).weight(.bold))

            SecureField("OpenAI API Key", text: $openAIKey)
                .textFieldStyle(.roundedBorder)

            SecureField("Google Calendar API Key", text: $googleCalendarKey)
                .textFieldStyle(.roundedBorder)

            SecureField("Linear API Key", text: $linearKey)
                .textFieldStyle(.roundedBorder)

            Text("Local-first: as chaves ficam neste dispositivo.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(CognitiveTheme.mutedInk)
        }
        .therapyCard()
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Perfil Terapêutico")
                .font(.system(.headline, design: .serif).weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Nível de confronto: \(Int(confrontationLevel))/5")
                    .font(.system(.caption, design: .rounded))
                Slider(value: $confrontationLevel, in: 1...5, step: 1)
                    .tint(CognitiveTheme.warning)
            }

            Text("Métodos padrão")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(CognitiveTheme.mutedInk)

            ForEach(InterventionMode.allCases) { mode in
                Toggle(isOn: Binding(
                    get: { selectedModes.contains(mode) },
                    set: { enabled in
                        if enabled {
                            selectedModes.insert(mode)
                        } else if selectedModes.count > 1 {
                            selectedModes.remove(mode)
                        }
                    }
                )) {
                    Text(mode.title)
                        .font(.system(.footnote, design: .rounded))
                }
                .toggleStyle(.switch)
            }

            Button {
                saveProfile()
            } label: {
                Label("Salvar Perfil", systemImage: "person.crop.circle.badge.checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TherapyActionButtonStyle(color: CognitiveTheme.action))
        }
        .therapyCard()
    }

    private func loadProfile() {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        confrontationLevel = Double(profile.confrontationLevel)
        selectedModes = Set(profile.defaultModes)
    }

    private func saveProfile() {
        let savedModes = selectedModes.isEmpty ? [.blended] : Array(selectedModes)
        let current = TherapyRepository.currentProfile(in: modelContext)

        let profile = TherapyProfile(
            confrontationLevel: Int(confrontationLevel),
            defaultModes: savedModes,
            morningWindow: current.morningWindow,
            middayWindow: current.middayWindow,
            eveningWindow: current.eveningWindow
        )

        TherapyRepository.saveProfile(profile, in: modelContext)
        saveMessage = "Perfil terapêutico atualizado."
    }
}
