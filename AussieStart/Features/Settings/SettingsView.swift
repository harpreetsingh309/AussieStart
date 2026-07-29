import SwiftUI

struct SettingsView: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        @Bindable var preferences = preferences
        NavigationStack {
            Form {
                Section("Personalisation") {
                    Picker("Language", selection: $preferences.language) {
                        ForEach(AppLanguage.allCases.filter(\.isMVPReady)) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    Picker("State / Territory", selection: $preferences.state) {
                        ForEach(AustralianState.allCases) { state in
                            Text(state.displayName).tag(state)
                        }
                    }
                    Picker("I am a", selection: $preferences.persona) {
                        ForEach(UserPersona.allCases) { persona in
                            Text(persona.displayName).tag(persona)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $preferences.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(appearanceHint(for: preferences.appearance))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Offline") {
                    LabeledContent("Content pack", value: ContentLoader.shared.catalog.version)
                    LabeledContent("Last reviewed", value: ContentLoader.shared.catalog.lastReviewed)
                    Text("All guides, tips, and checklists ship inside the app. No account or internet required.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy") {
                    Toggle("Share anonymous usage (off by default)", isOn: $preferences.analyticsOptIn)
                    Text("AussieStart stores bookmarks and progress only on this device. No login. No cloud sync.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    NavigationLink("About AussieStart") { AboutView() }
                    NavigationLink("Checklists") { ChecklistView() }
                    NavigationLink("First 30 Days") { JourneyView() }
                    Link("Australian Government", destination: URL(string: "https://www.australia.gov.au")!)
                }

                Section {
                    Button("Replay onboarding", role: .destructive) {
                        preferences.resetOnboarding()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func appearanceHint(for mode: AppearanceMode) -> String {
        switch mode {
        case .system:
            "Matches your iPhone’s Light / Dark setting."
        case .light:
            "Always use a light background."
        case .dark:
            "Always use a dark background."
        }
    }
}
