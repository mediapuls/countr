import Foundation

struct UndoEntry {
    let counterId: UUID
    let counterName: String
    let previousCount: Int
    let delta: Int
    let timestamp: Date
}

@Observable
final class UndoService {
    private(set) var lastEntry: UndoEntry?
    private(set) var showToast: Bool = false
    private(set) var toastMessage: String = ""

    private let expirationInterval: TimeInterval = 30

    func record(counterId: UUID, counterName: String, previousCount: Int, delta: Int) {
        lastEntry = UndoEntry(
            counterId: counterId,
            counterName: counterName,
            previousCount: previousCount,
            delta: delta,
            timestamp: Date()
        )
    }

    func undo() -> UndoEntry? {
        guard let entry = lastEntry,
              Date().timeIntervalSince(entry.timestamp) < expirationInterval else {
            lastEntry = nil
            return nil
        }
        let undone = entry
        lastEntry = nil
        let sign = undone.delta > 0 ? "+" : ""
        toastMessage = "Undid \(sign)\(undone.delta) on \(undone.counterName)"
        showToast = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            showToast = false
        }
        return undone
    }

    func dismissToast() {
        showToast = false
    }
}
