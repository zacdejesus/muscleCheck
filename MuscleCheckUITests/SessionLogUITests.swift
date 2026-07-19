//
//  SessionLogUITests.swift
//  MuscleCheckUITests
//
//  Drives the gym "Registro" (SessionLogView) flow end-to-end through the real UI.
//

import XCTest

final class SessionLogUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        // Force English + kg so the assertions are deterministic. Skip onboarding
        // (arguments domain wins over the persisted flag) so the gym seed still
        // happens on a fresh simulator, and disable tips so no popover covers rows.
        app.launchArguments += [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-hasCompletedOnboarding", "YES", "-uiTesting", "YES"
        ]
        return app
    }

    @MainActor
    func testGymSessionLogPersistsAndPrefills() throws {
        let app = makeApp()
        app.launch()

        // 1. Tap the "Chest" gym row by name. In a SwiftUI List the name is a child staticText
        // (CONTAINS handles the case where it merges with the weight label after saving).
        let chestRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Chest")).firstMatch
        XCTAssertTrue(chestRow.waitForExistence(timeout: 15), "Chest gym row not rendered")
        chestRow.tap()

        // 2. The session log opens titled with the muscle name, with the weight field and
        //    the sets/reps steppers. It must NOT auto-focus (no keyboard on entry).
        XCTAssertTrue(app.navigationBars["Chest"].waitForExistence(timeout: 5),
                      "Session log did not open on tapping a gym row")
        let weight = app.textFields["session.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["session.sets.plus"].exists)
        XCTAssertTrue(app.buttons["session.reps.plus"].exists)
        attachScreenshot(app, name: "01-modal-open")

        // 3. Bump sets and reps via steppers FIRST (no keyboard), then type the weight (its
        //    keyboard would otherwise cover the steppers). We capture whatever values the
        //    steppers land on and assert THOSE survive the round-trip — robust to XCUITest
        //    occasionally registering a fast tap twice on an animated button.
        for _ in 0..<4 { app.buttons["session.sets.plus"].tap() }
        for _ in 0..<10 { app.buttons["session.reps.plus"].tap() }
        let setsValue = app.staticTexts["session.sets.value"].label
        let repsValue = app.staticTexts["session.reps.value"].label
        XCTAssertNotEqual(setsValue, "–", "Sets stepper did not increment")
        XCTAssertNotEqual(repsValue, "–", "Reps stepper did not increment")
        weight.tap()
        weight.typeText("80")
        attachScreenshot(app, name: "02-filled")
        app.navigationBars.buttons["Save"].tap()

        // 4. Back on the list: the cell shows the weight label "80 kg". SwiftUI may merge the
        // row's Texts into one a11y element ("<name> 80 kg"), so match by CONTAINS.
        let weightLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "80 kg")).firstMatch
        XCTAssertTrue(weightLabel.waitForExistence(timeout: 5),
                      "Weight label not shown in the list cell after saving")
        attachScreenshot(app, name: "03-list-weight-label")

        // 5. Reopen the same row and confirm the three values were persisted (prefill).
        chestRow.tap()
        XCTAssertTrue(app.navigationBars["Chest"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["session.weight"].value as? String, "80")
        XCTAssertEqual(app.staticTexts["session.sets.value"].label, setsValue)
        XCTAssertEqual(app.staticTexts["session.reps.value"].label, repsValue)
        attachScreenshot(app, name: "04-reopened-prefilled")
    }

    @MainActor
    func testNoneMetricRowDoesNotOpenModal() throws {
        let app = makeApp()
        app.launch()

        // Create a stretching entry (default metric: check-only) through the add flow.
        // Unique name avoids the manager's duplicate rejection across repeated runs.
        // Yoga is no longer suitable here: since per-exercise metrics, yoga rows log
        // duration and DO open the modal.
        let entryName = "Str\(Int(Date().timeIntervalSince1970) % 100000)"

        app.buttons["home.addFAB"].tap()
        let nameField = app.textFields["add.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add sheet name field not found")
        nameField.tap()
        nameField.typeText(entryName)

        // Switch the category picker from Gym to Stretching (menu picker → tap, then pick by label).
        app.buttons["add.categoryPicker"].tap()
        let option = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Stretching")).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5), "Stretching option not found in category picker")
        option.tap()
        app.navigationBars.buttons["Save"].tap()

        // Tap the new row — the modal must NOT open (its metric logs nothing). The row
        // can land below the fold of the lazy List (other suites may have seeded more
        // entries on this simulator), so scroll it into existence first.
        let row = app.staticTexts[entryName]
        for _ in 0..<4 where !row.exists { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Stretching row was not created")
        row.tap()
        XCTAssertFalse(app.navigationBars[entryName].waitForExistence(timeout: 2),
                       "Session log modal opened for a check-only entry")
        attachScreenshot(app, name: "05-none-metric-no-modal")
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
