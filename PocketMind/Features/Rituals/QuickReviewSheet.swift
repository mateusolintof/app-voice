import SwiftUI
import SwiftData

struct QuickReviewSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var winsInput = ""
    @State private var frictionsInput = ""
    @State private var lesson = ""
    @State private var adjustment = ""
    @State private var consistencyScore: Double = 3
    @State private var ringProgress: CGFloat = 0

    let completionRate: Double

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PMDesign.spacingL) {
                    // Completion circle
                    ZStack {
                        Circle()
                            .stroke(PMDesign.textTertiary.opacity(0.15), lineWidth: 10)

                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(PMDesign.brandGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(Int(ringProgress * 100))%")
                                .font(PMDesign.title2)
                                .foregroundStyle(PMDesign.textPrimary)
                                .contentTransition(.numericText())
                            Text("concluido")
                                .font(PMDesign.caption2Rounded)
                                .foregroundStyle(PMDesign.textTertiary)
                        }
                    }
                    .frame(width: 130, height: 130)
                    .onAppear {
                        withAnimation(PMDesign.springGentle.delay(0.3)) {
                            ringProgress = completionRate
                        }
                    }

                    // Input fields
                    VStack(alignment: .leading, spacing: PMDesign.spacingM) {
                        inputField(
                            title: "Vitorias",
                            icon: "trophy.fill",
                            color: PMDesign.success,
                            placeholder: "Separe por virgula...",
                            text: $winsInput
                        )

                        inputField(
                            title: "Fricoes",
                            icon: "exclamationmark.triangle.fill",
                            color: PMDesign.warning,
                            placeholder: "Separe por virgula...",
                            text: $frictionsInput
                        )

                        inputField(
                            title: "Licao do dia",
                            icon: "lightbulb.fill",
                            color: PMDesign.brandPrimary,
                            placeholder: "O que voce aprendeu hoje?",
                            text: $lesson
                        )

                        inputField(
                            title: "Ajuste para amanha",
                            icon: "arrow.forward.circle.fill",
                            color: PMDesign.brandTertiary,
                            placeholder: "O que mudar amanha?",
                            text: $adjustment
                        )

                        // Consistency slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Consistencia", systemImage: "chart.bar.fill")
                                    .font(PMDesign.captionRounded)
                                    .foregroundStyle(PMDesign.textSecondary)
                                Spacer()
                                Text("\(Int(consistencyScore))/5")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(PMDesign.brandPrimary)
                            }

                            Slider(value: $consistencyScore, in: 1...5, step: 1)
                                .tint(PMDesign.brandPrimary)
                        }
                    }

                    GlassButton(title: "Salvar Revisao", icon: "checkmark.circle", style: .primary) {
                        saveReview()
                    }
                }
                .padding(PMDesign.spacingM)
            }
            .background(PMDesign.background)
            .navigationTitle("Revisao do Dia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func inputField(
        title: String,
        icon: String,
        color: Color,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(PMDesign.captionRounded)
                .foregroundStyle(color)

            TextField(placeholder, text: text, axis: .vertical)
                .font(.subheadline)
                .padding(PMDesign.spacingS)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
        }
    }

    private func saveReview() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        let wins = winsInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let frictions = frictionsInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        TherapyRepository.saveReview(
            date: Date(),
            wins: wins,
            frictions: frictions,
            lesson: lesson,
            adjustment: adjustment,
            consistencyScore: Int(consistencyScore),
            in: modelContext
        )

        TherapyRepository.logMetric(
            name: "daily_review_saved",
            value: consistencyScore,
            context: Date.now.formatted(date: .abbreviated, time: .omitted),
            in: modelContext
        )

        dismiss()
    }
}
