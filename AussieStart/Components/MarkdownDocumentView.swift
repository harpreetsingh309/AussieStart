import SwiftUI

struct MarkdownDocumentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let text):
                    Text(text)
                        .font(headingFont(level))
                        .foregroundStyle(AppTheme.title)
                        .padding(.top, level <= 2 ? 8 : 4)
                        .accessibilityAddTraits(.isHeader)
                case .paragraph(let text):
                    Text(inlineAttributed(text))
                        .font(.body)
                        .foregroundStyle(.primary)
                case .bullet(let text):
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .foregroundStyle(AppTheme.brandGreen)
                        Text(inlineAttributed(text))
                            .font(.body)
                    }
                case .numbered(let number, let text):
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(number).")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.brandGreen)
                            .frame(width: 24, alignment: .trailing)
                        Text(inlineAttributed(text))
                            .font(.body)
                    }
                case .quote(let text):
                    Text(text)
                        .font(.callout.italic())
                        .foregroundStyle(.secondary)
                        .padding(.leading, 12)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(AppTheme.brandGold)
                                .frame(width: 3)
                        }
                case .divider:
                    Divider().padding(.vertical, 4)
                }
            }
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

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title.bold()
        case 2: return .title2.weight(.semibold)
        case 3: return .title3.weight(.semibold)
        default: return .headline
        }
    }

    private func inlineAttributed(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        // Lightweight **bold** and *italic* handling
        if let md = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            result = md
        }
        return result
    }
}
