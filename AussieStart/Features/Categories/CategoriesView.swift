import SwiftUI

struct CategoriesView: View {
    @Environment(UserPreferences.self) private var preferences

    private var articles: ArticleRepository { ArticleRepository() }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ContentCategory.allCases) { category in
                        let count = articles.articles(in: category, state: preferences.state).count
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            CategoryTile(category: category, count: count)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(AppTheme.page)
            .navigationTitle("Topics")
        }
    }
}

struct CategoryDetailView: View {
    @Environment(UserPreferences.self) private var preferences
    let category: ContentCategory

    private var articles: ArticleRepository { ArticleRepository() }

    var body: some View {
        List {
            ForEach(articles.articles(in: category, state: preferences.state)) { article in
                NavigationLink {
                    ArticleDetailView(articleID: article.id)
                } label: {
                    ArticleRowView(article: article)
                }
            }
        }
        .navigationTitle(category.displayName)
    }
}
