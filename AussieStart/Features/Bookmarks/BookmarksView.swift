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
                Section("Saved articles") {
                    if bookmarks.isEmpty {
                        Text("Bookmark guides to read offline later.")
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

                Section("History") {
                    if history.isEmpty {
                        Text("Articles you open will appear here.")
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
                    NavigationLink("Checklists") { ChecklistView() }
                    NavigationLink("First 30 Days") { JourneyView() }
                }
            }
            .navigationTitle("Saved")
        }
    }
}
