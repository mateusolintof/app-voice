import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("openAIKey") private var openAIKey = ""

    @State private var confrontationLevel: Double = 4
    @State private var selectedModes: Set<InterventionMode> = [.blended]
    @State private var profileLoaded = false

    var body: some View {
        NavigationStack {
            List {
                // API Keys
                Section {
                    SecureField("sk-...", text: $openAIKey)
                        .font(.subheadline)
                } header: {
                    Label("Chave OpenAI", systemImage: "key.fill")
                } footer: {
                    Text("Sua chave fica salva apenas no dispositivo.")
                        .font(.caption2)
                }

                // Therapy Profile
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Nivel de Confrontacao")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(confrontationLevel))/5")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PMDesign.accent)
                        }

                        Slider(value: $confrontationLevel, in: 1...5, step: 1)
                            .tint(PMDesign.accent)

                        Text("Nivel 1: gentil e encorajador. Nivel 5: direto e confrontador.")
                            .font(.caption2)
                            .foregroundStyle(PMDesign.textTertiary)
                    }

                    ForEach(InterventionMode.allCases) { mode in
                        Toggle(isOn: Binding(
                            get: { selectedModes.contains(mode) },
                            set: { isOn in
                                if isOn {
                                    selectedModes.insert(mode)
                                } else if selectedModes.count > 1 {
                                    selectedModes.remove(mode)
                                }
                            }
                        )) {
                            Text(mode.title)
                                .font(.subheadline)
                        }
                        .tint(PMDesign.accent)
                    }
                } header: {
                    Label("Perfil Terapeutico", systemImage: "brain.head.profile")
                }

                // Save
                Section {
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Salvar Perfil", systemImage: "checkmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PMDesign.accent)
                            Spacer()
                        }
                    }
                }

                // About
                Section {
                    LabeledContent("Versao", value: "2.0")
                        .font(.subheadline)
                } header: {
                    Label("Sobre", systemImage: "info.circle")
                }
            }
            .navigationTitle("Perfil")
            .onAppear {
                if !profileLoaded {
                    loadProfile()
                    profileLoaded = true
                }
            }
        }
    }

    private func loadProfile() {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        confrontationLevel = Double(profile.confrontationLevel)
        selectedModes = Set(profile.defaultModes)
    }

    private func saveProfile() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let profile = TherapyProfile(
            confrontationLevel: Int(confrontationLevel),
            defaultModes: Array(selectedModes),
            morningWindow: DateInterval(
                start: calendar.date(byAdding: .hour, value: 7, to: startOfDay) ?? startOfDay,
                end: calendar.date(byAdding: .hour, value: 11, to: startOfDay) ?? startOfDay
            ),
            middayWindow: DateInterval(
                start: calendar.date(byAdding: .hour, value: 12, to: startOfDay) ?? startOfDay,
                end: calendar.date(byAdding: .hour, value: 15, to: startOfDay) ?? startOfDay
            ),
            eveningWindow: DateInterval(
                start: calendar.date(byAdding: .hour, value: 19, to: startOfDay) ?? startOfDay,
                end: calendar.date(byAdding: .hour, value: 22, to: startOfDay) ?? startOfDay
            )
        )

        TherapyRepository.saveProfile(profile, in: modelContext)
    }
}
