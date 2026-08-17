import SwiftUI
import SwiftData

struct ArticleDetailView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(StoreManager.self) private var store
    @Environment(\.modelContext) private var modelContext

    let articleID: String

    @State private var isBookmarked = false
    @State private var isCompleted = false
    @State private var showPaywall = false

    private var articles: ArticleRepository { ArticleRepository() }
    private var bookmarks: BookmarkRepository { BookmarkRepository(context: modelContext) }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        Group {
            if let article = articles.resolve(articleID, state: preferences.state, language: preferences.language) {
                let unlocked = store.canRead(article.meta)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        DestinationPhotoGallery(
                            imageNames: article.meta.images ?? [],
                            title: article.category == .explore
                                ? preferences.t("article.destination_photos")
                                : preferences.t("article.photos")
                        )

                        header(article)

                        if unlocked {
                            MarkdownDocumentView(markdown: article.markdown)
                                .font(.body)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            completeButton
                        } else {
                            lockedCard(article)
                        }

                        related(article)
                        DisclaimerBanner()
                    }
                    .padding()
                }
                .background(AppTheme.page.ignoresSafeArea())
                .navigationTitle(article.localizedTitle(for: preferences.language))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        ShareLink(
                            item: shareText(for: article),
                            subject: Text(article.localizedTitle(for: preferences.language))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(preferences.t("article.share"))

                        Button {
                            bookmarks.toggle(articleID)
                            isBookmarked = bookmarks.isBookmarked(articleID)
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        }
                        .accessibilityLabel(isBookmarked ? preferences.t("article.remove_bookmark") : preferences.t("article.save_bookmark"))
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView(highlightedArticleTitle: article.localizedTitle(for: preferences.language))
                }
                .onAppear {
                    isBookmarked = bookmarks.isBookmarked(articleID)
                    isCompleted = progress.isArticleCompleted(articleID)
                    progress.recordView(articleID: articleID)
                }
                .onChange(of: store.isPro) { _, _ in
                    showPaywall = false
                }
            } else {
                EmptyStateView(
                    symbol: "doc.questionmark",
                    title: preferences.t("article.unavailable_title"),
                    message: preferences.t("article.unavailable_body")
                )
            }
        }
    }

    private func header(_ article: ResolvedArticle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label(article.category.localizedName(for: preferences.language), systemImage: article.category.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(article.category.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(article.category.tint.opacity(0.14), in: Capsule())

                if article.meta.requiresPro {
                    ProBadge()
                }

                Spacer(minLength: 0)
            }

            Text(article.localizedTitle(for: preferences.language))
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.title)
                .fixedSize(horizontal: false, vertical: true)

            Text(article.localizedSubtitle(for: preferences.language))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                metaChip(symbol: "clock", text: preferences.t("common.min", article.meta.estimatedReadingMinutes))
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

    private var completeButton: some View {
        Button {
            progress.toggleArticleCompletion(articleID)
            isCompleted = progress.isArticleCompleted(articleID)
        } label: {
            Label(
                isCompleted ? preferences.t("article.completed") : preferences.t("article.mark_done"),
                systemImage: isCompleted ? "checkmark.circle.fill" : "circle"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(isCompleted ? AppTheme.brandGreen : .secondary)
        .accessibilityHint(preferences.t("article.mark_done_hint"))
    }

    private func lockedCard(_ article: ResolvedArticle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.brandGold)
            Text(preferences.t("pro.locked_title"))
                .font(.headline)
            Text(teaser(from: article.markdown))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(4)
            Button {
                showPaywall = true
            } label: {
                Text(preferences.t("pro.unlock_cta"))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.brandGreen)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func teaser(from markdown: String) -> String {
        markdown
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && !$0.hasPrefix("#") && !$0.hasPrefix("<!--") }
            ?? preferences.t("pro.locked_title")
    }

    private func shareText(for article: ResolvedArticle) -> String {
        """
        \(article.localizedTitle(for: preferences.language))
        \(article.localizedSubtitle(for: preferences.language))

        \(preferences.t("disclaimer.full"))
        """
    }

    private func related(_ article: ResolvedArticle) -> some View {
        let items = articles.related(to: article.id, state: preferences.state)
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: preferences.t("article.recommended"), subtitle: preferences.t("article.recommended_subtitle"))
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
