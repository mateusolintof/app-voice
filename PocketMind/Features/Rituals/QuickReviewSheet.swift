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
    @State private var saved = false

    let completionRate: Double

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PMDesign.spacingL) {
                    // Completion circle
                    ZStack {
                        Circle()
                            .stroke(PMDesign.textTertiary.opacity(0.2), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: completionRate)
                            .stroke(PMDesign.brandGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.8), value: completionRate)

                        VStack(spacing: 2) {
                            Text("\(Int(completionRate * 100))%")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(PMDesign.textPrimary)
                            Text("concluido")
                                .font(.caption2)
                                .foregroundStyle(PMDesign.textTertiary)
                        }
                    }
                    .frame(width: 120, height: 120)

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
                            color: PMDesign.accent,
                            placeholder: "O que voce aprendeu hoje?",
                            text: $lesson
                        )

                        inputField(
                            title: "Ajuste para amanha",
                            icon: "arrow.forward.circle.fill",
                            color: PMDesign.accentSecondary,
                            placeholder: "O que mudar amanha?",
                            text: $adjustment
                        )

                        // Consistency slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Consistencia", systemImage: "chart.bar.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PMDesign.textSecondary)
                                Spacer()
                                Text("\(Int(consistencyScore))/5")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(PMDesign.accent)
                            }

                            Slider(value: $consistencyScore, in: 1...5, step: 1)
                                .tint(PMDesign.accent)
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            TextField(placeholder, text: text, axis: .vertical)
                .font(.subheadline)
                .padding(PMDesign.spacingS)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: PMDesign.cornerSmall, style: .continuous))
        }
    }

    private func saveReview() {
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
