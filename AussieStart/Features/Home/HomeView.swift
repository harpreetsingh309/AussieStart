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
                VStack(alignment: .leading, spacing: 24) {
                    greeting
                    tipCard
                    journeyCard
                    continueReading
                    popular
                    emergency
                    DisclaimerBanner()
                }
                .padding()
            }
            .background(AppTheme.page)
            .navigationTitle("AussieStart")
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(AppTheme.headlineFont)
                .foregroundStyle(AppTheme.title)
            Text("Settling in \(preferences.state.displayName) · \(preferences.persona.displayName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var tipCard: some View {
        Group {
            if let tip = articles.tipOfTheDay() {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Today's tip", systemImage: "lightbulb.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.brandGold)
                    Text(tip.title)
                        .font(.headline)
                    Text(tip.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let articleID = tip.articleID {
                        NavigationLink("Read guide") {
                            ArticleDetailView(articleID: articleID)
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(colors: [AppTheme.brandNavy, AppTheme.brandGreen], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 18)
                )
                .foregroundStyle(.white)
            }
        }
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
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("First 30 Days")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(completed)/\(total) milestones · Keep going")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
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
                                ArticleRowView(article: meta)
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
            ForEach(articles.popular(state: preferences.state)) { article in
                NavigationLink {
                    ArticleDetailView(articleID: article.id)
                } label: {
                    ArticleRowView(article: article)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emergency: some View {
        NavigationLink {
            EmergencyView()
        } label: {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                VStack(alignment: .leading) {
                    Text("Emergency contacts")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("000 · Poisons · SES · Roadside")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding()
            .background(AppTheme.danger, in: RoundedRectangle(cornerRadius: 16))
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
