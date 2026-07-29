import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
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
    let article: ArticleMeta

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: article.category.symbolName)
                .font(.title3)
                .foregroundStyle(article.category.tint)
                .frame(width: 40, height: 40)
                .background(article.category.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(article.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("\(article.estimatedReadingMinutes) min · \(article.category.displayName)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct CategoryTile: View {
    let category: ContentCategory
    var count: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: category.symbolName)
                .font(.title2)
                .foregroundStyle(category.tint)
            Text(category.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
            if let count {
                Text("\(count) guides")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(category.tint.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(category.tint.opacity(0.18), lineWidth: 1)
        )
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.mist, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AppTheme.brandGreen, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.title)
        }
        .accessibilityLabel("Progress \(Int((progress * 100).rounded())) percent")
    }
}

struct DisclaimerBanner: View {
    var body: some View {
        Text("Informational only — not legal, migration, financial, or medical advice. Always verify with official Australian Government sources.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12))
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
