import SwiftUI
import SwiftData
import UIKit

struct HomeView: View {
    @Environment(UserPreferences.self) private var preferences
    @Environment(\.modelContext) private var modelContext

    private var articles: ArticleRepository { ArticleRepository() }
    private var progress: ProgressRepository { ProgressRepository(context: modelContext) }

    private var journeyStats: (completed: Int, total: Int, ratio: Double, week: Int) {
        let days = articles.catalog.journey
            .filter { $0.applies(to: preferences.persona) }
            .sorted { $0.day < $1.day }
        let done = progress.completedDayIDs()
        let completed = days.filter { done.contains($0.id) }.count
        let total = max(days.count, 1)
        let ratio = Double(completed) / Double(total)
        let currentWeek = days.first(where: { !done.contains($0.id) })?.week ?? days.last?.week ?? 1
        return (completed, total, ratio, currentWeek)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {
                    hero
                    HomeSearchBar()
                    journeyCard
                    tipCard
                    forYou
                    quickTopics
                    destinations
                    continueReading
                    popular
                    emergency
                    DisclaimerBanner()
                }
                .padding()
            }
            .pageBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    Text(preferences.t("home.settling_in", preferences.state.localizedName(for: preferences.language)))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                }
                Spacer(minLength: 0)
                Text(preferences.persona.localizedName(for: preferences.language))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.brandGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.92), in: Capsule())
            }

            Text(preferences.t("home.hero_tagline"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            let stats = journeyStats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preferences.t("home.milestones_completed", stats.completed, stats.total))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer(minLength: 0)
                    Text(preferences.t("home.journey_week", stats.week))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.18), in: Capsule())
                }
                SegmentedProgressBar(progress: stats.ratio, style: .onDark)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                AppTheme.heroGradient
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .offset(x: 120, y: -60)
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 90, height: 90)
                    .offset(x: -100, y: 80)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.heroRadius, style: .continuous))
        }
        .modifier(CardShadow(radius: 14, y: 8))
    }

    private var tipCard: some View {
        Group {
            if let tip = articles.tipOfTheDay() {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.brandGold, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            SectionLabel(text: preferences.t("home.todays_tip"))
                            Text(tip.localizedTitle(for: preferences.language))
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.title)
                        }
                    }

                    Text(tip.localizedDescription(for: preferences.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let articleID = tip.articleID {
                        NavigationLink {
                            ArticleDetailView(articleID: articleID)
                        } label: {
                            PrimaryPillButton(title: preferences.t("home.read_guide"), style: .onLight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .elevatedCard(AppTheme.Layout.cardRadius)
            }
        }
    }

    private var quickTopics: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: preferences.t("home.quick_topics"), label: preferences.t("home.section_topics"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickCategories) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            QuickTopicChip(
                                category: category,
                                title: category.localizedName(for: preferences.language)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
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
                        subtitle: preferences.t("home.for_you_subtitle", preferences.persona.localizedName(for: preferences.language)),
                        label: preferences.t("home.section_recommended")
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
                    HStack(alignment: .bottom) {
                        SectionHeader(
                            title: preferences.t("home.popular_destinations"),
                            subtitle: preferences.t("home.popular_destinations_subtitle"),
                            label: preferences.t("home.section_explore")
                        )
                        Spacer(minLength: 8)
                        NavigationLink(preferences.t("common.see_all")) {
                            CategoryDetailView(category: .explore)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.brandGreen)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(items.prefix(6)) { article in
                                NavigationLink {
                                    ArticleDetailView(articleID: article.id)
                                } label: {
                                    ImageOverlayCard(
                                        imageName: (article.images ?? []).first(where: { UIImage(named: $0) != nil }),
                                        fallbackSymbol: "binoculars.fill",
                                        fallbackColors: [Color(hex: "0E7490"), AppTheme.brandGreenFixed],
                                        title: article.localizedTitle(for: preferences.language),
                                        subtitle: article.localizedSubtitle(for: preferences.language),
                                        footer: preferences.t("common.min_read", article.estimatedReadingMinutes)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var journeyCard: some View {
        let stats = journeyStats

        return NavigationLink {
            JourneyView()
        } label: {
            JourneyProgressCard(
                progress: stats.ratio,
                completed: stats.completed,
                total: stats.total,
                currentWeek: stats.week
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preferences.t("home.first_30_days"))
    }

    private var continueReading: some View {
        let views = progress.recentViews()
        return Group {
            if !views.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(
                        title: preferences.t("home.continue_reading"),
                        label: preferences.t("home.section_reading")
                    )
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
            SectionHeader(
                title: preferences.t("home.most_popular"),
                subtitle: preferences.t("home.most_popular_subtitle", preferences.state.shortName),
                label: preferences.t("home.section_guides")
            )
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
            .modifier(CardShadow(radius: 8, y: 4))
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
