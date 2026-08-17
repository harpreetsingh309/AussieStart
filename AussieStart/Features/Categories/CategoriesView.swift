import SwiftUI

struct CategoriesView: View {
    @Environment(UserPreferences.self) private var preferences
    @State private var appear = false

    private var articles: ArticleRepository { ArticleRepository() }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preferences.t("topics.browse"))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(AppTheme.title)
                        Text(preferences.t("topics.tailored", preferences.state.shortName))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(ContentCategory.allCases.enumerated()), id: \.element.id) { index, category in
                            let count = articles.articles(in: category, state: preferences.state).count
                            NavigationLink {
                                CategoryDetailView(category: category)
                            } label: {
                                CategoryTile(category: category, count: count)
                            }
                            .buttonStyle(.plain)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 12)
                            .animation(
                                .spring(response: 0.45, dampingFraction: 0.85).delay(Double(index) * 0.03),
                                value: appear
                            )
                        }
                    }
                }
                .padding()
            }
            .background {
                LinearGradient(
                    colors: [AppTheme.mist.opacity(0.55), AppTheme.page],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle(preferences.t("topics.title"))
            .onAppear { appear = true }
        }
    }
}

struct CategoryDetailView: View {
    @Environment(UserPreferences.self) private var preferences
    let category: ContentCategory

    private var articles: ArticleRepository { ArticleRepository() }

    private var items: [ArticleMeta] {
        articles.articles(in: category, state: preferences.state)
    }

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyStateView(
                    symbol: category.symbolName,
                    title: preferences.t("empty.no_guides_title"),
                    message: preferences.t("empty.no_guides_body", category.localizedName(for: preferences.language))
                )
            } else {
                List {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: category.symbolName)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(category.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preferences.t("common.guides_count", items.count))
                                    .font(.headline)
                                Text(preferences.t("common.offline_for_state", preferences.state.shortName))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(category.tint.opacity(0.08))
                    }

                    Section(preferences.t("topics.guides")) {
                        ForEach(items) { article in
                            NavigationLink {
                                ArticleDetailView(articleID: article.id)
                            } label: {
                                ArticleRowView(article: article, showsChevron: false)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(category.localizedName(for: preferences.language))
    }
}
