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
                    Section(preferences.t("search.recent")) {
                        let recent = progress.recentSearches()
                        if recent.isEmpty {
                            Text(preferences.t("search.hint"))
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

                    Section(preferences.t("search.trending")) {
                        ForEach(articles.popular(state: preferences.state, persona: preferences.persona)) { article in
                            NavigationLink {
                                ArticleDetailView(articleID: article.id)
                            } label: {
                                ArticleRowView(article: article, showsChevron: false)
                            }
                        }
                    }
                } else {
                    Section(preferences.t("search.results")) {
                        if results.isEmpty {
                            Text(preferences.t("search.empty"))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(results) { hit in
                                NavigationLink {
                                    ArticleDetailView(articleID: hit.article.id)
                                } label: {
                                    ArticleRowView(article: hit.article, showsChevron: false)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(preferences.t("search.title"))
            .searchable(text: $query, prompt: preferences.t("search.prompt"))
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
        results = articles.search(query, state: preferences.state, language: preferences.language)
            .filter { $0.article.applies(to: preferences.persona) }
    }
}
