import SwiftUI

struct MarkdownDocumentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(GuideMarkdown.sections(from: markdown)) { section in
                sectionView(section)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: MDSection) -> some View {
        switch section.kind {
        case .related:
            EmptyView()
        case .overview:
            calloutSection(section, symbol: "flag.checkered", tint: AppTheme.brandGreen)
        case .why:
            calloutSection(section, symbol: "lightbulb.fill", tint: AppTheme.brandGold)
        case .when:
            calloutSection(section, symbol: "calendar", tint: Color(hex: "3B82F6"))
        case .requirements:
            requirementsSection(section)
        case .steps:
            stepsSection(section)
        case .mistakes:
            mistakesSection(section)
        case .faq:
            faqSection(section)
        case .terms:
            termsSection(section)
        case .links:
            linksSection(section)
        case .other:
            genericSection(section)
        }
    }

    private func calloutSection(_ section: MDSection, symbol: String, tint: Color) -> some View {
        sectionCard(title: section.title, symbol: symbol, tint: tint) {
            blockStack(section.blocks)
        }
    }

    private func requirementsSection(_ section: MDSection) -> some View {
        let chips = section.blocks.compactMap { block -> String? in
            if case .bullet(let text) = block { return text }
            return nil
        }
        let extra = section.blocks.filter {
            if case .bullet = $0 { return false }
            return true
        }
        return sectionCard(title: section.title, symbol: "checklist", tint: AppTheme.brandGreen) {
            if !extra.isEmpty {
                blockStack(extra)
            }
            if !chips.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 148), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(Array(chips.enumerated()), id: \.offset) { _, text in
                        RequirementChip(text: text)
                    }
                }
            }
        }
    }

    private func stepsSection(_ section: MDSection) -> some View {
        let steps = section.blocks.compactMap { block -> (Int, String)? in
            if case .numbered(let number, let text) = block { return (number, text) }
            return nil
        }
        let extra = section.blocks.filter {
            if case .numbered = $0 { return false }
            return true
        }
        return sectionCard(title: section.title, symbol: "arrow.triangle.turn.up.right.diamond.fill", tint: AppTheme.brandGreen) {
            if !steps.isEmpty {
                StepFlowView(steps: steps)
            }
            if !extra.isEmpty {
                blockStack(extra)
            }
        }
    }

    private func mistakesSection(_ section: MDSection) -> some View {
        sectionCard(title: section.title, symbol: "exclamationmark.triangle.fill", tint: AppTheme.brandGold) {
            VStack(spacing: 8) {
                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    if case .bullet(let text) = block {
                        WarningRow(text: text)
                    } else {
                        markdownBlock(block)
                    }
                }
            }
        }
    }

    private func faqSection(_ section: MDSection) -> some View {
        let items = GuideMarkdown.faqs(from: section.blocks)
        return sectionCard(title: section.title, symbol: "questionmark.circle.fill", tint: Color(hex: "6366F1")) {
            if items.isEmpty {
                blockStack(section.blocks)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        DisclosureGroup {
                            MarkdownText(item.answer)
                                .padding(.top, 6)
                                .padding(.bottom, 4)
                        } label: {
                            Text(item.question)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.title)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                        .tint(AppTheme.brandGreen)
                        .padding(12)
                        .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private func termsSection(_ section: MDSection) -> some View {
        sectionCard(title: section.title, symbol: "text.book.closed.fill", tint: AppTheme.brandGreen) {
            VStack(spacing: 8) {
                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    if case .bullet(let text) = block {
                        TermRow(text: text)
                    } else {
                        markdownBlock(block)
                    }
                }
            }
        }
    }

    private func linksSection(_ section: MDSection) -> some View {
        let parsed = GuideMarkdown.links(from: section.blocks)
        return sectionCard(title: section.title, symbol: "link", tint: Color(hex: "0EA5E9")) {
            if !parsed.intro.isEmpty {
                blockStack(parsed.intro)
            }
            VStack(spacing: 8) {
                ForEach(parsed.links) { item in
                    Link(destination: item.url) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.brandGreen)
                                .frame(width: 32, height: 32)
                                .background(AppTheme.mist, in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.title)
                                    .multilineTextAlignment(.leading)
                                Text(item.url.host ?? item.url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func genericSection(_ section: MDSection) -> some View {
        let numberedCount = section.blocks.reduce(0) { count, block in
            if case .numbered = block { return count + 1 }
            return count
        }
        if numberedCount >= 2 {
            stepsSection(MDSection(
                id: section.id,
                title: section.title,
                kind: .steps,
                blocks: section.blocks
            ))
        } else {
            sectionCard(title: section.title, symbol: "square.stack.3d.up.fill", tint: AppTheme.brandGreen) {
                blockStack(section.blocks)
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String?,
        symbol: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title, !title.isEmpty {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: symbol)
                        .font(.body.weight(.bold))
                        .foregroundStyle(tint)
                        .frame(width: 32, height: 32)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(AppTheme.title)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityAddTraits(.isHeader)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func blockStack(_ blocks: [MDBlock]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                markdownBlock(block)
            }
        }
    }

    @ViewBuilder
    private func markdownBlock(_ block: MDBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)
        case .paragraph(let text):
            MarkdownText(text)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(AppTheme.brandGreen)
                    .frame(width: 7, height: 7)
                    .padding(.top, 7)
                MarkdownText(text)
            }
            .padding(.leading, 4)
        case .numbered(let number, let text):
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.brandGreen, in: Circle())
                MarkdownText(text)
                    .padding(.top, 2)
            }
        case .quote(let text):
            Text(text)
                .font(.callout.italic())
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .leading) {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .fill(AppTheme.brandGold)
                    .frame(width: 4)
                }
        case .divider:
            Divider()
                .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        switch level {
        case 1:
            Text(text)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.title)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)
        case 2:
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppTheme.brandGreen)
                    .frame(width: 5, height: 22)
                Text(text)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.title)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityAddTraits(.isHeader)
        default:
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.brandGold)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.title)
            }
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
        }
    }
}

// MARK: - Visual rows

private struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(GuideMarkdown.attributed(text))
            .font(AppTheme.bodyFont)
            .foregroundStyle(.primary)
            .tint(AppTheme.brandGreen)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct RequirementChip: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: GuideMarkdown.chipSymbol(for: text))
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.brandGreen)
                .padding(.top, 2)
            Text(GuideMarkdown.attributed(text))
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .tint(AppTheme.brandGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WarningRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.octagon.fill")
                .foregroundStyle(AppTheme.danger)
                .padding(.top, 2)
            Text(GuideMarkdown.attributed(text))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .tint(AppTheme.brandGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TermRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "book.fill")
                .foregroundStyle(AppTheme.brandGold)
                .padding(.top, 1)
            Text(GuideMarkdown.attributed(text))
                .font(.subheadline)
                .tint(AppTheme.brandGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct StepFlowView: View {
    let steps: [(Int, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Text("\(step.0)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.brandGreen, in: Circle())
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(AppTheme.brandGreen.opacity(0.28))
                                .frame(width: 3)
                                .frame(minHeight: 18)
                        }
                    }
                    .frame(width: 28)

                    MarkdownText(step.1)
                        .padding(.bottom, index < steps.count - 1 ? 16 : 0)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Parsing

private enum MDBlock {
    case heading(Int, String)
    case paragraph(String)
    case bullet(String)
    case numbered(Int, String)
    case quote(String)
    case divider
}

private enum MDSectionKind {
    case overview, why, when, requirements, steps, mistakes, faq, terms, links, related, other
}

private struct MDSection: Identifiable {
    let id: Int
    let title: String?
    let kind: MDSectionKind
    let blocks: [MDBlock]
}

private struct GuideLink: Identifiable {
    let id: String
    let title: String
    let url: URL
}

private enum GuideMarkdown {
    static func sections(from markdown: String) -> [MDSection] {
        let blocks = parseBlocks(markdown)
        var sections: [MDSection] = []
        var currentTitle: String?
        var currentBlocks: [MDBlock] = []
        var index = 0

        func flush() {
            let title = currentTitle
            let kind = kind(for: title, blocks: currentBlocks)
            if kind != .related, title != nil || !currentBlocks.isEmpty {
                sections.append(MDSection(id: index, title: title, kind: kind, blocks: currentBlocks))
                index += 1
            }
            currentTitle = nil
            currentBlocks = []
        }

        for block in blocks {
            if case .heading(let level, let text) = block, level == 1 {
                flush()
                currentTitle = text
                continue
            }
            currentBlocks.append(block)
        }
        flush()
        return sections
    }

    static func kind(for title: String?, blocks: [MDBlock]) -> MDSectionKind {
        let heading = (title ?? "").lowercased()
        let classified: MDSectionKind
        if matches(heading, ["related article", "संबंधित", "ਸਬੰਧਤ"]) {
            classified = .related
        } else if matches(heading, ["official", "links", "आधिकारिक", "राष्ट्रीय लिंक", "ਅਧਿਕਾਰਤ", "ਰਾਸ਼ਟਰੀ ਲਿੰਕ", "लिंक", "ਲਿੰਕ"]) {
            classified = .links
        } else if matches(heading, ["step-by-step", "step by step", "कदम", "ਕਦਮ", "itinerary"]) {
            classified = .steps
        } else if matches(heading, ["requirement", "ज़रूरी चीज़", "जरूरी चीज़", "ਲੋੜੀਂਦੀ"]) {
            classified = .requirements
        } else if matches(heading, ["mistake", "गलति", "ਗਲਤੀ"]) {
            classified = .mistakes
        } else if matches(heading, ["faq", "सवाल", "ਸਵਾਲ"]) {
            classified = .faq
        } else if matches(heading, ["useful term", "उपयोगी शब्द", "ਲਾਭਦਾਇਕ"]) {
            classified = .terms
        } else if matches(heading, ["when to", "कब करें", "ਕਦੋਂ"]) {
            classified = .when
        } else if matches(heading, ["why this", "क्यों", "ਕਿਉਂ"]) {
            classified = .why
        } else if matches(heading, ["overview", "अवलोकन", "ਝਲਕ", "ਸੰਖੇਪ"]) {
            classified = .overview
        } else {
            classified = .other
        }

        if classified != .other && classified != .related {
            return classified
        }

        let numbered = blocks.filter { if case .numbered = $0 { return true } else { return false } }.count
        if numbered >= 2 { return .steps }
        if !faqs(from: blocks).isEmpty { return .faq }
        if links(from: blocks).links.count >= 2 { return .links }
        return classified
    }

    static func faqs(from blocks: [MDBlock]) -> [(question: String, answer: String)] {
        blocks.compactMap { block -> (String, String)? in
            let text: String
            switch block {
            case .paragraph(let value), .bullet(let value):
                text = value
            default:
                return nil
            }
            return faqPair(text)
        }
    }

    static func links(from blocks: [MDBlock]) -> (intro: [MDBlock], links: [GuideLink]) {
        var intro: [MDBlock] = []
        var items: [GuideLink] = []
        var seen = Set<String>()

        func append(title: String, url: URL) {
            let key = url.absoluteString
            guard seen.insert(key).inserted else { return }
            items.append(GuideLink(id: key, title: title, url: url))
        }

        for block in blocks {
            switch block {
            case .bullet(let text), .paragraph(let text), .numbered(_, let text):
                let found = extractLinks(from: text)
                if found.isEmpty {
                    intro.append(block)
                } else {
                    found.forEach { append(title: $0.title, url: $0.url) }
                }
            default:
                intro.append(block)
            }
        }
        return (intro, items)
    }

    static func attributed(_ text: String) -> AttributedString {
        if let md = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return md
        }
        return AttributedString(text)
    }

    static func chipSymbol(for text: String) -> String {
        let value = text.lowercased()
        if matches(value, ["passport", "पासपोर्ट", "ਪਾਸਪੋਰਟ", "id", "visa", "वीज़ा", "वीजा", "ਵੀਜ਼ਾ"]) {
            return "person.text.rectangle.fill"
        }
        if matches(value, ["phone", "mobile", "फ़ोन", "फोन", "ਫੋਨ", "sim"]) {
            return "iphone"
        }
        if matches(value, ["email", "ईमेल", "ਈਮੇਲ"]) {
            return "envelope.fill"
        }
        if matches(value, ["address", "पता", "ਪਤਾ", "house", "rent"]) {
            return "house.fill"
        }
        if matches(value, ["photo", "फ़ोटो", "फोटो", "ਫੋਟੋ"]) {
            return "camera.fill"
        }
        if matches(value, ["money", "bond", "fund", "पैसे", "ਪੈਸੇ", "card", "bank"]) {
            return "banknote.fill"
        }
        if matches(value, ["student", "enrol", "school", "छात्र", "ਵਿਦਿਆਰਥੀ"]) {
            return "graduationcap.fill"
        }
        return "checkmark.circle.fill"
    }

    private static func matches(_ value: String, _ needles: [String]) -> Bool {
        needles.contains { value.contains($0.lowercased()) }
    }

    private static func faqPair(_ text: String) -> (String, String)? {
        guard text.hasPrefix("**"),
              let close = text.range(of: "**", range: text.index(text.startIndex, offsetBy: 2)..<text.endIndex)
        else { return nil }
        let question = String(text[text.index(text.startIndex, offsetBy: 2)..<close.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let answer = String(text[close.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard question.count > 8, !answer.isEmpty else { return nil }
        return (question, answer)
    }

    private static func extractLinks(from text: String) -> [(title: String, url: URL)] {
        var results: [(String, URL)] = []
        let ns = text as NSString
        if let markdown = try? NSRegularExpression(pattern: #"\[([^\]]+)\]\((https?://[^)\s]+)\)"#) {
            for match in markdown.matches(in: text, range: NSRange(location: 0, length: ns.length)) where match.numberOfRanges == 3 {
                let title = ns.substring(with: match.range(at: 1))
                if let url = URL(string: ns.substring(with: match.range(at: 2))) {
                    results.append((title, url))
                }
            }
        }
        if !results.isEmpty { return results }

        if let labeled = try? NSRegularExpression(pattern: #"^(.+?):\s*(https?://\S+|\S+\.[a-z]{2,}[^\s]*)$"#, options: [.caseInsensitive]),
           let match = labeled.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges == 3,
           let url = url(from: ns.substring(with: match.range(at: 2))) {
            let title = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
            return [(title.isEmpty ? hostTitle(url) : title, url)]
        }

        if let bare = try? NSRegularExpression(pattern: #"https?://[^\s)]+"#),
           let match = bare.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
           let url = URL(string: ns.substring(with: match.range)) {
            let title = ns.replacingCharacters(in: match.range, with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " :-"))
            return [(title.isEmpty ? hostTitle(url) : title, url)]
        }

        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if !trimmed.contains(" "), let url = url(from: trimmed) {
            return [(hostTitle(url), url)]
        }
        return []
    }

    private static func url(from raw: String) -> URL? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: ".,);"))
        if !value.contains(".") { return nil }
        if !value.hasPrefix("http") {
            value = "https://\(value)"
        }
        return URL(string: value)
    }

    private static func hostTitle(_ url: URL) -> String {
        (url.host ?? url.absoluteString).replacingOccurrences(of: "www.", with: "")
    }

    private static func parseBlocks(_ markdown: String) -> [MDBlock] {
        var result: [MDBlock] = []
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            let text = paragraphBuffer.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { result.append(.paragraph(text)) }
            paragraphBuffer.removeAll()
        }

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                flushParagraph()
                continue
            }
            if line.hasPrefix("---") || line == "***" {
                flushParagraph()
                result.append(.divider)
                continue
            }
            if line.hasPrefix("#") {
                flushParagraph()
                let level = line.prefix(while: { $0 == "#" }).count
                let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
                result.append(.heading(min(level, 4), String(text)))
                continue
            }
            if line.hasPrefix("> ") {
                flushParagraph()
                result.append(.quote(String(line.dropFirst(2))))
                continue
            }
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                flushParagraph()
                result.append(.bullet(String(line.dropFirst(2))))
                continue
            }
            if let numbered = matchNumbered(line) {
                flushParagraph()
                result.append(.numbered(numbered.0, numbered.1))
                continue
            }
            paragraphBuffer.append(line)
        }
        flushParagraph()
        return result
    }

    private static func matchNumbered(_ line: String) -> (Int, String)? {
        guard let dot = line.firstIndex(of: "."),
              let number = Int(line[..<dot]),
              line[dot...].hasPrefix(". ")
        else { return nil }
        let text = line[line.index(dot, offsetBy: 2)...]
        return (number, String(text))
    }
}
