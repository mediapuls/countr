import ActivityKit
import Foundation

@Observable
final class LiveActivityService {
    private(set) var activeCounterId: UUID?

    func startTracking(counter: Counter) {
        // End any existing activity first
        endTracking()

        let attributes = CountrActivityAttributes(
            counterName: counter.name,
            goal: counter.goal,
            colorName: counter.color.rawValue
        )
        let state = CountrActivityAttributes.ContentState(count: counter.count)
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            _ = try Activity.request(attributes: attributes, content: content)
            activeCounterId = counter.id
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }

    func updateCount(_ count: Int) {
        let state = CountrActivityAttributes.ContentState(count: count)
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            for activity in Activity<CountrActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }

    func endTracking() {
        activeCounterId = nil
        Task {
            for activity in Activity<CountrActivityAttributes>.activities {
                let state = activity.content.state
                let content = ActivityContent(state: state, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }

    var isTracking: Bool {
        activeCounterId != nil
    }

    func isTrackingCounter(_ id: UUID) -> Bool {
        activeCounterId == id
    }
}
