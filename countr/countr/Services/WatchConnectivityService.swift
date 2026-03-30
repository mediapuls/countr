#if canImport(WatchConnectivity)
import WatchConnectivity
#endif
import SwiftData

final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    override init() {
        super.init()
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        #endif
    }

    func sendCounterData(context: ModelContext) {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported(),
              WCSession.default.isReachable else { return }

        let descriptor = FetchDescriptor<Counter>(sortBy: [SortDescriptor(\Counter.order)])
        guard let counters = try? context.fetch(descriptor) else { return }

        let data = counters.map { counter in
            WidgetCounterData(
                id: counter.id,
                name: counter.name,
                count: counter.count,
                goal: counter.goal,
                colorName: counter.color.rawValue,
                resetMode: counter.resetMode.rawValue
            )
        }

        guard let jsonData = try? JSONEncoder().encode(data),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        WCSession.default.sendMessage(["counters": jsonString], replyHandler: nil)
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {}
}
#endif
