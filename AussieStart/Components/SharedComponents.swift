import SwiftUI
import UIKit

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
                Text(article.localizedTitle(for: preferences.language))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
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
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.card)
        )
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
