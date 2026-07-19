//
//  ToolbarUITests.swift
//  MuscleCheckUITests
//
//  Repro for the "dead ··· overflow" bug: at large Dynamic Type the trailing toolbar
//  actions must stay reachable (directly or via a working overflow menu).
//

import XCTest

final class ToolbarUITests: XCTestCase {

    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTrailingActionsReachableAtLargeText() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            // Skip onboarding and disable tips — this test drives the home toolbar.
            "-hasCompletedOnboarding", "YES", "-uiTesting", "YES",
            // Force the largest accessibility text size to provoke toolbar overflow.
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 15))
        attach(app, "01-toolbar-large-text")

        // Priority: Add and Settings must stay directly visible (never the first to collapse).
        XCTAssertTrue(app.buttons["Add new muscle group"].waitForExistence(timeout: 5),
                      "Add button not directly visible (lost overflow priority)")
        XCTAssertTrue(app.buttons["Settings"].exists,
                      "Settings button not directly visible (lost overflow priority)")

        // Progress Photos is declared last, so it's the first to fall into the overflow.
        // It must still be REACHABLE — directly or via the "···" menu. Just finding it in
        // the opened menu refutes the original bug ("··· que no hace nada"); we don't tap
        // it because it's Pro-gated and would open a paywall on a fresh sim.
        if !app.buttons["Progress Photos"].waitForExistence(timeout: 3) {
            let nav = app.navigationBars.firstMatch
            let overflow = nav.buttons.element(boundBy: nav.buttons.count - 1)
            overflow.tap()
            attach(app, "02-overflow-open")
        }
        XCTAssertTrue(app.buttons["Progress Photos"].waitForExistence(timeout: 3),
                      "Progress Photos not reachable — dead overflow")
        attach(app, "03-all-actions-reachable")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let s = XCTAttachment(screenshot: app.screenshot())
        s.name = name; s.lifetime = .keepAlways; add(s)
    }
}
