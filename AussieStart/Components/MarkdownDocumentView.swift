import SwiftUI

struct MarkdownDocumentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let text):
                    headingView(level: level, text: text)
                case .paragraph(let text):
                    Text(inlineAttributed(text))
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                case .bullet(let text):
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(AppTheme.brandGreen)
                            .frame(width: 7, height: 7)
                            .padding(.top, 7)
                        Text(inlineAttributed(text))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 4)
                case .numbered(let number, let text):
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(number)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(AppTheme.brandGreen, in: Circle())
                        Text(inlineAttributed(text))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
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
        }
    }

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        switch level {
        case 1:
            Text(text)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.title)
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
        case 2:
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(AppTheme.brandGreen)
                    .frame(width: 5, height: 28)

                Text(text)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.title)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.top, 10)
            .accessibilityAddTraits(.isHeader)
        case 3:
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.brandGold)
                Text(text)
                    .font(.headline)
                    .foregroundStyle(AppTheme.title)
            }
            .padding(.top, 8)
            .accessibilityAddTraits(.isHeader)
        default:
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.brandGreen)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.top, 6)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private enum Block {
        case heading(Int, String)
        case paragraph(String)
        case bullet(String)
        case numbered(Int, String)
        case quote(String)
        case divider
    }

    private var blocks: [Block] {
        var result: [Block] = []
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

    private func matchNumbered(_ line: String) -> (Int, String)? {
        guard let dot = line.firstIndex(of: "."),
              let number = Int(line[..<dot]),
              line[dot...].hasPrefix(". ")
        else { return nil }
        let text = line[line.index(dot, offsetBy: 2)...]
        return (number, String(text))
    }

    private func inlineAttributed(_ text: String) -> AttributedString {
        if let md = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return md
        }
        return AttributedString(text)
    }
}
