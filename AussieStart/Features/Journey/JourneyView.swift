import SwiftUI
import SwiftData

struct JourneyView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var completed: Set<String> = []

    private var catalog: ContentCatalog { ContentLoader.shared.catalog }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        let days = catalog.journey.sorted { $0.day < $1.day }
        let doneCount = days.filter { completed.contains($0.id) }.count
        let ratio = days.isEmpty ? 0 : Double(doneCount) / Double(days.count)

        List {
            Section {
                HStack(spacing: 16) {
                    ProgressRing(progress: ratio)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(doneCount)/\(days.count) completed")
                            .font(.headline)
                        Text("A practical roadmap for your first month in \(preferences.state.displayName).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            ForEach(grouped(days), id: \.week) { group in
                Section("Week \(group.week)") {
                    ForEach(group.days) { day in
                        dayRow(day)
                    }
                }
            }
        }
        .navigationTitle("First 30 Days")
        .onAppear { completed = progress.completedDayIDs() }
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
                        Text("Day \(day.day): \(day.title)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .strikethrough(completed.contains(day.id))
                        Text(day.summary)
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
                        Label(meta.title, systemImage: meta.category.symbolName)
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
