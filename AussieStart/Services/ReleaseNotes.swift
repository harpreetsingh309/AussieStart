import Foundation

/// Decides whether to show the What's New sheet.
///
/// Keyed on the app version rather than on `hasCompletedOnboarding`, so it
/// reaches people who already finished onboarding without re-running it. Two
/// rules keep it from ever ambushing the wrong person:
///
/// * Someone who has never opened the app before does not see it — they get
///   onboarding, which already covers this material.
/// * It shows at most once per version, and is marked seen the moment it
///   appears rather than when it is dismissed, so a crash or a force-quit
///   cannot make it reappear on every launch.
enum ReleaseNotes {
    private enum Keys {
        static let lastSeenVersion = "releaseNotes.lastSeenVersion"
    }

    /// Bumped by hand when a release has something worth announcing. Kept
    /// separate from CFBundleShortVersionString so a bugfix release does not
    /// interrupt everyone for nothing.
    static let currentNotesVersion = "1.1"

    static var lastSeenVersion: String? {
        UserDefaults.standard.string(forKey: Keys.lastSeenVersion)
    }

    /// True only for someone updating from an earlier version.
    static func shouldShow(hasCompletedOnboarding: Bool) -> Bool {
        guard !AppStoreScreenshotScene.isActive else { return false }
        guard hasCompletedOnboarding else { return false }
        return lastSeenVersion != currentNotesVersion
    }

    static func markSeen() {
        UserDefaults.standard.set(currentNotesVersion, forKey: Keys.lastSeenVersion)
    }

    /// Called when someone finishes onboarding, so a brand new person is never
    /// shown release notes for the version they just installed.
    static func markSeenForNewUser() {
        markSeen()
    }
}
