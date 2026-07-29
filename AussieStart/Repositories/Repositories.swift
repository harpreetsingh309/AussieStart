import Foundation
import SwiftData

@MainActor
final class ArticleRepository {
    private let loader: ContentLoader
    private let searchEngine: LocalSearchEngine

    init(loader: ContentLoader = .shared) {
        self.loader = loader
        self.searchEngine = LocalSearchEngine(loader: loader)
    }

    var catalog: ContentCatalog { loader.catalog }

    func articles(for state: AustralianState) -> [ArticleMeta] {
        loader.articles(for: state)
    }

    func articles(in category: ContentCategory, state: AustralianState) -> [ArticleMeta] {
        loader.articles(in: category, state: state)
    }

    func resolve(_ id: String, state: AustralianState) -> ResolvedArticle? {
        loader.article(id: id, state: state)
    }

    func popular(state: AustralianState) -> [ArticleMeta] {
        loader.popularArticles(state: state)
    }

    func related(to id: String, state: AustralianState) -> [ArticleMeta] {
        loader.relatedArticles(for: id, state: state)
    }

    func search(_ query: String, state: AustralianState) -> [SearchHit] {
        searchEngine.search(query: query, state: state)
    }

    func tipOfTheDay() -> DailyTipMeta? {
        loader.tipOfTheDay()
    }

    func nextRecommendation(after articleID: String, state: AustralianState) -> ArticleMeta? {
        related(to: articleID, state: state).first
    }
}

@MainActor
final class BookmarkRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func isBookmarked(_ articleID: String) -> Bool {
        fetch(articleID) != nil
    }

    func toggle(_ articleID: String) {
        if let existing = fetch(articleID) {
            context.delete(existing)
        } else {
            context.insert(BookmarkRecord(articleID: articleID))
        }
        try? context.save()
    }

    func all() -> [BookmarkRecord] {
        let descriptor = FetchDescriptor<BookmarkRecord>(sortBy: [SortDescriptor(\.dateSaved, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetch(_ articleID: String) -> BookmarkRecord? {
        var descriptor = FetchDescriptor<BookmarkRecord>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}

@MainActor
final class ProgressRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func recordView(articleID: String, progress: Double = 0) {
        if let existing = fetchView(articleID) {
            existing.viewedAt = .now
            existing.progress = max(existing.progress, progress)
        } else {
            context.insert(RecentViewRecord(articleID: articleID, progress: progress))
        }
        try? context.save()
    }

    func recentViews(limit: Int = 8) -> [RecentViewRecord] {
        var descriptor = FetchDescriptor<RecentViewRecord>(
            sortBy: [SortDescriptor(\.viewedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func saveSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existing = fetchSearch(trimmed) {
            existing.searchedAt = .now
        } else {
            context.insert(RecentSearchRecord(query: trimmed))
        }
        try? context.save()
    }

    func recentSearches(limit: Int = 8) -> [RecentSearchRecord] {
        var descriptor = FetchDescriptor<RecentSearchRecord>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func isTaskCompleted(_ taskID: String) -> Bool {
        fetchTask(taskID)?.completed == true
    }

    func toggleTask(_ taskID: String) {
        if let existing = fetchTask(taskID) {
            existing.completed.toggle()
            existing.completedAt = existing.completed ? .now : nil
        } else {
            context.insert(ChecklistProgressRecord(taskID: taskID, completed: true, completedAt: .now))
        }
        try? context.save()
    }

    func completedTaskIDs() -> Set<String> {
        let descriptor = FetchDescriptor<ChecklistProgressRecord>(
            predicate: #Predicate { $0.completed == true }
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return Set(rows.map(\.taskID))
    }

    func isDayCompleted(_ dayID: String) -> Bool {
        fetchDay(dayID)?.completed == true
    }

    func toggleDay(_ dayID: String) {
        if let existing = fetchDay(dayID) {
            existing.completed.toggle()
            existing.completedAt = existing.completed ? .now : nil
        } else {
            context.insert(JourneyProgressRecord(dayID: dayID, completed: true, completedAt: .now))
        }
        try? context.save()
    }

    func completedDayIDs() -> Set<String> {
        let descriptor = FetchDescriptor<JourneyProgressRecord>(
            predicate: #Predicate { $0.completed == true }
        )
        let rows = (try? context.fetch(descriptor)) ?? []
        return Set(rows.map(\.dayID))
    }

    private func fetchView(_ articleID: String) -> RecentViewRecord? {
        var descriptor = FetchDescriptor<RecentViewRecord>(
            predicate: #Predicate { $0.articleID == articleID }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchSearch(_ query: String) -> RecentSearchRecord? {
        var descriptor = FetchDescriptor<RecentSearchRecord>(
            predicate: #Predicate { $0.query == query }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchTask(_ taskID: String) -> ChecklistProgressRecord? {
        var descriptor = FetchDescriptor<ChecklistProgressRecord>(
            predicate: #Predicate { $0.taskID == taskID }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func fetchDay(_ dayID: String) -> JourneyProgressRecord? {
        var descriptor = FetchDescriptor<JourneyProgressRecord>(
            predicate: #Predicate { $0.dayID == dayID }
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
