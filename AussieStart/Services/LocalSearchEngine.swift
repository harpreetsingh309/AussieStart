import Foundation

struct SearchHit: Identifiable, Hashable {
    let article: ArticleMeta
    let score: Double
    var id: String { article.id }
}

final class LocalSearchEngine {
    private let loader: ContentLoader
    private let synonyms: [String: Set<String>]

    init(loader: ContentLoader = .shared) {
        self.loader = loader
        var map: [String: Set<String>] = [:]
        for (key, values) in loader.catalog.synonyms {
            let normalizedKey = Self.normalize(key)
            var group = Set(values.map(Self.normalize))
            group.insert(normalizedKey)
            for term in group {
                map[term, default: []].formUnion(group)
            }
        }
        self.synonyms = map
    }

    func search(query: String, state: AustralianState, limit: Int = 30) -> [SearchHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let tokens = Self.tokenize(trimmed)
        let expanded = expand(tokens)
        let articles = loader.articles(for: state)

        let scored: [SearchHit] = articles.compactMap { article in
            let haystack = ([
                article.title,
                article.subtitle,
                article.category.displayName,
                article.keywords.joined(separator: " ")
            ].joined(separator: " ")).lowercased()

            var score = 0.0
            for token in expanded {
                if article.title.lowercased().contains(token) { score += 5 }
                if article.keywords.map({ $0.lowercased() }).contains(where: { $0.contains(token) || token.contains($0) }) {
                    score += 3
                }
                if haystack.contains(token) { score += 1 }
            }

            // Exact phrase boost
            if article.title.lowercased().contains(trimmed.lowercased()) {
                score += 8
            }

            guard score > 0 else { return nil }
            return SearchHit(article: article, score: score)
        }

        return scored.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return (lhs.article.popularRank ?? 999) < (rhs.article.popularRank ?? 999)
            }
            return lhs.score > rhs.score
        }
        .prefix(limit)
        .map { $0 }
    }

    private func expand(_ tokens: [String]) -> Set<String> {
        var result = Set(tokens)
        for token in tokens {
            if let group = synonyms[token] {
                result.formUnion(group)
            }
        }
        return result
    }

    private static func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map(normalize)
            .filter { $0.count > 1 }
    }

    private static func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
