import SwiftUI

/// Shown once during onboarding, immediately after the language choice so it
/// reads in the language the person selected.
///
/// Deliberately type-led: no imitation of First Nations visual styles such as
/// dot painting, and no reproduction of the Aboriginal or Torres Strait
/// Islander flags. Earth tones only. An Acknowledgement of Country may be
/// offered by anyone; a Welcome to Country may only be given by a Traditional
/// Owner, which is why this screen is worded as an acknowledgement.
struct AcknowledgementOfCountryView: View {
    let language: AppLanguage

    var body: some View {
        ScrollView {
            AcknowledgementOfCountryCard(language: language)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

/// The acknowledgement itself, without a scroll container, so it can be placed
/// inside a screen that already scrolls (What's New) as well as standalone.
struct AcknowledgementOfCountryCard: View {
    let language: AppLanguage

    @State private var appear = false

    private func t(_ key: String) -> String { L10n.tr(key, language: language) }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: 22) {
                emblem

                Text(t("onboarding.acknowledgement_title"))
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(AppTheme.title)

                Text(t("onboarding.acknowledgement_body"))
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(6)
                    .foregroundStyle(AppTheme.title)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().opacity(0.4)

                Text(t("onboarding.acknowledgement_note"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Label(t("onboarding.acknowledgement_learn"), systemImage: "books.vertical.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.brandGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color(hex: "92400E").opacity(0.22), lineWidth: 1)
                    }
            )
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 14)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appear = true }
        }
        .accessibilityElement(children: .combine)
    }

    /// An abstract horizon in ochre and red earth tones — evocative of Country
    /// without borrowing any First Nations design language.
    private var emblem: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "B45309"), Color(hex: "92400E"), Color(hex: "7C2D12")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(hex: "FCD34D").opacity(0.9))
                .frame(width: 54, height: 54)
                .offset(y: 10)
                .blur(radius: 0.4)

            Rectangle()
                .fill(Color(hex: "451A03").opacity(0.55))
                .frame(height: 26)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 104)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityHidden(true)
    }
}
