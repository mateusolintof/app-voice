import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = OnboardingViewModel()
    @Binding var isCompleted: Bool

    var body: some View {
        ZStack {
            PMDesign.background.ignoresSafeArea()
            AnimatedMeshBackground()
                .opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.top, PMDesign.spacingM)

                // Content
                TabView(selection: $vm.currentStep) {
                    welcomeStep.tag(0)
                    nameStep.tag(1)
                    apiKeyStep.tag(2)
                    personalizationStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(PMDesign.springSnappy, value: vm.currentStep)

                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, PMDesign.spacingM)
                    .padding(.bottom, PMDesign.spacingXL)
            }
        }
        .alert("Erro", isPresented: .init(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<vm.totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= vm.currentStep ? PMDesign.brandPrimary : PMDesign.textTertiary.opacity(0.2))
                    .frame(height: 4)
                    .animation(PMDesign.springSnappy, value: vm.currentStep)
            }
        }
        .padding(.horizontal, PMDesign.spacingM)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(PMDesign.brandGradient)
                    .frame(width: 100, height: 100)
                    .softShadow(radius: 20, color: PMDesign.brandPrimary.opacity(0.3))

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text("PocketMind")
                    .font(PMDesign.largeTitleRounded)
                    .foregroundStyle(PMDesign.textPrimary)

                Text("Seu coach pessoal com IA")
                    .font(PMDesign.subheadlineRounded)
                    .foregroundStyle(PMDesign.textSecondary)

                Text("Terapia cognitiva, estoicismo e logoterapia\nna palma da sua mao.")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.textTertiary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, PMDesign.spacingM)
    }

    // MARK: - Step 1: Name

    private var nameStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(PMDesign.brandPrimary)

            VStack(spacing: 8) {
                Text("Como posso te chamar?")
                    .font(PMDesign.title3)
                    .foregroundStyle(PMDesign.textPrimary)

                Text("Seu nome aparecera nas saudacoes diarias.")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.textTertiary)
            }

            TextField("Seu nome", text: $vm.userName)
                .font(PMDesign.headlineRounded)
                .multilineTextAlignment(.center)
                .padding(PMDesign.spacingM)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))
                .padding(.horizontal, PMDesign.spacingXL)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, PMDesign.spacingM)
    }

    // MARK: - Step 2: API Key

    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundStyle(PMDesign.accentGold)

            VStack(spacing: 8) {
                Text("Chave OpenAI")
                    .font(PMDesign.title3)
                    .foregroundStyle(PMDesign.textPrimary)

                Text("O PocketMind usa a API da OpenAI para funcionar.\nVoce precisara de uma chave de API.")
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.textTertiary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                SecureField("sk-...", text: $vm.apiKey)
                    .font(.subheadline)
                    .padding(PMDesign.spacingM)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerMedium, style: .continuous))

                Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Obter chave em platform.openai.com")
                    }
                    .font(PMDesign.captionRounded)
                    .foregroundStyle(PMDesign.brandPrimary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption2)
                    Text("Sua chave fica salva apenas no dispositivo.")
                        .font(PMDesign.caption2Rounded)
                }
                .foregroundStyle(PMDesign.textTertiary)
            }
            .padding(.horizontal, PMDesign.spacingS)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, PMDesign.spacingM)
    }

    // MARK: - Step 3: Personalization

    private var personalizationStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 40))
                    .foregroundStyle(PMDesign.brandSecondary)
                    .padding(.top, PMDesign.spacingXL)

                VStack(spacing: 8) {
                    Text("Personalize seu coach")
                        .font(PMDesign.title3)
                        .foregroundStyle(PMDesign.textPrimary)

                    Text("Ajuste o estilo do coach para seu perfil.")
                        .font(PMDesign.captionRounded)
                        .foregroundStyle(PMDesign.textTertiary)
                }

                // Confrontation slider
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Nivel de Confrontacao")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(vm.confrontationLevel))/5")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PMDesign.brandPrimary)
                        }

                        Slider(value: $vm.confrontationLevel, in: 1...5, step: 1)
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
                }

                // Initial thought
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sua primeira reflexao", systemImage: "text.bubble.fill")
                            .font(PMDesign.captionRounded)
                            .foregroundStyle(PMDesign.brandPrimary)

                        Text("Compartilhe algo que esta pensando ou sentindo. A IA vai gerar sua primeira missao.")
                            .font(PMDesign.caption2Rounded)
                            .foregroundStyle(PMDesign.textTertiary)

                        TextEditor(text: $vm.initialThought)
                            .font(.body)
                            .frame(minHeight: 100)
                            .padding(PMDesign.spacingS)
                            .background(PMDesign.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, PMDesign.spacingM)
            .padding(.bottom, 100) // Space for bottom button
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if vm.currentStep > 0 {
                GlassButton(title: "Voltar", icon: "chevron.left", style: .secondary) {
                    withAnimation(PMDesign.springSnappy) {
                        vm.previousStep()
                    }
                }
            }

            if vm.isLastStep {
                GlassButton(
                    title: vm.isProcessing ? "Preparando..." : "Comecar",
                    icon: vm.isProcessing ? "arrow.clockwise" : "sparkles",
                    style: .primary,
                    isLoading: vm.isProcessing
                ) {
                    Task {
                        await vm.completeOnboarding(modelContext: modelContext)
                        withAnimation(PMDesign.springGentle) {
                            isCompleted = true
                        }
                    }
                }
            } else {
                GlassButton(
                    title: vm.currentStep == 2 && vm.apiKey.isEmpty ? "Pular" : "Continuar",
                    icon: "chevron.right",
                    style: .primary
                ) {
                    withAnimation(PMDesign.springSnappy) {
                        vm.nextStep()
                    }
                }
                .disabled(!vm.canProceed)
                .opacity(vm.canProceed ? 1 : 0.5)
            }
        }
    }
}
