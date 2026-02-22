import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("openAIKey") private var openAIKey = ""

    @State private var confrontationLevel: Double = 4
    @State private var selectedModes: Set<InterventionMode> = [.blended]
    @State private var profileLoaded = false
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PMDesign.spacingL) {
                    avatarSection
                    apiKeySection
                    therapyProfileSection
                    saveSection
                    aboutSection
                }
                .padding(.horizontal, PMDesign.spacingM)
                .padding(.bottom, PMDesign.spacingXL)
            }
            .background(PMDesign.background)
            .navigationTitle("Perfil")
            .onAppear {
                if !profileLoaded {
                    loadProfile()
                    profileLoaded = true
                }
            }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PMDesign.brandGradient)
                    .frame(width: 80, height: 80)

                Text("PM")
                    .font(PMDesign.title2)
                    .foregroundStyle(.white)
            }
            .softShadow(radius: 12, color: PMDesign.brandPrimary.opacity(0.3))

            Text("PocketMind")
                .font(PMDesign.headlineRounded)
                .foregroundStyle(PMDesign.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, PMDesign.spacingS)
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Chave OpenAI", systemImage: "key.fill")
                        .font(PMDesign.captionRounded)
                        .foregroundStyle(PMDesign.textSecondary)

                    Spacer()

                    // Status indicator
                    Circle()
                        .fill(openAIKey.isEmpty ? PMDesign.danger : PMDesign.success)
                        .frame(width: 8, height: 8)
                    Text(openAIKey.isEmpty ? "Ausente" : "Configurada")
                        .font(PMDesign.caption2Rounded)
                        .foregroundStyle(openAIKey.isEmpty ? PMDesign.danger : PMDesign.success)
                }

                SecureField("sk-...", text: $openAIKey)
                    .font(.subheadline)
                    .padding(PMDesign.spacingS)
                    .background(PMDesign.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))

                Text("Sua chave fica salva apenas no dispositivo.")
                    .font(PMDesign.caption2Rounded)
                    .foregroundStyle(PMDesign.textTertiary)
            }
        }
    }

    // MARK: - Therapy Profile

    private var therapyProfileSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PMDesign.spacingM) {
                Label("Perfil Terapeutico", systemImage: "brain.head.profile")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.textSecondary)

                // Confrontation slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Nivel de Confrontacao")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(confrontationLevel))/5")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PMDesign.brandPrimary)
                    }

                    Slider(value: $confrontationLevel, in: 1...5, step: 1)
                        .tint(PMDesign.brandPrimary)

                    HStack {
                        Text("Gentil")
                            .font(PMDesign.caption2Rounded)
                            .foregroundStyle(PMDesign.textTertiary)
                        Spacer()
                        Text("Confrontador")
                            .font(PMDesign.caption2Rounded)
                            .foregroundStyle(PMDesign.textTertiary)
                    }
                }

                Divider()

                // Intervention modes
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
                    .tint(PMDesign.brandPrimary)
                }
            }
        }
    }

    // MARK: - Save

    private var saveSection: some View {
        GlassButton(title: saved ? "Salvo!" : "Salvar Perfil", icon: saved ? "checkmark.circle.fill" : "checkmark.circle", style: .primary) {
            saveProfile()
            withAnimation(PMDesign.springSnappy) {
                saved = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation { saved = false }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Sobre", systemImage: "info.circle")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.textSecondary)

                HStack {
                    Text("Versao")
                        .font(.subheadline)
                        .foregroundStyle(PMDesign.textPrimary)
                    Spacer()
                    Text("2.1")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PMDesign.brandPrimary)
                }
            }
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        let profile = TherapyRepository.currentProfile(in: modelContext)
        confrontationLevel = Double(profile.confrontationLevel)
        selectedModes = Set(profile.defaultModes)
    }

    private func saveProfile() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

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
