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
    func testGroupExerciseLogPersistsAndPrefills() throws {
        let app = makeApp()
        app.launch()

        // 1. Tap the "Chest" gym row by name → opens the group's exercises (Fase 2:
        //    tapping a group no longer opens a single-value editor).
        let chestRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Chest")).firstMatch
        XCTAssertTrue(chestRow.waitForExistence(timeout: 15), "Chest gym row not rendered")
        chestRow.tap()

        // 2. Add an exercise to the group.
        XCTAssertTrue(app.buttons["group.addExercise"].waitForExistence(timeout: 5),
                      "Group detail did not open on tapping a gym row")
        app.buttons["group.addExercise"].tap()
        let name = app.textFields["group.exerciseName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Exercise name field missing")
        name.tap(); name.typeText("Bench")
        app.buttons["group.exerciseConfirm"].tap()

        // 3. Open the exercise editor: weight field + sets/reps steppers, no auto-focus.
        //    Target the row by a11y id — after saving it merges "Bench 80 kg", so a
        //    staticText match would be ambiguous on the reopen.
        let benchRow = app.buttons["group.exercise.Bench"]
        XCTAssertTrue(benchRow.waitForExistence(timeout: 5), "Exercise row not created")
        benchRow.tap()
        XCTAssertTrue(app.navigationBars["Bench"].waitForExistence(timeout: 5),
                      "Exercise editor did not open")
        let weight = app.textFields["session.weight"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["session.sets.plus"].exists)
        XCTAssertTrue(app.buttons["session.reps.plus"].exists)
        attachScreenshot(app, name: "01-editor-open")

        // 4. Bump sets/reps via steppers FIRST (no keyboard), then type the weight (its
        //    keyboard would otherwise cover the steppers). Capture whatever the steppers
        //    land on and assert THOSE survive the round-trip.
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

        // 5. Back on the group detail: the exercise row shows "80 kg" (SwiftUI may merge
        //    the row's Texts into one element, so match by CONTAINS).
        let weightLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "80 kg")).firstMatch
        XCTAssertTrue(weightLabel.waitForExistence(timeout: 5),
                      "Exercise value not shown after saving")
        attachScreenshot(app, name: "03-exercise-value")

        // 6. Reopen the exercise and confirm the three values persisted (prefill).
        benchRow.tap()
        XCTAssertTrue(app.navigationBars["Bench"].waitForExistence(timeout: 5))
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

        // Picker flow: pick the Stretching category chip, then the "create your own"
        // escape hatch (presets can't be used — repeated runs would find them added).
        // Category chips wrap (FlowLayout), so every one is on screen — no scroll.
        let stretchingChip = app.buttons["add.category.stretching"]
        XCTAssertTrue(stretchingChip.waitForExistence(timeout: 5), "Stretching category chip not found")
        stretchingChip.tap()
        app.buttons["add.createCustom"].tap()

        let nameField = app.textFields["add.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Create form name field not found")
        nameField.tap()
        nameField.typeText(entryName)
        app.buttons["add.confirm"].tap()

        // Back on the picker — close the sheet.
        let done = app.buttons["add.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Done button not found after create")
        done.tap()

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
