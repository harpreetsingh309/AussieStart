import SwiftUI
import SwiftData

struct ArticleDetailView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext

    let articleID: String

    @State private var isBookmarked = false

    private var articles: ArticleRepository { ArticleRepository() }
    private var bookmarks: BookmarkRepository { BookmarkRepository(context: modelContext) }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        Group {
            if let article = articles.resolve(articleID, state: preferences.state) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header(article)
                        MarkdownDocumentView(markdown: article.markdown)
                        related(article)
                        DisclaimerBanner()
                    }
                    .padding()
                }
                .navigationTitle(article.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            bookmarks.toggle(articleID)
                            isBookmarked = bookmarks.isBookmarked(articleID)
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        }
                        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Save bookmark")
                    }
                }
                .onAppear {
                    isBookmarked = bookmarks.isBookmarked(articleID)
                    progress.recordView(articleID: articleID)
                }
            } else {
                EmptyStateView(
                    symbol: "doc.questionmark",
                    title: "Article unavailable",
                    message: "This guide is not in the offline pack yet."
                )
            }
        }
    }

    private func header(_ article: ResolvedArticle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(article.category.displayName, systemImage: article.category.symbolName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(article.category.tint)
            Text(article.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Label("\(article.meta.estimatedReadingMinutes) min", systemImage: "clock")
                Label(preferences.state.shortName, systemImage: "mappin.and.ellipse")
                Label("Updated \(article.meta.lastUpdated)", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func related(_ article: ResolvedArticle) -> some View {
        let items = articles.related(to: article.id, state: preferences.state)
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Recommended next", subtitle: "Keep your settlement flow going")
                    ForEach(items) { item in
                        NavigationLink {
                            ArticleDetailView(articleID: item.id)
                        } label: {
                            ArticleRowView(article: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}
