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
                    VStack(alignment: .leading, spacing: 20) {
                        DestinationPhotoGallery(
                            imageNames: article.meta.images ?? [],
                            title: article.category == .explore ? "Destination photos" : "Photos"
                        )

                        header(article)

                        MarkdownDocumentView(markdown: article.markdown)
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                        related(article)
                        DisclaimerBanner()
                    }
                    .padding()
                }
                .background(AppTheme.page.ignoresSafeArea())
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label(article.category.displayName, systemImage: article.category.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(article.category.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(article.category.tint.opacity(0.14), in: Capsule())

                Spacer(minLength: 0)
            }

            Text(article.title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.title)
                .fixedSize(horizontal: false, vertical: true)

            Text(article.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                metaChip(symbol: "clock", text: "\(article.meta.estimatedReadingMinutes) min")
                metaChip(symbol: "mappin.and.ellipse", text: preferences.state.shortName)
                metaChip(symbol: "calendar", text: article.meta.lastUpdated)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [article.category.tint.opacity(0.16), AppTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private func metaChip(symbol: String, text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.elevated.opacity(0.9), in: Capsule())
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
                            ArticleRowView(article: item, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}
