import SwiftUI

@Observable
final class HapticService {
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "haptic_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "haptic_enabled") }
    }

    init() {
        if !UserDefaults.standard.contains(key: "haptic_enabled") {
            UserDefaults.standard.set(true, forKey: "haptic_enabled")
        }
    }

    func lightImpact() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func mediumImpact() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        object(forKey: key) != nil
    }
}
