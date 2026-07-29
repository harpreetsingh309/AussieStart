import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var results: [SearchHit] = []

    private var articles: ArticleRepository { ArticleRepository() }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Recent searches") {
                        let recent = progress.recentSearches()
                        if recent.isEmpty {
                            Text("Try “GP”, “TFN”, or “Myki”")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(recent, id: \.query) { item in
                                Button(item.query) {
                                    query = item.query
                                    runSearch()
                                }
                            }
                        }
                    }

                    Section("Trending") {
                        ForEach(articles.popular(state: preferences.state)) { article in
                            NavigationLink {
                                ArticleDetailView(articleID: article.id)
                            } label: {
                                ArticleRowView(article: article)
                            }
                        }
                    }
                } else {
                    Section("Results") {
                        if results.isEmpty {
                            Text("No matches. Try a synonym like “doctor” for GP.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(results) { hit in
                                NavigationLink {
                                    ArticleDetailView(articleID: hit.article.id)
                                } label: {
                                    ArticleRowView(article: hit.article)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Search guides")
            .onChange(of: query) { _, _ in
                runSearch()
            }
            .onSubmit(of: .search) {
                progress.saveSearch(query)
                runSearch()
            }
        }
    }

    private func runSearch() {
        results = articles.search(query, state: preferences.state)
    }
}
