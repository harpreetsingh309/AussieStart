import SwiftUI
import UIKit

enum AppTheme {
    /// Primary brand accent — slightly brighter in dark mode for contrast.
    static let brandGreen = Color(light: "0B6E4F", dark: "3DDC97")
    static let brandGold = Color(light: "C4A35A", dark: "E0C07A")
    static let danger = Color(light: "B91C1C", dark: "F87171")
    static let accent = brandGreen

    /// Primary headings — navy in light, soft off-white in dark.
    static let title = Color(light: "0B1F33", dark: "F3F6F8")

    /// Page wash / soft panels.
    static let sand = Color(light: "F3EFE6", dark: "121A22")
    static let mist = Color(light: "E8F2EE", dark: "1A2A26")

    /// Cards and grouped surfaces that follow system appearance.
    static let card = Color(.secondarySystemGroupedBackground)
    static let page = Color(.systemGroupedBackground)
    static let elevated = Color(.secondarySystemBackground)

    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .default)
    static let sectionLabelFont = Font.system(.caption, design: .rounded).weight(.semibold)

    /// Kept for splash / hero gradients that intentionally stay dark.
    static let brandNavy = Color(hex: "0B1F33")
    static let brandGreenFixed = Color(hex: "0B6E4F")

    enum Layout {
        static let sectionSpacing: CGFloat = 24
        static let cardRadius: CGFloat = 20
        static let heroRadius: CGFloat = 24
        static let chipRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [brandNavy, brandGreenFixed.opacity(0.92), Color(hex: "134E4A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CardShadow: ViewModifier {
    var radius: CGFloat = 12
    var y: CGFloat = 6

    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.07), radius: radius, x: 0, y: y)
    }
}

struct PageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(
                    colors: [AppTheme.sand.opacity(0.9), AppTheme.page, AppTheme.page],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
    }
}

extension View {
    func elevatedCard(_ cornerRadius: CGFloat = AppTheme.Layout.cardRadius) -> some View {
        softCard(cornerRadius).modifier(CardShadow())
    }

    func pageBackground() -> some View {
        modifier(PageBackground())
    }
}

struct GlassCardBackground: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Layout.cardRadius

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(.white.opacity(0.22), lineWidth: 0.5)
                    }
            }
    }
}

extension View {
    func glassCard(_ cornerRadius: CGFloat = AppTheme.Layout.cardRadius) -> some View {
        modifier(GlassCardBackground(cornerRadius: cornerRadius))
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 11, 110, 79)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    init(light: String, dark: String) {
        self.init(
            uiColor: UIColor { traits in
                let hex = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(Color(hex: hex))
            }
        )
    }
}

extension ContentCategory {
    var tint: Color {
        Color(light: tintHex, dark: tintHexDark)
    }

    var tintHexDark: String {
        switch self {
        case .arrival: "5BA4D9"
        case .sim: "2DD4BF"
        case .banking: "60A5FA"
        case .healthcare: "F87171"
        case .transport: "A78BFA"
        case .driving: "FB923C"
        case .taxes: "34D399"
        case .housing: "FBBF24"
        case .jobs: "38BDF8"
        case .shopping: "F472B6"
        case .family: "C084FC"
        case .explore: "22D3EE"
        case .emergency: "F87171"
        case .students: "818CF8"
        }
    }
}
