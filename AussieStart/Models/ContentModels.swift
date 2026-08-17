import Foundation

struct ContentCatalog: Codable {
    let version: String
    let lastReviewed: String
    let articles: [ArticleMeta]
    let tips: [DailyTipMeta]
    let journey: [JourneyDayMeta]
    let checklists: [ChecklistMeta]
    let synonyms: [String: [String]]
    let emergencyContacts: [EmergencyContactMeta]
}

struct ArticleMeta: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: ContentCategory
    let states: [String]
    let keywords: [String]
    let estimatedReadingMinutes: Int
    let relatedArticles: [String]
    let file: String
    let lastUpdated: String
    let popularRank: Int?
    /// Asset catalog image set names, e.g. `explore-uluru-1`.
    let images: [String]?
    /// `all` or persona raw values (`student`, `worker`, …). Nil means everyone.
    let personas: [String]?
    /// Unlockable with AussieStart Pro. Nil/false = free.
    let isPremium: Bool?

    var requiresPro: Bool { isPremium == true }

    var appliesToAllStates: Bool {
        states.map { $0.lowercased() }.contains("all")
    }

    func applies(to state: AustralianState) -> Bool {
        appliesToAllStates || states.map { $0.lowercased() }.contains(state.rawValue)
    }

    func applies(to persona: UserPersona) -> Bool {
        guard let personas, !personas.isEmpty else { return true }
        let normalized = personas.map { $0.lowercased() }
        return normalized.contains("all") || normalized.contains(persona.rawValue)
    }

    func localizedTitle(for language: AppLanguage) -> String {
        L10n.tr("article.\(id).title", language: language, fallback: title)
    }

    func localizedSubtitle(for language: AppLanguage) -> String {
        L10n.tr("article.\(id).subtitle", language: language, fallback: subtitle)
    }
}

struct DailyTipMeta: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: ContentCategory
    let priority: Int
    let articleID: String?

    func localizedTitle(for language: AppLanguage) -> String {
        L10n.tr("tip.\(id).title", language: language, fallback: title)
    }

    func localizedDescription(for language: AppLanguage) -> String {
        L10n.tr("tip.\(id).description", language: language, fallback: description)
    }
}

struct JourneyDayMeta: Codable, Identifiable, Hashable {
    let id: String
    let day: Int
    let title: String
    let summary: String
    let taskIDs: [String]
    let articleIDs: [String]
    let week: Int
    let personas: [String]?
    let isPremium: Bool?

    var requiresPro: Bool { isPremium == true }

    func applies(to persona: UserPersona) -> Bool {
        guard let personas, !personas.isEmpty else { return true }
        let normalized = personas.map { $0.lowercased() }
        return normalized.contains("all") || normalized.contains(persona.rawValue)
    }

    func localizedTitle(for language: AppLanguage) -> String {
        L10n.tr("journey.\(id).title", language: language, fallback: title)
    }

    func localizedSummary(for language: AppLanguage) -> String {
        L10n.tr("journey.\(id).summary", language: language, fallback: summary)
    }
}

struct ChecklistMeta: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: ContentCategory
    let tasks: [ChecklistTaskMeta]
    let personas: [String]?

    func applies(to persona: UserPersona) -> Bool {
        guard let personas, !personas.isEmpty else { return true }
        let normalized = personas.map { $0.lowercased() }
        return normalized.contains("all") || normalized.contains(persona.rawValue)
    }

    func localizedTitle(for language: AppLanguage) -> String {
        L10n.tr("checklist.\(id).title", language: language, fallback: title)
    }

    func localizedSubtitle(for language: AppLanguage) -> String {
        L10n.tr("checklist.\(id).subtitle", language: language, fallback: subtitle)
    }
}

struct ChecklistTaskMeta: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let articleID: String?

    func localizedTitle(for language: AppLanguage) -> String {
        L10n.tr("task.\(id).title", language: language, fallback: title)
    }
}

struct EmergencyContactMeta: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let number: String
    let detail: String
    let isTripleZero: Bool

    func localizedName(for language: AppLanguage) -> String {
        L10n.tr("emergency.\(id).name", language: language, fallback: name)
    }

    func localizedDetail(for language: AppLanguage) -> String {
        L10n.tr("emergency.\(id).detail", language: language, fallback: detail)
    }

    var telURL: URL? {
        let digits = number.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }
}

struct ResolvedArticle: Identifiable, Hashable {
    let meta: ArticleMeta
    let markdown: String

    var id: String { meta.id }
    var title: String { meta.title }
    var subtitle: String { meta.subtitle }
    var category: ContentCategory { meta.category }

    func localizedTitle(for language: AppLanguage) -> String {
        meta.localizedTitle(for: language)
    }

    func localizedSubtitle(for language: AppLanguage) -> String {
        meta.localizedSubtitle(for: language)
    }
}
