import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = JournalViewModel()
    @State private var showRecordingSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if vm.filteredEntries.isEmpty {
                    emptyState
                } else {
                    entryList
                }

                RecordFloatingButton {
                    showRecordingSheet = true
                }
                .padding(.bottom, PMDesign.spacingL)
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

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: PMDesign.spacingM, pinnedViews: .sectionHeaders) {
                ForEach(vm.groupedEntries, id: \.0) { section, entries in
                    Section {
                        ForEach(entries) { entry in
                            NavigationLink(value: entry.id) {
                                JournalEntryCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    vm.deleteEntry(id: entry.id, modelContext: modelContext)
                                } label: {
                                    Label("Apagar", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(section)
                                .font(.caption.weight(.semibold))
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 56))
                .foregroundStyle(PMDesign.subtleGradient)

            Text("Toque no microfone para\nregistrar seu primeiro pensamento")
                .font(.subheadline)
                .foregroundStyle(PMDesign.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
