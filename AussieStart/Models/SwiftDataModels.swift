import Foundation
import SwiftData

@Model
final class BookmarkRecord {
    @Attribute(.unique) var articleID: String
    var dateSaved: Date

    init(articleID: String, dateSaved: Date = .now) {
        self.articleID = articleID
        self.dateSaved = dateSaved
    }
}

@Model
final class RecentViewRecord {
    @Attribute(.unique) var articleID: String
    var viewedAt: Date
    var progress: Double

    init(articleID: String, viewedAt: Date = .now, progress: Double = 0) {
        self.articleID = articleID
        self.viewedAt = viewedAt
        self.progress = progress
    }
}

@Model
final class RecentSearchRecord {
    @Attribute(.unique) var query: String
    var searchedAt: Date

    init(query: String, searchedAt: Date = .now) {
        self.query = query
        self.searchedAt = searchedAt
    }
}

@Model
final class ChecklistProgressRecord {
    @Attribute(.unique) var taskID: String
    var completed: Bool
    var completedAt: Date?

    init(taskID: String, completed: Bool = false, completedAt: Date? = nil) {
        self.taskID = taskID
        self.completed = completed
        self.completedAt = completedAt
    }
}

@Model
final class JourneyProgressRecord {
    @Attribute(.unique) var dayID: String
    var completed: Bool
    var completedAt: Date?

    init(dayID: String, completed: Bool = false, completedAt: Date? = nil) {
        self.dayID = dayID
        self.completed = completed
        self.completedAt = completedAt
    }
}
