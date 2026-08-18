import SwiftUI

struct SettingsView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(StoreManager.self) private var store
    @State private var showPaywall = false

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
                    .onChange(of: preferences.language) { _, language in
                        guard store.isPro, preferences.journeyRemindersEnabled else { return }
                        Task {
                            await JourneyReminderScheduler.sync(enabled: true, language: language)
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

                Section(preferences.t("pro.title")) {
                    if store.isPro {
                        Label(preferences.t("pro.active"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(AppTheme.brandGreen)
                        Toggle(preferences.t("pro.reminders"), isOn: $preferences.journeyRemindersEnabled)
                            .onChange(of: preferences.journeyRemindersEnabled) { _, enabled in
                                Task {
                                    await JourneyReminderScheduler.sync(
                                        enabled: enabled,
                                        language: preferences.language
                                    )
                                }
                            }
                        Text(preferences.t("pro.reminders_blurb"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label(preferences.t("pro.unlock_cta"), systemImage: "star.circle.fill")
                        }
                    }
                    Button(preferences.t("pro.restore")) {
                        Task { await store.restore() }
                    }
                    Text(preferences.t("pro.settings_blurb"))
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
                    NavigationLink(preferences.t("privacy.title")) { PrivacyPolicyView() }
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}
