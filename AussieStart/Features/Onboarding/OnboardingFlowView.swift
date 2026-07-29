import SwiftUI

struct OnboardingFlowView: View {
    @Environment(UserPreferences.self) private var preferences
    @State private var step = 0
    @State private var language: AppLanguage = .english
    @State private var state: AustralianState = .vic
    @State private var persona: UserPersona = .student

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
        .accessibilityLabel("Onboarding step \(step + 1) of 5")
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("🇦🇺")
                .font(.system(size: 56))
            Text("Welcome to AussieStart")
                .font(AppTheme.titleFont)
                .foregroundStyle(AppTheme.title)
            Text("Trusted, offline settlement guides for new migrants — in plain language, tuned to your state.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Choose your language", subtitle: "MVP includes English, Hindi, and Punjabi. More languages unlock as content is translated.")
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(AppLanguage.allCases) { lang in
                        selectableRow(
                            title: lang.displayName,
                            subtitle: lang.isMVPReady ? "Available now" : "Coming soon",
                            selected: language == lang,
                            disabled: !lang.isMVPReady
                        ) {
                            language = lang
                        }
                    }
                }
            }
        }
    }

    private var statePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Where will you live?", subtitle: "Guides adapt for transport cards, licences, and local services.")
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(AustralianState.allCases) { item in
                        selectableRow(
                            title: item.displayName,
                            subtitle: "Transport: \(item.transportCardName)",
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
            SectionHeader(title: "What describes you?", subtitle: "We’ll prioritise your First 30 Days roadmap.")
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(UserPersona.allCases) { item in
                        selectableRow(
                            title: item.displayName,
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
                title: "Your personal roadmap",
                subtitle: "Based on \(persona.displayName.lowercased()) life in \(state.displayName)."
            )
            VStack(alignment: .leading, spacing: 12) {
                roadmapRow(day: "Day 1", text: "Get a local SIM and internet")
                roadmapRow(day: "Day 2", text: "Open a bank account")
                roadmapRow(day: "Day 3", text: "Apply for your TFN")
                roadmapRow(day: "Day 4", text: "Set up \(state.transportCardName)")
                roadmapRow(day: "Week 2+", text: "Housing, healthcare, and more")
            }
            .padding()
            .background(AppTheme.mist, in: RoundedRectangle(cornerRadius: 16))

            DisclaimerBanner()
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack {
            if step > 0 {
                Button("Back") { step -= 1 }
                    .buttonStyle(.bordered)
            }
            Spacer()
            Button(step == 4 ? "Start exploring" : "Continue") {
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
