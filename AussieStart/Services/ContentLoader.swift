import Foundation

enum ContentLoaderError: LocalizedError {
    case catalogMissing
    case articleMissing(String)
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .catalogMissing: "Content catalog is missing from the app bundle."
        case .articleMissing(let id): "Article file missing for \(id)."
        case .decodeFailed: "Could not decode bundled content."
        }
    }
}

final class ContentLoader {
    static let shared = ContentLoader()

    private(set) var catalog: ContentCatalog = ContentCatalog(
        version: "0",
        lastReviewed: "unknown",
        articles: [],
        tips: [],
        journey: [],
        checklists: [],
        synonyms: [:],
        emergencyContacts: []
    )
    private var markdownCache: [String: String] = [:]

    private init() {
        do {
            try loadCatalog()
        } catch {
            assertionFailure("Failed to load catalog: \(error)")
        }
    }

    func loadCatalog() throws {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: nil)
            ?? Bundle.main.url(forResource: "catalog", withExtension: "json")
        else {
            throw ContentLoaderError.catalogMissing
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        catalog = try decoder.decode(ContentCatalog.self, from: data)
    }

    func article(id: String, state: AustralianState, language: AppLanguage = .english) -> ResolvedArticle? {
        guard let meta = catalog.articles.first(where: { $0.id == id }) else { return nil }
        guard let markdown = loadMarkdown(named: meta.file, language: language) else { return nil }
        let resolved = StateContentResolver.resolve(markdown: markdown, state: state, language: language)
        return ResolvedArticle(meta: meta, markdown: resolved)
    }

    func articles(for state: AustralianState, persona: UserPersona? = nil) -> [ArticleMeta] {
        catalog.articles.filter { article in
            article.applies(to: state) && (persona.map { article.applies(to: $0) } ?? true)
        }
        .sorted { ($0.popularRank ?? 999) < ($1.popularRank ?? 999) }
    }

    func articles(in category: ContentCategory, state: AustralianState, persona: UserPersona? = nil) -> [ArticleMeta] {
        articles(for: state, persona: persona).filter { $0.category == category }
    }

    func popularArticles(state: AustralianState, persona: UserPersona? = nil, limit: Int = 6) -> [ArticleMeta] {
        Array(articles(for: state, persona: persona).prefix(limit))
    }

    func recommended(for persona: UserPersona, state: AustralianState, limit: Int = 6) -> [ArticleMeta] {
        let ranked = articles(for: state, persona: persona)
        let essentials = ranked.filter { $0.requiresPro }
        let rest = ranked.filter { !$0.requiresPro }
        return Array((essentials + rest).prefix(limit))
    }

    func tipOfTheDay(for date: Date = .now) -> DailyTipMeta? {
        guard !catalog.tips.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let sorted = catalog.tips.sorted { $0.priority < $1.priority }
        return sorted[day % sorted.count]
    }

    func relatedArticles(for articleID: String, state: AustralianState) -> [ArticleMeta] {
        guard let meta = catalog.articles.first(where: { $0.id == articleID }) else { return [] }
        return meta.relatedArticles.compactMap { id in
            catalog.articles.first(where: { $0.id == id && $0.applies(to: state) })
        }
    }

    private func loadMarkdown(named file: String, language: AppLanguage) -> String? {
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension.isEmpty ? "md" : (file as NSString).pathExtension
        let candidates: [String]
        if language.isMVPReady, language != .english {
            candidates = ["\(name).\(language.rawValue)", name]
        } else {
            candidates = [name]
        }

        for candidate in candidates {
            let cacheKey = "\(candidate).\(ext)"
            if let cached = markdownCache[cacheKey] { return cached }
            if let url = Bundle.main.url(forResource: candidate, withExtension: ext)
                ?? Bundle.main.url(forResource: candidate, withExtension: ext, subdirectory: "articles"),
               let text = try? String(contentsOf: url, encoding: .utf8) {
                markdownCache[cacheKey] = text
                return text
            }
        }
        return nil
    }
}

enum StateContentResolver {
    /// Supports blocks like:
    /// <!-- state:vic --> ... <!-- /state -->
    /// and placeholders {{state.name}}, {{state.transport}}
    static func resolve(markdown: String, state: AustralianState, language: AppLanguage = .english) -> String {
        var output = markdown
        let pattern = #"<!--\s*state:([a-z,]+)\s*-->([\s\S]*?)<!--\s*/state\s*-->"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return applyPlaceholders(output, state: state, language: language)
        }

        let ns = output as NSString
        let matches = regex.matches(in: output, range: NSRange(location: 0, length: ns.length))
        for match in matches.reversed() {
            guard match.numberOfRanges == 3,
                  let statesRange = Range(match.range(at: 1), in: output),
                  let bodyRange = Range(match.range(at: 2), in: output),
                  let fullRange = Range(match.range, in: output)
            else { continue }

            let allowed = output[statesRange]
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let replacement = allowed.contains(state.rawValue) || allowed.contains("all")
                ? String(output[bodyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                : ""
            output.replaceSubrange(fullRange, with: replacement.isEmpty ? "" : "\n\(replacement)\n")
        }

        return applyPlaceholders(output, state: state, language: language)
    }

    private static func applyPlaceholders(_ markdown: String, state: AustralianState, language: AppLanguage) -> String {
        markdown
            .replacingOccurrences(of: "{{state.name}}", with: state.localizedName(for: language))
            .replacingOccurrences(of: "{{state.short}}", with: state.shortName)
            .replacingOccurrences(of: "{{state.transport}}", with: state.transportCardName)
    }
}
