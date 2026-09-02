import StoreKitTest
import UIKit
import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var session: SKTestSession?
    private var screenshotDirectory: URL {
        URL(fileURLWithPath: "/Users/harpreetsingh/Desktop/AussieStart/AppStore/raw")
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        if let url = Bundle(for: AppStoreScreenshotTests.self).url(forResource: "Products", withExtension: "storekit") {
            session = try SKTestSession(contentsOf: url)
            session?.resetToDefaultState()
            session?.disableDialogs = true
            session?.clearTransactions()
        }
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_AU"]
        app.launch()
        try FileManager.default.createDirectory(at: screenshotDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        session?.clearTransactions()
        session = nil
        app = nil
    }

    func testIAPPurchaseUnlocksPro() throws {
        completeOnboardingIfNeeded()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 8))

        let unlock = app.buttons["Unlock AussieStart Pro"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 8), "Paywall entry should be visible before purchase")
        unlock.tap()

        let buy = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Unlock Pro'")).firstMatch
        XCTAssertTrue(buy.waitForExistence(timeout: 12), "StoreKit product price should load on the paywall")
        buy.tap()

        confirmStoreKitSheetIfNeeded()

        app.buttons["Close"].tap()
        XCTAssertTrue(
            app.staticTexts["Pro is unlocked on this Apple ID"].waitForExistence(timeout: 8)
                || !app.buttons["Unlock AussieStart Pro"].exists,
            "Settings should reflect the Pro purchase"
        )
    }

    func testCaptureAppStoreScreenshots() throws {
        completeOnboardingIfNeeded()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 8))
        sleepBriefly()
        try saveShot("01-home")

        let first30 = app.buttons["First 30 Days"].firstMatch
        if first30.waitForExistence(timeout: 4) {
            first30.tap()
        } else {
            app.otherElements.containing(.staticText, identifier: "First 30 Days").firstMatch.tap()
        }
        XCTAssertTrue(app.navigationBars["First 30 Days"].waitForExistence(timeout: 8) || app.staticTexts["First 30 Days"].waitForExistence(timeout: 8))
        sleepBriefly()
        try saveShot("02-journey")
        popIfNeeded()

        let simGuide = app.staticTexts["Get a local SIM or eSIM"].firstMatch
        if simGuide.waitForExistence(timeout: 4) {
            simGuide.tap()
            sleepBriefly()
            try saveShot("03-guide")
            popIfNeeded()
        }

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8) || app.staticTexts["Settings"].waitForExistence(timeout: 8))
        sleepBriefly()
        try saveShot("04-languages")

        let unlock = app.buttons["Unlock AussieStart Pro"]
        if unlock.waitForExistence(timeout: 6) {
            unlock.tap()
            _ = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Unlock Pro'")).firstMatch.waitForExistence(timeout: 10)
            sleepBriefly()
            try saveShot("05-paywall")
        }
    }

    private func completeOnboardingIfNeeded() {
        _ = app.staticTexts["AussieStart"].waitForExistence(timeout: 4)
        if app.tabBars.buttons["Home"].waitForExistence(timeout: 3) {
            return
        }
        let begin = app.buttons["Begin your journey"]
        if begin.waitForExistence(timeout: 4) {
            begin.tap()
        }
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 8), "Onboarding should appear after splash")
        for _ in 0..<4 {
            if continueButton.waitForExistence(timeout: 2) {
                continueButton.tap()
            }
        }
        let start = app.buttons["Start exploring"]
        if start.waitForExistence(timeout: 4) {
            start.tap()
        }
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
    }

    private func confirmStoreKitSheetIfNeeded() {
        let buy = app.buttons["Buy"]
        if buy.waitForExistence(timeout: 3) {
            buy.tap()
        }
        let ok = app.alerts.buttons["OK"]
        if ok.waitForExistence(timeout: 3) {
            ok.tap()
        }
    }

    private func popIfNeeded() {
        if app.navigationBars.buttons.element(boundBy: 0).exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    private func sleepBriefly() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))
    }

    private func saveShot(_ name: String) throws {
        let idiom = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        let url = screenshotDirectory.appendingPathComponent("\(idiom)-\(name).png")
        try app.screenshot().pngRepresentation.write(to: url)
    }
}
