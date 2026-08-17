import SwiftUI

struct AboutView: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(preferences.t("app.name"))
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.title)
                Text(preferences.t("about.blurb"))
                    .foregroundStyle(.secondary)

                Group {
                    labeled(preferences.t("about.version"), ContentLoader.shared.catalog.version)
                    labeled(preferences.t("about.content_reviewed"), ContentLoader.shared.catalog.lastReviewed)
                    labeled(preferences.t("about.architecture"), "SwiftUI · MVVM · SwiftData · Offline Markdown")
                }

                DisclaimerBanner()

                Text(preferences.t("about.verify"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(preferences.t("about.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
        }
    }
}
