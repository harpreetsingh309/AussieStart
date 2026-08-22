import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(UserPreferences.self) private var preferences
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if let scene = AppStoreScreenshotScene.current {
                AppStoreScreenshotRoot(scene: scene)
            } else if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if preferences.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlowView()
                    .transition(.opacity)
            }
        }
        .environment(\.locale, preferences.language.locale)
        .id(preferences.language.rawValue)
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .animation(.easeInOut(duration: 0.35), value: preferences.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.2), value: preferences.language)
        .task {
            if AppStoreScreenshotScene.isActive {
                showSplash = false
                return
            }
            try? await Task.sleep(for: .milliseconds(1200))
            showSplash = false
        }
    }
}

struct SplashView: View {
    @Environment(UserPreferences.self) private var preferences
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.brandNavy, AppTheme.brandGreenFixed.opacity(0.88), AppTheme.brandNavy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 112, height: 112)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(AppTheme.brandGold)
                        .scaleEffect(appear ? 1 : 0.72)
                        .opacity(appear ? 1 : 0)
                }

                VStack(spacing: 10) {
                    Text(preferences.t("app.name"))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)

                    Text(preferences.t("app.tagline"))
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .opacity(appear ? 1 : 0)
                }
                .padding(.horizontal, 28)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                appear = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preferences.t("app.name")). \(preferences.t("app.tagline"))")
    }
}

struct MainTabView: View {
    @Environment(UserPreferences.self) private var preferences
    @State private var selectedTab: Int

    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(preferences.t("tab.home"), systemImage: "house.fill") }
                .tag(0)

            SearchView()
                .tabItem { Label(preferences.t("tab.search"), systemImage: "magnifyingglass") }
                .tag(1)

            CategoriesView()
                .tabItem { Label(preferences.t("tab.topics"), systemImage: "square.grid.2x2.fill") }
                .tag(2)

            BookmarksView()
                .tabItem { Label(preferences.t("tab.saved"), systemImage: "bookmark.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label(preferences.t("tab.settings"), systemImage: "gearshape.fill") }
                .tag(4)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
