import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(UndoService.self) private var undoService
    @Environment(HapticService.self) private var haptics

    @Query(sort: \Counter.order) private var counters: [Counter]
    @Query(sort: \CounterGroup.order) private var groups: [CounterGroup]

    @State private var showCreateSheet = false
    @State private var counterToEdit: Counter?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if counters.isEmpty {
                        emptyState
                    } else {
                        counterList
                    }
                }
                createButton
                if undoService.showToast {
                    VStack {
                        ToastView(message: undoService.toastMessage)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 8)
                        Spacer()
                    }
                    .animation(.spring(duration: 0.3), value: undoService.showToast)
                }
            }
            .navigationTitle("countr")
            .onShake { performUndo() }
            .sheet(isPresented: $showCreateSheet) { CreateCounterSheet() }
            .sheet(item: $counterToEdit) { counter in EditCounterSheet(counter: counter) }
        }
    }

    private var counterList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(ungroupedCounters) { counter in counterRow(counter) }
                ForEach(groups) { group in
                    let groupCounters = group.counters.sorted { $0.order < $1.order }
                    if !groupCounters.isEmpty {
                        GroupHeader(group: group)
                        if group.isExpanded {
                            ForEach(groupCounters) { counter in
                                counterRow(counter)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 80)
        }
    }

    private func counterRow(_ counter: Counter) -> some View {
        CounterCard(counter: counter)
            .overlay(alignment: .topTrailing) {
                Button {
                    counterToEdit = counter
                } label: {
                    Image(systemName: "ellipsis").font(.body).foregroundStyle(.secondary).padding(12)
                }
                .buttonStyle(.plain)
            }
    }

    private var ungroupedCounters: [Counter] {
        counters.filter { $0.group == nil }.sorted { $0.order < $1.order }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "number.circle").font(.system(size: 64)).foregroundStyle(.secondary)
            Text("No counters yet").font(.headline)
            Text("Tap + to create your first counter").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var createButton: some View {
        Button {
            showCreateSheet = true
            haptics.lightImpact()
        } label: {
            Image(systemName: "plus").font(.title2).fontWeight(.semibold).foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(.blue))
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .padding(24)
    }

    private func performUndo() {
        guard let entry = undoService.undo() else { return }
        if let counter = counters.first(where: { $0.id == entry.counterId }) {
            withAnimation { counter.count = entry.previousCount }
            haptics.mediumImpact()
        }
    }
}
