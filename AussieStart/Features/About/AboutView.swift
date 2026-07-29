import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("AussieStart")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.title)
                Text("The complete Australia starter guide in your pocket — built local-first for new migrants.")
                    .foregroundStyle(.secondary)

                Group {
                    labeled("Version", ContentLoader.shared.catalog.version)
                    labeled("Content reviewed", ContentLoader.shared.catalog.lastReviewed)
                    labeled("Architecture", "SwiftUI · MVVM · SwiftData · Offline Markdown")
                }

                DisclaimerBanner()

                Text("Always verify critical steps with official sources such as Services Australia, the ATO, state transport agencies, and your local council.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body)
        }
    }
}
