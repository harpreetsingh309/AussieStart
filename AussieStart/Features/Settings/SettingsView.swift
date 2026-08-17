import SwiftUI

struct SettingsView: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences
        NavigationStack {
            Form {
                Section(preferences.t("settings.personalisation")) {
                    Picker(preferences.t("settings.language"), selection: $preferences.language) {
                        ForEach(AppLanguage.allCases.filter(\.isMVPReady)) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    Text(preferences.t("settings.language_note"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Picker(preferences.t("settings.state"), selection: $preferences.state) {
                        ForEach(AustralianState.allCases) { state in
                            Text(state.localizedName(for: preferences.language)).tag(state)
                        }
                    }
                    Picker(preferences.t("settings.persona"), selection: $preferences.persona) {
                        ForEach(UserPersona.allCases) { persona in
                            Text(persona.localizedName(for: preferences.language)).tag(persona)
                        }
                    }
                }

                Section(preferences.t("settings.appearance")) {
                    Picker(preferences.t("settings.theme"), selection: $preferences.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.localizedName(for: preferences.language)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(preferences.t(preferences.appearance.hintKey))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(preferences.t("settings.offline")) {
                    LabeledContent(preferences.t("settings.content_pack"), value: ContentLoader.shared.catalog.version)
                    LabeledContent(preferences.t("settings.last_reviewed"), value: ContentLoader.shared.catalog.lastReviewed)
                    Text(preferences.t("settings.offline_blurb"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(preferences.t("settings.privacy")) {
                    Toggle(preferences.t("settings.analytics"), isOn: $preferences.analyticsOptIn)
                    Text(preferences.t("settings.privacy_blurb"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(preferences.t("settings.about")) {
                    NavigationLink(preferences.t("settings.about_app")) { AboutView() }
                    NavigationLink(preferences.t("saved.checklists")) { ChecklistView() }
                    NavigationLink(preferences.t("saved.journey")) { JourneyView() }
                    Link(preferences.t("settings.aus_gov"), destination: URL(string: "https://www.australia.gov.au")!)
                }

                Section {
                    Button(preferences.t("settings.replay_onboarding"), role: .destructive) {
                        preferences.resetOnboarding()
                    }
                }
            }
            .navigationTitle(preferences.t("settings.title"))
        }
    }
}
