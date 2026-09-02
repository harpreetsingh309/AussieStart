import Foundation
import UserNotifications

/// Per-task reminders set by the user.
///
/// Kept in UserDefaults rather than SwiftData deliberately: adding a model to
/// the existing schema risks a migration failure, and `AussieStartApp` responds
/// to that by deleting the store — which would take the person's bookmarks and
/// progress with it. This is a handful of dates, so the risk is not worth it.
@MainActor
@Observable
final class TaskReminderStore {
    static let shared = TaskReminderStore()

    static let idPrefix = "aussiestart.task."
    private let key = "taskReminders"

    private(set) var reminders: [String: Date] = [:]

    private init() {
        if let raw = UserDefaults.standard.dictionary(forKey: key) as? [String: Date] {
            reminders = raw
        }
        pruneExpired()
    }

    func date(for taskID: String) -> Date? { reminders[taskID] }

    func hasReminder(for taskID: String) -> Bool { reminders[taskID] != nil }

    /// Schedules (or reschedules) a reminder. Returns false when notification
    /// permission is unavailable, so the caller can explain why nothing happened.
    @discardableResult
    func set(_ date: Date, for taskID: String, title: String, body: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard await DailyTipScheduler.ensureAuthorised(center) else { return false }
        guard date > .now else { return false }

        center.removePendingNotificationRequests(withIdentifiers: [Self.idPrefix + taskID])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["taskID": taskID]

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: Self.idPrefix + taskID,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            return false
        }

        reminders[taskID] = date
        persist()
        return true
    }

    func clear(_ taskID: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.idPrefix + taskID])
        reminders.removeValue(forKey: taskID)
        persist()
    }

    /// Drops reminders whose time has passed so the badge state stays honest.
    func pruneExpired() {
        let stale = reminders.filter { $0.value <= .now }.map(\.key)
        guard !stale.isEmpty else { return }
        for id in stale { reminders.removeValue(forKey: id) }
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(reminders, forKey: key)
    }
}
