import Foundation

@Observable
final class CelebrationService {
    private(set) var isShowingConfetti: Bool = false
    private var celebratedCounters: Set<UUID> = []

    func checkGoalReached(counter: Counter) -> Bool {
        guard let goal = counter.goal else { return false }
        guard counter.count >= goal else { return false }
        guard counter.count - counter.stepValue < goal else { return false }
        guard !celebratedCounters.contains(counter.id) else { return false }
        celebratedCounters.insert(counter.id)
        return true
    }

    func triggerConfetti() {
        isShowingConfetti = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            isShowingConfetti = false
        }
    }

    func resetCelebration(for counterId: UUID) {
        celebratedCounters.remove(counterId)
    }
}
