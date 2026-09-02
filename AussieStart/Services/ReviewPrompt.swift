import Foundation

/// Decides when to ask for an App Store rating.
///
/// Apple allows at most three prompts per user per 365 days and the system
/// silently swallows the rest, so each one has to be spent well. The rules
/// here follow Apple's guidance: only after the person has actually got value
/// from the app, never on the first day, never twice for the same version, and
/// never in response to a button the user pressed.
enum ReviewPrompt {
    private enum Keys {
        static let firstLaunch = "review.firstLaunchDate"
        static let readGuides = "review.readGuideIDs"
        static let lastVersion = "review.lastPromptedVersion"
        static let lastDate = "review.lastPromptedDate"
    }

    /// Ask once the person has read at least this many distinct guides.
    /// Deliberately a floor rather than an exact match: if the moment is missed
    /// (the reader closes the guide before the delay elapses) the next guide
    /// still qualifies, instead of the milestone being silently consumed.
    static let readGuidesThreshold = 3
    /// Never on day one — a prompt then reads as pushy and buys a low rating.
    static let minimumDaysInstalled = 2
    /// Well inside Apple's 365-day window, so we never burn all three at once.
    static let cooldownDays = 120

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// Call once per launch.
    static func registerLaunch() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Keys.firstLaunch) == nil {
            defaults.set(Date.now, forKey: Keys.firstLaunch)
        }
    }

    /// Records that a guide was actually read (not merely locked behind a
    /// paywall) and reports whether this is a good moment to ask.
    @discardableResult
    static func recordGuideRead(_ articleID: String) -> Bool {
        let defaults = UserDefaults.standard
        var ids = Set(defaults.stringArray(forKey: Keys.readGuides) ?? [])
        let isNew = ids.insert(articleID).inserted
        if isNew {
            defaults.set(Array(ids), forKey: Keys.readGuides)
        }
        return shouldPrompt(readCount: ids.count)
    }

    static var readGuideCount: Int {
        (UserDefaults.standard.stringArray(forKey: Keys.readGuides) ?? []).count
    }

    static func shouldPrompt(readCount: Int = readGuideCount) -> Bool {
        guard !AppStoreScreenshotScene.isActive else { return false }

        let defaults = UserDefaults.standard

        // Only once the app has demonstrably been useful.
        guard readCount >= readGuidesThreshold else { return false }

        // Not for a version we already asked about.
        if defaults.string(forKey: Keys.lastVersion) == currentVersion { return false }

        // Not before the app has had a chance to prove itself.
        guard let installed = defaults.object(forKey: Keys.firstLaunch) as? Date,
              daysBetween(installed, .now) >= minimumDaysInstalled
        else { return false }

        // Not inside the cooldown.
        if let last = defaults.object(forKey: Keys.lastDate) as? Date,
           daysBetween(last, .now) < cooldownDays {
            return false
        }

        return true
    }

    static func markPrompted() {
        let defaults = UserDefaults.standard
        defaults.set(currentVersion, forKey: Keys.lastVersion)
        defaults.set(Date.now, forKey: Keys.lastDate)
    }

    private static func daysBetween(_ a: Date, _ b: Date) -> Int {
        Calendar.current.dateComponents([.day], from: a, to: b).day ?? 0
    }
}
