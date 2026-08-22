import Foundation
import SwiftUI

enum AppStoreScreenshotScene: String {
    case home
    case journey
    case guide
    case languages
    case paywall
    case topics
    case explore

    static var current: AppStoreScreenshotScene? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-AppStoreScreenshot"),
              args.indices.contains(index + 1) else {
            return nil
        }
        return AppStoreScreenshotScene(rawValue: args[index + 1])
    }

    static var isActive: Bool { current != nil }
}

struct AppStoreScreenshotRoot: View {
    let scene: AppStoreScreenshotScene

    var body: some View {
        Group {
            switch scene {
            case .home:
                MainTabView()
            case .journey:
                NavigationStack {
                    JourneyView()
                }
            case .guide:
                NavigationStack {
                    ArticleDetailView(articleID: "sim-setup")
                }
            case .languages:
                SettingsView()
            case .paywall:
                PaywallView()
            case .topics:
                MainTabView(selectedTab: 2)
            case .explore:
                NavigationStack {
                    ArticleDetailView(articleID: "explore-great-ocean-road")
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
