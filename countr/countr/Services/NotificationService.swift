import UserNotifications
import SwiftData

enum NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    static func scheduleReminder(for counter: Counter) {
        let center = UNUserNotificationCenter.current()
        let identifier = "reminder-\(counter.id.uuidString)"
        guard let timeStr = counter.reminderTime else { return }
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return }

        let content = UNMutableNotificationContent()
        content.title = counter.name
        content.body = "You haven't logged \(counter.name) today. Tap to open countr."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = parts[0]
        dateComponents.minute = parts[1]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelReminder(for counter: Counter) {
        let identifier = "reminder-\(counter.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func rescheduleAll(counters: [Counter]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for counter in counters where counter.reminderTime != nil {
            if counter.count == 0 { scheduleReminder(for: counter) }
        }
    }
}
