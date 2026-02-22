import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = TodayViewModel()
    @State private var showRecordingSheet = false
    @State private var ringProgress: CGFloat = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PMDesign.spacingL) {
                    greetingHeader
                    progressRing
                    statPills
                    if !vm.todayMission.isEmpty {
                        missionCard
                    }
                    slotIndicator
                    quickActions
                    if let entry = vm.recentEntry {
                        recentEntryCard(entry)
                    }
                }
                .padding(.horizontal, PMDesign.spacingM)
                .padding(.bottom, PMDesign.spacingXL)
            }
            .background {
                ZStack {
                    PMDesign.background.opacity(0.85)
                    AnimatedMeshBackground()
                        .opacity(0.4)
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Hoje")
            .sheet(isPresented: $showRecordingSheet) {
                VoiceRecordingSheet()
            }
            .onChange(of: showRecordingSheet) { _, isShowing in
                if !isShowing { vm.load(modelContext: modelContext) }
            }
            .onAppear {
                vm.load(modelContext: modelContext)
                withAnimation(PMDesign.springGentle.delay(0.3)) {
                    ringProgress = vm.completionRate
                }
            }
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vm.greeting)
                .font(PMDesign.largeTitleRounded)
                .foregroundStyle(PMDesign.textPrimary)

            Text(Date.now, format: .dateTime.weekday(.wide).day().month())
                .font(PMDesign.subheadlineRounded)
                .foregroundStyle(PMDesign.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, PMDesign.spacingS)
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(PMDesign.textTertiary.opacity(0.15), lineWidth: 10)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(PMDesign.brandGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(ringProgress * 100))")
                    .font(PMDesign.heroNumber)
                    .foregroundStyle(PMDesign.textPrimary)
                    .contentTransition(.numericText())

                Text("% concluido")
                    .font(PMDesign.caption2Rounded)
                    .foregroundStyle(PMDesign.textTertiary)
            }
        }
        .frame(width: 160, height: 160)
    }

    // MARK: - Stat Pills

    private var statPills: some View {
        HStack(spacing: PMDesign.spacingS) {
            statPill(
                icon: "book.fill",
                value: "\(vm.todayEntryCount)",
                label: vm.todayEntryCount == 1 ? "entrada" : "entradas",
                color: PMDesign.brandSecondary
            )

            statPill(
                icon: "checkmark.seal.fill",
                value: "\(vm.completedCount)/\(vm.totalCount)",
                label: "compromissos",
                color: PMDesign.success
            )

            statPill(
                icon: vm.hasReview ? "checkmark.circle.fill" : "circle",
                value: vm.hasReview ? "Feita" : "Pendente",
                label: "revisao",
                color: vm.hasReview ? PMDesign.success : PMDesign.textTertiary
            )
        }
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        GlassCard(cornerRadius: PMDesign.cornerSmall, padding: PMDesign.spacingS) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(PMDesign.headlineRounded)
                    .foregroundStyle(PMDesign.textPrimary)
                Text(label)
                    .font(PMDesign.caption2Rounded)
                    .foregroundStyle(PMDesign.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Mission Card

    private var missionCard: some View {
        GlassCard(glowColor: PMDesign.accentGold, glowOpacity: 0.4) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundStyle(PMDesign.accentGold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Missao do Dia")
                        .font(PMDesign.captionRounded)
                        .foregroundStyle(PMDesign.accentGold)
                    Text(vm.todayMission)
                        .font(PMDesign.subheadlineRounded)
                        .foregroundStyle(PMDesign.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Slot Indicator

    private var slotIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: slotIcon)
                .symbolEffect(.pulse)
                .foregroundStyle(PMDesign.brandPrimary)

            Text(vm.currentSlot.title)
                .font(PMDesign.captionRounded)
                .foregroundStyle(PMDesign.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var slotIcon: String {
        switch vm.currentSlot {
        case .morning: return "sun.max.fill"
        case .midday: return "sun.min.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: PMDesign.spacingS) {
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showRecordingSheet = true
            } label: {
                GlassCard(padding: PMDesign.spacingM) {
                    VStack(spacing: 10) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundStyle(PMDesign.brandPrimary)
                        Text("Gravar\nPensamento")
                            .font(PMDesign.captionRounded)
                            .foregroundStyle(PMDesign.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80)
                }
            }
            .buttonStyle(PressScaleButtonStyle())

            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                NotificationCenter.default.post(name: .switchToTab, object: 2)
            } label: {
                GlassCard(padding: PMDesign.spacingM) {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(PMDesign.accentGold)
                        Text("Iniciar\nRitual")
                            .font(PMDesign.captionRounded)
                            .foregroundStyle(PMDesign.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 80)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    // MARK: - Recent Entry

    private func recentEntryCard(_ entry: JournalEntryEntity) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Ultima entrada", systemImage: "book.fill")
                        .font(PMDesign.captionRounded)
                        .foregroundStyle(PMDesign.textSecondary)
                    Spacer()
                    Text(entry.createdAt, format: .dateTime.hour().minute())
                        .font(PMDesign.caption2Rounded)
                        .foregroundStyle(PMDesign.textTertiary)
                }

                Text(entry.transcribedText)
                    .font(.subheadline)
                    .foregroundStyle(PMDesign.textPrimary)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Notification for tab switching

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}
