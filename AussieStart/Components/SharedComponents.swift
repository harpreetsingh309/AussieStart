import SwiftUI
import UIKit

struct SectionLabel: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.brandGreen)
                .frame(width: 5, height: 5)
            Text(text.uppercased())
                .font(AppTheme.sectionLabelFont)
                .foregroundStyle(AppTheme.brandGreen)
                .tracking(0.6)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var label: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                SectionLabel(text: label)
            }
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.title)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

struct HomeSearchBar: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        NavigationLink {
            SearchView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.brandGreen)
                Text(preferences.t("search.prompt"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.card, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(AppTheme.mist, lineWidth: 1)
            }
            .modifier(CardShadow(radius: 6, y: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preferences.t("search.title"))
    }
}

struct PrimaryPillButton: View {
    let title: String
    var showsArrow: Bool = true
    var style: Style = .onDark

    enum Style {
        case onDark, onLight
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.bold))
            if showsArrow {
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(style == .onDark ? AppTheme.brandGreen : .white)
                    .frame(width: 26, height: 26)
                    .background(style == .onDark ? .white : AppTheme.brandGreen, in: Circle())
            }
        }
        .foregroundStyle(style == .onDark ? AppTheme.title : AppTheme.brandGreen)
        .padding(.leading, 16)
        .padding(.trailing, showsArrow ? 6 : 16)
        .padding(.vertical, 6)
        .background(style == .onDark ? .white : AppTheme.mist, in: Capsule())
    }
}

struct JourneyProgressCard: View {
    @Environment(UserPreferences.self) private var preferences
    let progress: Double
    let completed: Int
    let total: Int
    let currentWeek: Int

    var body: some View {
        HStack(spacing: 16) {
            ProgressRing(progress: progress, lineWidth: 7)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preferences.t("home.first_30_days"))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.title)
                    Spacer(minLength: 0)
                    Text(preferences.t("home.journey_week", currentWeek))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.brandGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.mist, in: Capsule())
                }

                Text(preferences.t("home.milestones_completed", completed, total))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                SegmentedProgressBar(progress: progress)
            }
        }
        .padding(AppTheme.Layout.cardPadding)
        .elevatedCard(AppTheme.Layout.cardRadius)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.brandGreen, AppTheme.brandGold],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 12)
        }
    }
}

struct SegmentedProgressBar: View {
    let progress: Double
    var style: Style = .onLight
    private let segments = 5

    enum Style {
        case onLight, onDark
    }

    private var filledColor: Color {
        style == .onDark ? .white : AppTheme.brandGreen
    }

    private var emptyColor: Color {
        style == .onDark ? .white.opacity(0.22) : AppTheme.mist
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<segments, id: \.self) { index in
                let threshold = Double(index + 1) / Double(segments)
                Capsule()
                    .fill(progress >= threshold ? filledColor : emptyColor)
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }
}

struct QuickTopicChip: View {
    let category: ContentCategory
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(category.tint, in: Circle())
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.title)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(AppTheme.card, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(category.tint.opacity(0.2), lineWidth: 1)
        }
        .modifier(CardShadow(radius: 6, y: 3))
    }
}

struct ImageOverlayCard: View {
    let imageName: String?
    let fallbackSymbol: String
    let fallbackColors: [Color]
    let title: String
    let subtitle: String
    let footer: String
    var width: CGFloat = 240

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    } else {
                        LinearGradient(
                            colors: fallbackColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .overlay {
                            Image(systemName: fallbackSymbol)
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                }
                .frame(height: 148)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.72)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(footer)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(14)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppTheme.Layout.cardRadius,
                    topTrailingRadius: AppTheme.Layout.cardRadius,
                    style: .continuous
                )
            )

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .frame(width: width, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius, style: .continuous))
        .modifier(CardShadow(radius: 10, y: 5))
    }
}

struct ArticleRowView: View {
    @Environment(UserPreferences.self) private var preferences
    let article: ArticleMeta
    /// Hide when used inside a `List` `NavigationLink` (system already shows a chevron).
    var showsChevron: Bool = true
    var cardStyle: Bool = false
    /// Prefer first destination photo as the leading thumbnail when available.
    var prefersPhotoThumbnail: Bool = true

    private var thumbnailName: String? {
        guard prefersPhotoThumbnail else { return nil }
        return (article.images ?? []).first(where: { UIImage(named: $0) != nil })
    }

    var body: some View {
        HStack(spacing: 14) {
            if let thumbnailName {
                Image(thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: article.category.symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(article.category.tint)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [article.category.tint.opacity(0.22), article.category.tint.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(article.localizedTitle(for: preferences.language))
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if article.requiresPro {
                        ProBadge()
                    }
                }
                Text(article.localizedSubtitle(for: preferences.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(preferences.t("common.min_category", article.estimatedReadingMinutes, article.category.localizedName(for: preferences.language)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(article.category.tint.opacity(0.9))
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(cardStyle ? 14 : 0)
        .padding(.vertical, cardStyle ? 0 : 4)
        .background {
            if cardStyle {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.card)
                    .modifier(CardShadow(radius: 8, y: 4))
            }
        }
        .contentShape(Rectangle())
    }
}

struct CategoryTile: View {
    @Environment(UserPreferences.self) private var preferences
    let category: ContentCategory
    var count: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [category.tint.opacity(0.35), category.tint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 6)

            VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: category.symbolName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [category.tint, category.tint.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                Spacer(minLength: 0)
                if let count {
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(category.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(category.tint.opacity(0.15), in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.localizedName(for: preferences.language))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.title)
                Text(count == 0 ? preferences.t("common.coming_soon") : preferences.t("common.guides_count", count ?? 0))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [category.tint.opacity(0.35), category.tint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .modifier(CardShadow(radius: 8, y: 4))
    }
}

struct ProgressRing: View {
    @Environment(UserPreferences.self) private var preferences
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.mist, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.brandGreen, AppTheme.brandGold, AppTheme.brandGreen],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.title)
        }
        .accessibilityLabel(preferences.t("common.progress_percent", Int((progress * 100).rounded())))
    }
}

struct DisclaimerBanner: View {
    @Environment(UserPreferences.self) private var preferences

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppTheme.brandGreen)
            Text(preferences.t("disclaimer.full"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        }
    }
}

struct SoftCardBackground: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.card)
            )
    }
}

extension View {
    func softCard(_ cornerRadius: CGFloat = 18) -> some View {
        modifier(SoftCardBackground(cornerRadius: cornerRadius))
    }
}
