import WatchConnectivity
import SwiftUI

@Observable
final class WatchDataService: NSObject, WCSessionDelegate {
    var counters: [WidgetCounterData] = []

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        loadFromUserDefaults()
    }

    func loadFromUserDefaults() {
        guard let defaults = UserDefaults(suiteName: WidgetCounterData.suiteName),
              let data = defaults.data(forKey: WidgetCounterData.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([WidgetCounterData].self, from: data) else { return }
        counters = decoded
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let jsonString = message["counters"] as? String,
           let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WidgetCounterData].self, from: data) {
            Task { @MainActor in
                self.counters = decoded
            }
        }
    }
}
