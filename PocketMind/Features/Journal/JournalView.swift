import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = JournalViewModel()
    @State private var showRecordingSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                switch vm.loadingState {
                case .idle, .loading:
                    skeletonView
                case .loaded where vm.filteredEntries.isEmpty:
                    emptyState
                case .loaded:
                    entryList
                case .error(let msg):
                    errorView(msg)
                }

                RecordFloatingButton {
                    showRecordingSheet = true
                }
                .padding(.bottom, PMDesign.spacingL)

                // Undo snackbar
                if vm.showUndoSnackbar {
                    undoSnackbar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 90)
                }
            }
            .background(PMDesign.background)
            .navigationTitle("Diario")
            .searchable(text: $vm.searchText, prompt: "Buscar entradas...")
            .sheet(isPresented: $showRecordingSheet) {
                VoiceRecordingSheet()
            }
            .onChange(of: showRecordingSheet) { _, isShowing in
                if !isShowing {
                    vm.loadEntries(modelContext: modelContext)
                }
            }
            .onAppear {
                vm.loadEntries(modelContext: modelContext)
            }
        }
    }

    // MARK: - Skeleton Loading

    private var skeletonView: some View {
        ScrollView {
            LazyVStack(spacing: PMDesign.spacingM) {
                ForEach(0..<3, id: \.self) { _ in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(PMDesign.textTertiary.opacity(0.15))
                                .frame(width: 80, height: 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(PMDesign.textTertiary.opacity(0.15))
                                .frame(height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(PMDesign.textTertiary.opacity(0.15))
                                .frame(width: 200, height: 14)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .shimmer()
                }
            }
            .padding(.horizontal, PMDesign.spacingM)
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: PMDesign.spacingM, pinnedViews: .sectionHeaders) {
                ForEach(vm.groupedEntries, id: \.0) { section, entries in
                    Section {
                        ForEach(entries) { entry in
                            NavigationLink(value: entry.id) {
                                JournalEntryCard(entry: entry)
                            }
                            .buttonStyle(PressScaleButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    withAnimation(PMDesign.springSnappy) {
                                        vm.deleteEntry(id: entry.id, modelContext: modelContext)
                                    }
                                } label: {
                                    Label("Apagar", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(section)
                                .font(PMDesign.caption2Rounded)
                                .foregroundStyle(PMDesign.textSecondary)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.horizontal, PMDesign.spacingS)
                        .padding(.vertical, PMDesign.spacingXS)
                        .background(PMDesign.background.opacity(0.9))
                    }
                }
            }
            .padding(.horizontal, PMDesign.spacingM)
            .padding(.bottom, 100)
        }
        .navigationDestination(for: UUID.self) { entryId in
            if let entry = vm.entries.first(where: { $0.id == entryId }) {
                JournalEntryDetailView(entry: entry)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 56))
                .foregroundStyle(PMDesign.brandPrimary.opacity(0.4))
                .symbolEffect(.pulse)

            Text("Toque no microfone para\nregistrar seu primeiro pensamento")
                .font(PMDesign.subheadlineRounded)
                .foregroundStyle(PMDesign.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(PMDesign.warning)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PMDesign.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Undo Snackbar

    private var undoSnackbar: some View {
        HStack {
            Text("Entrada apagada")
                .font(PMDesign.captionRounded)
                .foregroundStyle(PMDesign.textPrimary)
            Spacer()
            Button("Desfazer") {
                withAnimation(PMDesign.springSnappy) {
                    vm.undoDelete(modelContext: modelContext)
                }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(PMDesign.brandPrimary)
        }
        .padding(.horizontal, PMDesign.spacingM)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal, PMDesign.spacingL)
        .softShadow()
    }
}
