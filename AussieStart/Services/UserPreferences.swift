import Foundation
import SwiftUI

@Observable
final class UserPreferences {
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let language = "appLanguage"
        static let state = "australianState"
        static let persona = "userPersona"
        static let appearance = "appearanceMode"
        static let journeyReminders = "journeyRemindersEnabled"
        static let dailyTip = "dailyTipEnabled"
        static let dailyTipHour = "dailyTipHour"
        static let dailyTipMinute = "dailyTipMinute"
    }

    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Keys.language) }
    }

    var state: AustralianState {
        didSet { UserDefaults.standard.set(state.rawValue, forKey: Keys.state) }
    }

    var persona: UserPersona {
        didSet { UserDefaults.standard.set(persona.rawValue, forKey: Keys.persona) }
    }

    var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    var journeyRemindersEnabled: Bool {
        didSet { UserDefaults.standard.set(journeyRemindersEnabled, forKey: Keys.journeyReminders) }
    }

    /// Free, opt-in, off by default.
    var dailyTipEnabled: Bool {
        didSet { UserDefaults.standard.set(dailyTipEnabled, forKey: Keys.dailyTip) }
    }

    /// The time of day the tip fires, stored as components so it survives
    /// timezone changes — a migrant moving Perth to Sydney still gets 6pm local.
    var dailyTipHour: Int {
        didSet { UserDefaults.standard.set(dailyTipHour, forKey: Keys.dailyTipHour) }
    }

    var dailyTipMinute: Int {
        didSet { UserDefaults.standard.set(dailyTipMinute, forKey: Keys.dailyTipMinute) }
    }

    /// Bridges the stored components to a `Date` for `DatePicker`.
    var dailyTipTime: Date {
        get {
            var comps = DateComponents()
            comps.hour = dailyTipHour
            comps.minute = dailyTipMinute
            return Calendar.current.date(from: comps) ?? .now
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            dailyTipHour = comps.hour ?? DailyTipScheduler.defaultHour
            dailyTipMinute = comps.minute ?? DailyTipScheduler.defaultMinute
        }
    }

    init() {
        let defaults = UserDefaults.standard
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english
        state = AustralianState(rawValue: defaults.string(forKey: Keys.state) ?? "") ?? .vic
        persona = UserPersona(rawValue: defaults.string(forKey: Keys.persona) ?? "") ?? .student
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        journeyRemindersEnabled = defaults.bool(forKey: Keys.journeyReminders)
        dailyTipEnabled = defaults.bool(forKey: Keys.dailyTip)
        dailyTipHour = defaults.object(forKey: Keys.dailyTipHour) as? Int ?? DailyTipScheduler.defaultHour
        dailyTipMinute = defaults.object(forKey: Keys.dailyTipMinute) as? Int ?? DailyTipScheduler.defaultMinute
        if AppStoreScreenshotScene.isActive {
            language = .english
            state = .vic
            persona = .student
            appearance = .light
            hasCompletedOnboarding = true
            dailyTipEnabled = false
        }
    }

    func completeOnboarding(language: AppLanguage, state: AustralianState, persona: UserPersona) {
        self.language = language
        self.state = state
        self.persona = persona
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
