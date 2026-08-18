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

    init() {
        let defaults = UserDefaults.standard
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        language = AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .english
        state = AustralianState(rawValue: defaults.string(forKey: Keys.state) ?? "") ?? .vic
        persona = UserPersona(rawValue: defaults.string(forKey: Keys.persona) ?? "") ?? .student
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        journeyRemindersEnabled = defaults.bool(forKey: Keys.journeyReminders)
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
