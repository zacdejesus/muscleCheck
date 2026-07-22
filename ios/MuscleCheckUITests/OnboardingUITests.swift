//
//  OnboardingUITests.swift
//  MuscleCheckUITests
//
//  Drives the first-run onboarding end-to-end: welcome → category picker →
//  personalized seed → first contextual tip on the home list.
//

import XCTest

final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        // -resetOnboarding forces the first-run state on an installed build. Tips stay
        // ENABLED here (no -uiTesting): this flow asserts the first tip shows up.
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-resetOnboarding", "YES"
        ]
        return app
    }

    /// Welcome → picker. Retries the CTA tap once: a tap can land while the cover is
    /// still animating in and get swallowed.
    private func advanceToPicker(_ app: XCUIApplication) {
        let start = app.buttons["onboarding.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Welcome screen not shown on first run")
        start.tap()
        let skip = app.buttons["onboarding.skip"]
        if !skip.waitForExistence(timeout: 5) {
            start.tap()
            XCTAssertTrue(skip.waitForExistence(timeout: 5), "Category picker not shown after tapping Get Started")
        }
    }

    @MainActor
    func testOnboardingSeedsSelectedCategoriesAndShowsCheckTip() throws {
        let app = makeApp()
        app.launch()

        attachScreenshot(app, name: "01-welcome")
        advanceToPicker(app)

        // Picker: gym is pre-selected; add yoga, then create the list.
        XCTAssertTrue(app.buttons["onboarding.category.gym"].isSelected, "Gym should start selected")
        app.buttons["onboarding.category.yoga"].tap()
        attachScreenshot(app, name: "02-picker-gym-yoga")
        app.buttons["onboarding.createList"].tap()

        // Home list seeded: gym presets visible at the top.
        let chestRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Chest")).firstMatch
        XCTAssertTrue(chestRow.waitForExistence(timeout: 10), "Gym presets not seeded after onboarding")

        // The "check" tip pops on the first row — the first contextual lesson.
        let checkTip = app.staticTexts["Trained today?"]
        XCTAssertTrue(checkTip.waitForExistence(timeout: 10), "Check tip not shown after onboarding")
        attachScreenshot(app, name: "03-home-seeded-with-tip")

        // Dismiss the tip popover so it can't swallow the scroll gesture.
        let closeTip = app.buttons["Close"].firstMatch
        if closeTip.waitForExistence(timeout: 2) { closeTip.tap() }

        // Yoga section is below the fold of a lazy List — scroll it into existence.
        let yogaRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Vinyasa")).firstMatch
        for _ in 0..<3 where !yogaRow.exists { app.swipeUp() }
        XCTAssertTrue(yogaRow.waitForExistence(timeout: 5), "Yoga presets not seeded after onboarding")
        attachScreenshot(app, name: "04-yoga-section-seeded")
    }

    @MainActor
    func testSkipLandsOnChecklist() throws {
        let app = makeApp()
        app.launch()

        advanceToPicker(app)
        app.buttons["onboarding.skip"].tap()

        // Skip completes onboarding and lands on a seeded checklist. (Gym-ONLY seeding
        // is asserted in unit tests — the sim's store may carry entries from other runs.)
        let chestRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Chest")).firstMatch
        XCTAssertTrue(chestRow.waitForExistence(timeout: 10), "Checklist not shown after skipping onboarding")
        XCTAssertFalse(app.buttons["onboarding.skip"].exists, "Onboarding still on screen after skip")
        attachScreenshot(app, name: "05-skip-lands-on-checklist")
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
