import SwiftUI
import SwiftData

struct JourneyView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @State private var completed: Set<String> = []
    @State private var showPaywall = false

    private var catalog: ContentCatalog { ContentLoader.shared.catalog }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        let days = catalog.journey.filter { $0.applies(to: preferences.persona) }.sorted { $0.day < $1.day }
        let doneCount = days.filter { completed.contains($0.id) }.count
        let ratio = days.isEmpty ? 0 : Double(doneCount) / Double(days.count)

        List {
            Section {
                HStack(spacing: 16) {
                    ProgressRing(progress: ratio)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preferences.t("journey.completed", doneCount, days.count))
                            .font(.headline)
                        Text(preferences.t("journey.subtitle", preferences.state.localizedName(for: preferences.language)))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            ForEach(grouped(days), id: \.week) { group in
                Section(preferences.t("journey.week", group.week)) {
                    ForEach(group.days) { day in
                        dayRow(day)
                    }
                }
            }
        }
        .navigationTitle(preferences.t("journey.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.isPro {
                    ShareLink(item: shareText(days: days)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(preferences.t("journey.share"))
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(preferences.t("journey.share_pro"))
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear { completed = progress.completedDayIDs() }
    }

    private func shareText(days: [JourneyDayMeta]) -> String {
        let lines = days.map { day in
            let mark = completed.contains(day.id) ? "✓" : "○"
            return "\(mark) \(preferences.t("journey.day", day.day, day.localizedTitle(for: preferences.language)))"
        }
        return ([preferences.t("journey.share_header", preferences.state.localizedName(for: preferences.language))] + lines + [preferences.t("disclaimer.full")]).joined(separator: "\n")
    }

    private func dayRow(_ day: JourneyDayMeta) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                progress.toggleDay(day.id)
                completed = progress.completedDayIDs()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: completed.contains(day.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(completed.contains(day.id) ? AppTheme.brandGreen : .secondary)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(preferences.t("journey.day", day.day, day.localizedTitle(for: preferences.language)))
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .strikethrough(completed.contains(day.id))
                            if day.requiresPro {
                                ProBadge()
                            }
                        }
                        Text(day.localizedSummary(for: preferences.language))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            ForEach(day.articleIDs, id: \.self) { articleID in
                if let meta = catalog.articles.first(where: { $0.id == articleID }) {
                    NavigationLink {
                        ArticleDetailView(articleID: articleID)
                    } label: {
                        Label(meta.localizedTitle(for: preferences.language), systemImage: meta.category.symbolName)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private struct WeekGroup {
        let week: Int
        let days: [JourneyDayMeta]
    }

    private func grouped(_ days: [JourneyDayMeta]) -> [WeekGroup] {
        Dictionary(grouping: days, by: \.week)
            .map { WeekGroup(week: $0.key, days: $0.value.sorted { $0.day < $1.day }) }
            .sorted { $0.week < $1.week }
    }
}
