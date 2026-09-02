import SwiftUI
import SwiftData
import UIKit

@main
struct AussieStartApp: App {
    @State private var preferences = UserPreferences()
    @State private var store = StoreManager()
    private let container: ModelContainer

    init() {
        let schema = Schema([
            BookmarkRecord.self,
            RecentViewRecord.self,
            RecentSearchRecord.self,
            ChecklistProgressRecord.self,
            JourneyProgressRecord.self
        ])
        let storeURL = URL.applicationSupportDirectory.appending(path: "AussieStart.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            try? FileManager.default.removeItem(at: storeURL)
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
        _ = ContentLoader.shared
        if AppStoreScreenshotScene.isActive {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(preferences)
                .environment(store)
                .environment(\.locale, preferences.language.locale)
                .environment(\.layoutDirection, preferences.language.isRightToLeft ? .rightToLeft : .leftToRight)
                .preferredColorScheme(AppStoreScreenshotScene.isActive ? .light : preferences.appearance.colorScheme)
                .tint(AppTheme.accent)
                .animation(.easeInOut(duration: 0.25), value: preferences.appearance)
        }
        .modelContainer(container)
    }
}
