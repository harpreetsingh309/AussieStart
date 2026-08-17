import SwiftUI

struct OnboardingFlowView: View {
    @Environment(UserPreferences.self) private var preferences
    @State private var step = 0
    @State private var language: AppLanguage = .english
    @State private var state: AustralianState = .vic
    @State private var persona: UserPersona = .student

    private func t(_ key: String) -> String { L10n.tr(key, language: language) }
    private func t(_ key: String, _ arg: CVarArg) -> String { L10n.tr(key, language: language, arg) }
    private func t(_ key: String, _ a: CVarArg, _ b: CVarArg) -> String { L10n.tr(key, language: language, a, b) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                Group {
                    switch step {
                    case 0: welcome
                    case 1: languagePicker
                    case 2: statePicker
                    case 3: personaPicker
                    default: roadmapPreview
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(language.rawValue)

                bottomBar
            }
            .background(
                LinearGradient(
                    colors: [AppTheme.sand, AppTheme.page],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
        .environment(\.locale, language.locale)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Capsule()
                .fill(AppTheme.mist)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.brandGreen)
                        .frame(width: geo.size.width * CGFloat(step + 1) / 5)
                }
        }
        .frame(height: 6)
        .padding(.horizontal)
        .padding(.top, 12)
        .accessibilityLabel(t("onboarding.step", step + 1))
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("🇦🇺")
                .font(.system(size: 56))
            Text(t("onboarding.welcome_title"))
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.title)
            Text(t("onboarding.welcome_body"))
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: t("onboarding.choose_language"), subtitle: t("onboarding.choose_language_subtitle"))
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(AppLanguage.allCases) { lang in
                        selectableRow(
                            title: lang.displayName,
                            subtitle: lang.isMVPReady ? t("common.available_now") : t("common.coming_soon_lang"),
                            selected: language == lang,
                            disabled: !lang.isMVPReady
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                language = lang
                            }
                        }
                    }
                }
            }
        }
    }

    private var statePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: t("onboarding.choose_state"), subtitle: t("onboarding.choose_state_subtitle"))
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(AustralianState.allCases) { item in
                        selectableRow(
                            title: item.localizedName(for: language),
                            subtitle: t("onboarding.transport_label", item.transportCardName),
                            selected: state == item
                        ) {
                            state = item
                        }
                    }
                }
            }
        }
    }

    private var personaPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: t("onboarding.choose_persona"), subtitle: t("onboarding.choose_persona_subtitle"))
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(UserPersona.allCases) { item in
                        selectableRow(
                            title: item.localizedName(for: language),
                            subtitle: nil,
                            selected: persona == item,
                            symbol: item.symbolName
                        ) {
                            persona = item
                        }
                    }
                }
            }
        }
    }

    private var roadmapPreview: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader(
                title: t("onboarding.roadmap_title"),
                subtitle: t("onboarding.roadmap_subtitle", persona.localizedName(for: language), state.localizedName(for: language))
            )
            VStack(alignment: .leading, spacing: 12) {
                roadmapRow(day: t("onboarding.day1"), text: t("onboarding.task_sim"))
                roadmapRow(day: t("onboarding.day2"), text: t("onboarding.task_bank"))
                if persona != .tourist {
                    roadmapRow(day: t("onboarding.day3"), text: t("onboarding.task_tfn"))
                }
                roadmapRow(day: t("onboarding.day4"), text: t("onboarding.task_transport", state.transportCardName))
                roadmapRow(day: t("onboarding.week2"), text: roadmapWeekTwoText)
            }
            .padding()
            .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 16))

            DisclaimerBanner()
            Spacer()
        }
    }

    private var roadmapWeekTwoText: String {
        switch persona {
        case .student: t("onboarding.task_more_student")
        case .family: t("onboarding.task_more_family")
        case .tourist: t("onboarding.task_more_tourist")
        case .worker, .pr, .citizen: t("onboarding.task_more")
        }
    }

    private var bottomBar: some View {
        HStack {
            if step > 0 {
                Button(t("common.back")) { step -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            Button(step == 4 ? t("onboarding.start") : t("common.continue")) {
                if step < 4 {
                    step += 1
                } else {
                    preferences.completeOnboarding(language: language, state: state, persona: persona)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.brandGreen)
        }
        .padding()
    }

    private func selectableRow(
        title: String,
        subtitle: String?,
        selected: Bool,
        symbol: String? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(AppTheme.brandGreen)
                        .frame(width: 28)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? AppTheme.brandGreen : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? AppTheme.mist : AppTheme.elevated)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }

    private func roadmapRow(day: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(day)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.brandGreen)
                .frame(width: 64, alignment: .leading)
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
    }
}
