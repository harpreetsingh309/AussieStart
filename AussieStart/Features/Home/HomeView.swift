import SwiftUI
import SwiftData

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
                    quickTopics
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
                Text("Settling in \(preferences.state.displayName)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(preferences.persona.displayName)
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
                    Label("Today's tip", systemImage: "lightbulb.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.brandGold)
                    Text(tip.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text(tip.description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                    if let articleID = tip.articleID {
                        NavigationLink {
                            ArticleDetailView(articleID: articleID)
                        } label: {
                            Text("Read guide")
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
            SectionHeader(title: "Quick topics")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickCategories) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.symbolName)
                                Text(category.displayName)
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
        [.family, .healthcare, .transport, .banking, .housing, .emergency]
    }

    private var journeyCard: some View {
        let days = articles.catalog.journey
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
                    Text("First 30 Days")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.title)
                    Text("\(completed)/\(total) milestones completed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Tap to continue your roadmap")
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
                    SectionHeader(title: "Continue reading")
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
            SectionHeader(title: "Most popular", subtitle: "Start with these for \(preferences.state.shortName)")
            ForEach(articles.popular(state: preferences.state).prefix(5)) { article in
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
                    Text("Emergency contacts")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("000 · Poisons · SES · healthdirect")
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
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

struct EmergencyView: View {
    private let contacts = ContentLoader.shared.catalog.emergencyContacts

    var body: some View {
        List(contacts) { contact in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(contact.name).font(.headline)
                    if contact.isTripleZero {
                        Text("LIFE THREATENING")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.danger.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.danger)
                    }
                }
                Text(contact.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(contact.number)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.brandGreen)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Emergency")
        .safeAreaInset(edge: .bottom) {
            DisclaimerBanner()
                .padding()
                .background(.bar)
        }
    }
}
