import SwiftUI
import SwiftData

struct CounterCard: View {
    @Bindable var counter: Counter
    @Environment(\.modelContext) private var modelContext
    @Environment(HapticService.self) private var haptics
    @Environment(UndoService.self) private var undoService
    @Environment(CelebrationService.self) private var celebration

    @State private var countScale: CGFloat = 1.0
    @State private var isPressed: Bool = false
    @State private var streak: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            countDisplay
            if counter.goal != nil { goalSection }
            if streak >= 2 { streakBadge }
            bottomRow
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16).fill(counter.color.color).frame(width: 4)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(duration: 0.2), value: isPressed)
        .onTapGesture { increment(by: counter.stepValue) }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in isPressed = pressing }, perform: {})
        .contextMenu {
            Button("+ \(counter.stepValue)") { increment(by: counter.stepValue) }
            Button("+ \(counter.stepValue * 5)") { increment(by: counter.stepValue * 5) }
            Button("+ \(counter.stepValue * 10)") { increment(by: counter.stepValue * 10) }
            Button("+ \(counter.stepValue * 25)") { increment(by: counter.stepValue * 25) }
        }
        .task { streak = loadStreak() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAction(named: "Increment") { increment(by: counter.stepValue) }
        .accessibilityAction(named: "Decrement") { decrement() }
    }

    private var headerRow: some View {
        HStack {
            Text(counter.name).font(.headline)
            Spacer()
            if counter.resetMode != .manual {
                Text(counter.resetMode.label)
                    .font(.caption).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(counter.color.color.opacity(0.15))
                    .foregroundStyle(counter.color.color)
                    .clipShape(Capsule())
            }
        }
    }

    private var countDisplay: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(counter.count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .scaleEffect(countScale)
                .animation(.spring(duration: 0.3, bounce: 0.4), value: countScale)
                .contentTransition(.numericText())
            if let goal = counter.goal {
                Text("/ \(goal)").font(.title3).foregroundStyle(.secondary)
            }
        }
    }

    private var goalSection: some View {
        ProgressBar(value: counter.count, goal: counter.goal!, color: counter.color.color)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text("\u{1F525}")
            Text("\(streak) day streak").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var bottomRow: some View {
        HStack {
            Button { decrement() } label: {
                Image(systemName: "minus.circle.fill").font(.title2).foregroundStyle(.secondary)
            }.buttonStyle(.plain)
            Spacer()
            Button { increment(by: counter.stepValue) } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(counter.color.color)
            }.buttonStyle(.plain)
            Spacer()
            Button { shareCounter() } label: {
                Image(systemName: "square.and.arrow.up").font(.title3).foregroundStyle(.secondary)
            }.buttonStyle(.plain)
        }
    }

    private func increment(by amount: Int) {
        undoService.record(counterId: counter.id, counterName: counter.name, previousCount: counter.count, delta: amount)
        withAnimation { counter.count += amount }
        countScale = 1.15
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            countScale = 1.0
        }
        haptics.lightImpact()
        saveTodayHistory()
        if celebration.checkGoalReached(counter: counter) {
            haptics.success()
            celebration.triggerConfetti()
        }
        streak = loadStreak()
    }

    private func decrement() {
        guard counter.count > 0 else { return }
        let amount = min(counter.stepValue, counter.count)
        undoService.record(counterId: counter.id, counterName: counter.name, previousCount: counter.count, delta: -amount)
        withAnimation { counter.count -= amount }
        haptics.lightImpact()
        saveTodayHistory()
        streak = loadStreak()
    }

    private func saveTodayHistory() {
        let today = Counter.todayString()
        let counterId = counter.id
        let descriptor = FetchDescriptor<DailyHistory>(
            predicate: #Predicate { $0.counterId == counterId && $0.date == today }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.total = counter.count
        } else {
            modelContext.insert(DailyHistory(counterId: counterId, date: today, total: counter.count))
        }
    }

    private func loadStreak() -> Int {
        let counterId = counter.id
        let descriptor = FetchDescriptor<DailyHistory>(
            predicate: #Predicate { $0.counterId == counterId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let history = (try? modelContext.fetch(descriptor)) ?? []
        return StreakService.calculateStreak(mode: counter.resetMode, history: history, currentDate: Counter.todayString(), currentCount: counter.count)
    }

    private func shareCounter() {
        // Placeholder — implemented in Task 14
    }

    private var accessibilityDescription: String {
        var parts = [counter.name, "\(counter.count)"]
        if let goal = counter.goal { parts.append("of \(goal)") }
        if counter.resetMode != .manual { parts.append("\(counter.resetMode.label) counter") }
        if streak >= 2 { parts.append("\(streak) day streak") }
        return parts.joined(separator: ", ")
    }
}
