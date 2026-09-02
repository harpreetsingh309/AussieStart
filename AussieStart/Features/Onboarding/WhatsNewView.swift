import SwiftUI

/// A one-time, non-blocking summary of what changed in this release.
///
/// Shown to people who already completed onboarding, in place of re-running
/// it. Nothing here changes a setting on its own — each card offers a way to
/// go and change something, and dismissing it costs the person nothing.
struct WhatsNewView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    /// Set when the person taps through to a setting, so the caller can send
    /// them to the right place after the sheet closes.
    @Binding var destination: WhatsNewDestination?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    card(
                        symbol: "globe.asia.australia.fill",
                        title: preferences.t("whatsnew.languages_title"),
                        body: preferences.t("whatsnew.languages_body"),
                        action: preferences.t("whatsnew.languages_cta"),
                        destination: .language
                    )

                    card(
                        symbol: "books.vertical.fill",
                        title: preferences.t("whatsnew.culture_title"),
                        body: preferences.t("whatsnew.culture_body"),
                        action: preferences.t("whatsnew.culture_cta"),
                        destination: .culture
                    )

                    card(
                        symbol: "bell.badge.fill",
                        title: preferences.t("whatsnew.reminders_title"),
                        body: preferences.t("whatsnew.reminders_body"),
                        action: preferences.t("whatsnew.reminders_cta"),
                        destination: .settings
                    )

                    card(
                        symbol: "cart.fill",
                        title: preferences.t("whatsnew.rewards_title"),
                        body: preferences.t("whatsnew.rewards_body"),
                        action: nil,
                        destination: nil
                    )

                    acknowledgement
                }
                .padding()
            }
            .background(AppTheme.page.ignoresSafeArea())
            .navigationTitle(preferences.t("whatsnew.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(preferences.t("whatsnew.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(preferences.t("whatsnew.headline"))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.title)
            Text(preferences.t("whatsnew.subhead"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The Acknowledgement of Country was added to onboarding, so people who
    /// joined earlier would otherwise never see it. It sits here in full
    /// rather than as a one-line mention.
    private var acknowledgement: some View {
        AcknowledgementOfCountryCard(language: preferences.language)
    }

    @ViewBuilder
    private func card(
        symbol: String,
        title: String,
        body: String,
        action: String?,
        destination target: WhatsNewDestination?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(AppTheme.title)

            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let action, let target {
                Button(action) {
                    destination = target
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.brandGreen)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Where a What's New card sends the person once the sheet closes.
enum WhatsNewDestination: Hashable {
    case language
    case settings
    case culture
}
