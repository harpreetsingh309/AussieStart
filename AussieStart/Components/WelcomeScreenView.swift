import SwiftUI

struct WelcomeScreenView: View {
    let language: AppLanguage
    let onContinue: () -> Void

    @State private var appear = false

    private func t(_ key: String) -> String { L10n.tr(key, language: language) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                welcomeBackground(size: geo.size)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(t("onboarding.welcome_line1"))
                        Text(t("onboarding.welcome_line2"))
                        Text(t("onboarding.welcome_line3"))
                    }
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 18)

                    Text(t("onboarding.welcome_tagline"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.94))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial.opacity(0.55), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(.white.opacity(0.28), lineWidth: 0.5)
                        }
                        .padding(.top, 18)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 12)

                    // A fixed gap, not a flexible Spacer. Two flexible spacers
                    // would share the free space and centre the text block over
                    // the middle of the scene; with only the top one flexible
                    // the copy settles at the bottom and leaves the horizon clear.
                    Spacer().frame(height: 30)

                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Text(t("onboarding.welcome_cta"))
                                .font(.headline.weight(.bold))
                            Image(systemName: "arrow.right")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(AppTheme.brandNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, geo.safeAreaInsets.top)
                .padding(.bottom, geo.safeAreaInsets.bottom + 12)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                appear = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(t("onboarding.welcome_line1")) \(t("onboarding.welcome_line2")) \(t("onboarding.welcome_line3")). \(t("onboarding.welcome_tagline"))")
        .accessibilityAction(named: t("onboarding.welcome_cta"), onContinue)
    }

    /// Set to `true` to use the bundled Sydney Harbour photo instead of the
    /// drawn outback scene. The photo is 1400×933 landscape supplied at 1x
    /// only, so on a portrait phone it is cropped hard and upscaled roughly
    /// threefold. The drawn scene stays sharp at any size and needs no licence.
    private static let usesPhotoBackground = false

    @ViewBuilder
    private func welcomeBackground(size: CGSize) -> some View {
        ZStack {
            Color.black

            if Self.usesPhotoBackground {
                Image("welcome-australia")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()

                LinearGradient(
                    colors: [
                        .black.opacity(0.18),
                        .black.opacity(0.08),
                        .black.opacity(0.55),
                        .black.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                AustralianHorizonView(warmth: appear ? 1 : 0.35)
                    .animation(.easeInOut(duration: 1.1), value: appear)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
