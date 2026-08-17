import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext

    private var articles: ArticleRepository { ArticleRepository() }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    greeting
                    tipCard
                    forYou
                    quickTopics
                    destinations
                    journeyCard
                    continueReading
                    popular
                    emergency
                    DisclaimerBanner()
                }
                .padding()
            }
            .background {
                LinearGradient(
                    colors: [AppTheme.sand.opacity(0.85), AppTheme.page, AppTheme.page],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle("AussieStart")
        }
    }

    private var greeting: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(greetingText)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.title)
                Text(preferences.t("home.settling_in", preferences.state.localizedName(for: preferences.language)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(preferences.persona.localizedName(for: preferences.language))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.brandGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.mist, in: Capsule())
            }
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.brandGreen, AppTheme.brandNavy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .softCard(22)
    }

    private var tipCard: some View {
        Group {
            if let tip = articles.tipOfTheDay() {
                VStack(alignment: .leading, spacing: 12) {
                    Label(preferences.t("home.todays_tip"), systemImage: "lightbulb.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.brandGold)
                    Text(tip.localizedTitle(for: preferences.language))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text(tip.localizedDescription(for: preferences.language))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                    if let articleID = tip.articleID {
                        NavigationLink {
                            ArticleDetailView(articleID: articleID)
                        } label: {
                            Text(preferences.t("home.read_guide"))
                                .font(.subheadline.weight(.bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.18), in: Capsule())
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [AppTheme.brandNavy, AppTheme.brandGreenFixed.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .foregroundStyle(.white)
            }
        }
    }

    private var quickTopics: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: preferences.t("home.quick_topics"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickCategories) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.symbolName)
                                Text(category.localizedName(for: preferences.language))
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(category.tint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(category.tint.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var quickCategories: [ContentCategory] {
        preferences.persona.suggestedCategories
    }

    private var forYou: some View {
        let items = articles.recommended(for: preferences.persona, state: preferences.state)
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: preferences.t("home.for_you"),
                        subtitle: preferences.t("home.for_you_subtitle", preferences.persona.localizedName(for: preferences.language))
                    )
                    ForEach(items.prefix(4)) { article in
                        NavigationLink {
                            ArticleDetailView(articleID: article.id)
                        } label: {
                            ArticleRowView(article: article, cardStyle: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var destinations: some View {
        let items = articles.articles(in: .explore, state: preferences.state, persona: preferences.persona)
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeader(
                            title: preferences.t("home.popular_destinations"),
                            subtitle: preferences.t("home.popular_destinations_subtitle")
                        )
                        Spacer(minLength: 8)
                        NavigationLink(preferences.t("common.see_all")) {
                            CategoryDetailView(category: .explore)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.brandGreen)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(items.prefix(6)) { article in
                                NavigationLink {
                                    ArticleDetailView(articleID: article.id)
                                } label: {
                                    VStack(alignment: .leading, spacing: 10) {
                                        if let hero = (article.images ?? []).first(where: { UIImage(named: $0) != nil }) {
                                            Image(hero)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 96)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        } else {
                                            Image(systemName: "binoculars.fill")
                                                .font(.title3.weight(.semibold))
                                                .foregroundStyle(.white)
                                                .frame(width: 40, height: 40)
                                                .background(
                                                    LinearGradient(
                                                        colors: [Color(hex: "0E7490"), AppTheme.brandGreenFixed],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                )
                                        }
                                        Text(article.localizedTitle(for: preferences.language))
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.title)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Text(article.localizedSubtitle(for: preferences.language))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                        Text(preferences.t("common.min_read", article.estimatedReadingMinutes))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(Color(hex: "0E7490"))
                                    }
                                    .padding(14)
                                    .frame(width: 220, alignment: .leading)
                                    .softCard(18)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var journeyCard: some View {
        let days = articles.catalog.journey.filter { $0.applies(to: preferences.persona) }
        let done = progress.completedDayIDs()
        let completed = days.filter { done.contains($0.id) }.count
        let total = max(days.count, 1)
        let ratio = Double(completed) / Double(total)

        return NavigationLink {
            JourneyView()
        } label: {
            HStack(spacing: 16) {
                ProgressRing(progress: ratio)
                    .frame(width: 68, height: 68)
                VStack(alignment: .leading, spacing: 6) {
                    Text(preferences.t("home.first_30_days"))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.title)
                    Text(preferences.t("home.milestones_completed", completed, total))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(preferences.t("home.continue_roadmap"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.brandGreen)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .softCard(20)
        }
        .buttonStyle(.plain)
    }

    private var continueReading: some View {
        let views = progress.recentViews()
        return Group {
            if !views.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: preferences.t("home.continue_reading"))
                    ForEach(views, id: \.articleID) { view in
                        if let meta = articles.catalog.articles.first(where: { $0.id == view.articleID }) {
                            NavigationLink {
                                ArticleDetailView(articleID: meta.id)
                            } label: {
                                ArticleRowView(article: meta, cardStyle: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var popular: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: preferences.t("home.most_popular"), subtitle: preferences.t("home.most_popular_subtitle", preferences.state.shortName))
            ForEach(articles.popular(state: preferences.state, persona: preferences.persona).prefix(5)) { article in
                NavigationLink {
                    ArticleDetailView(articleID: article.id)
                } label: {
                    ArticleRowView(article: article, cardStyle: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emergency: some View {
        NavigationLink {
            EmergencyView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(preferences.t("home.emergency_contacts"))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(preferences.t("home.emergency_subtitle"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [AppTheme.danger, Color(hex: "7F1D1D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return preferences.t("greeting.morning")
        case 12..<17: return preferences.t("greeting.afternoon")
        default: return preferences.t("greeting.evening")
        }
    }
}

struct EmergencyView: View {
    @Environment(UserPreferences.self) private var preferences
    private let contacts = ContentLoader.shared.catalog.emergencyContacts

    var body: some View {
        List(contacts) { contact in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(contact.localizedName(for: preferences.language)).font(.headline)
                    if contact.isTripleZero {
                        Text(preferences.t("emergency.life_threatening"))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.danger.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.danger)
                    }
                }
                Text(contact.localizedDetail(for: preferences.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let telURL = contact.telURL {
                    Link(destination: telURL) {
                        Label(contact.number, systemImage: "phone.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.brandGreen)
                    }
                    .accessibilityLabel(preferences.t("emergency.call", contact.localizedName(for: preferences.language), contact.number))
                } else {
                    Text(contact.number)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.brandGreen)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(preferences.t("emergency.title"))
        .safeAreaInset(edge: .bottom) {
            DisclaimerBanner()
                .padding()
                .background(.bar)
        }
    }
}
