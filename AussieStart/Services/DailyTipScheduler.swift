import Foundation
import UserNotifications

/// Opt-in daily settlement tip.
///
/// A local notification carries fixed content decided when it is scheduled, so
/// there is no way to pick a random tip at fire time. Instead a shuffled run of
/// tips is scheduled `horizonDays` ahead and topped up every time the app is
/// opened, which keeps the sequence varied without repeating inside a cycle.
enum DailyTipScheduler {
    static let idPrefix = "aussiestart.dailytip."

    /// iOS caps an app at 64 pending notifications. Fourteen leaves plenty of
    /// room for the four First 30 Days reminders and any task reminders.
    static let horizonDays = 14

    static let defaultHour = 18
    static let defaultMinute = 0

    static func sync(enabled: Bool, hour: Int, minute: Int, language: AppLanguage) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: (0..<horizonDays).map { "\(idPrefix)\($0)" }
        )
        guard enabled else { return }
        guard await ensureAuthorised(center) else { return }

        let tips = ContentLoader.shared.catalog.tips
        guard !tips.isEmpty else { return }

        let calendar = Calendar.current
        var bag: [DailyTipMeta] = []
        var scheduled = 0
        var dayOffset = 0

        // Walk forward day by day, skipping today if the chosen time has passed.
        while scheduled < horizonDays, dayOffset < horizonDays + 1 {
            defer { dayOffset += 1 }

            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: .now) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            guard let fireDate = calendar.date(from: comps), fireDate > .now else { continue }

            if bag.isEmpty { bag = tips.shuffled() }
            let tip = bag.removeFirst()

            let content = UNMutableNotificationContent()
            content.title = tip.localizedTitle(for: language)
            content.body = tip.localizedDescription(for: language)
            content.sound = .default
            if let articleID = tip.articleID {
                content.userInfo = ["articleID": articleID]
            }

            let request = UNNotificationRequest(
                identifier: "\(idPrefix)\(scheduled)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            )
            try? await center.add(request)
            scheduled += 1
        }
    }

    /// Asks for permission only the first time. Never re-prompts a user who
    /// has already declined — iOS would ignore it anyway.
    static func ensureAuthorised(_ center: UNUserNotificationCenter = .current()) async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }
}
