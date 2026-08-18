import Foundation
import UserNotifications

enum JourneyReminderScheduler {
    static let idPrefix = "aussiestart.journey."

    static func sync(enabled: Bool, language: AppLanguage) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: (1...4).map { "\(idPrefix)\($0)" }
        )
        guard enabled else { return }

        let granted: Bool
        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return
        }
        guard granted else { return }

        let titles = [
            L10n.tr("reminder.week1.title", language: language),
            L10n.tr("reminder.week2.title", language: language),
            L10n.tr("reminder.week3.title", language: language),
            L10n.tr("reminder.week4.title", language: language)
        ]
        let bodies = [
            L10n.tr("reminder.week1.body", language: language),
            L10n.tr("reminder.week2.body", language: language),
            L10n.tr("reminder.week3.body", language: language),
            L10n.tr("reminder.week4.body", language: language)
        ]

        for week in 1...4 {
            guard let fire = Calendar.current.date(byAdding: .day, value: week * 7, to: .now) else { continue }
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: fire)
            comps.hour = 9
            comps.minute = 0

            let content = UNMutableNotificationContent()
            content.title = titles[week - 1]
            content.body = bodies[week - 1]
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(idPrefix)\(week)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
            try? await center.add(request)
        }
    }
}
