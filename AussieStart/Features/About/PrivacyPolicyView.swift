import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(preferences.t("privacy.title"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.title)
                Text(preferences.t("privacy.updated"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                group(preferences.t("privacy.collect_title"), preferences.t("privacy.collect_body"))
                group(preferences.t("privacy.purchases_title"), preferences.t("privacy.purchases_body"))
                group(preferences.t("privacy.notgov_title"), preferences.t("privacy.notgov_body"))
                group(preferences.t("privacy.contact_title"), preferences.t("privacy.contact_body"))

                DisclaimerBanner()
            }
            .padding()
        }
        .navigationTitle(preferences.t("privacy.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func group(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
