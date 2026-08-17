import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkRecord.dateSaved, order: .reverse) private var bookmarks: [BookmarkRecord]
    @Query(sort: \RecentViewRecord.viewedAt, order: .reverse) private var history: [RecentViewRecord]

    private var articles: ArticleRepository { ArticleRepository() }

    var body: some View {
        NavigationStack {
            List {
                Section(preferences.t("saved.articles")) {
                    if bookmarks.isEmpty {
                        Text(preferences.t("saved.empty"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(bookmarks, id: \.articleID) { bookmark in
                            if let meta = articles.catalog.articles.first(where: { $0.id == bookmark.articleID }) {
                                NavigationLink {
                                    ArticleDetailView(articleID: meta.id)
                                } label: {
                                    ArticleRowView(article: meta, showsChevron: false)
                                }
                            }
                        }
                    }
                }

                Section(preferences.t("saved.history")) {
                    if history.isEmpty {
                        Text(preferences.t("saved.history_empty"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(history.prefix(20), id: \.articleID) { item in
                            if let meta = articles.catalog.articles.first(where: { $0.id == item.articleID }) {
                                NavigationLink {
                                    ArticleDetailView(articleID: meta.id)
                                } label: {
                                    ArticleRowView(article: meta, showsChevron: false)
                                }
                            }
                        }
                    }
                }

                Section {
                    NavigationLink(preferences.t("saved.checklists")) { ChecklistView() }
                    NavigationLink(preferences.t("saved.journey")) { JourneyView() }
                }
            }
            .navigationTitle(preferences.t("saved.title"))
        }
    }
}
