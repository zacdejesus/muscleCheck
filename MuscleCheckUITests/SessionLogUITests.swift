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
        // Force English + kg so the assertions are deterministic.
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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

        // 2. The session log modal opens with title "Log" and the three fields.
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 5),
                      "Session log modal did not open on tapping a gym row")
        let weight = app.textFields["session.weight"]
        let sets = app.textFields["session.sets"]
        let reps = app.textFields["session.reps"]
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        XCTAssertTrue(sets.exists)
        XCTAssertTrue(reps.exists)
        attachScreenshot(app, name: "01-modal-open")

        // 3. Enter weight + sets + reps and save.
        weight.tap()
        weight.typeText("80")
        sets.tap()
        sets.typeText("4")
        reps.tap()
        reps.typeText("10")
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
        XCTAssertTrue(app.navigationBars["Log"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["session.weight"].value as? String, "80")
        XCTAssertEqual(app.textFields["session.sets"].value as? String, "4")
        XCTAssertEqual(app.textFields["session.reps"].value as? String, "10")
        attachScreenshot(app, name: "04-reopened-prefilled")
    }

    @MainActor
    func testNonGymRowDoesNotOpenModal() throws {
        let app = makeApp()
        app.launch()

        // Create a yoga (non-gym) entry through the add flow. Unique name avoids the
        // manager's duplicate rejection across repeated runs on the same simulator.
        let yogaName = "Yoga\(Int(Date().timeIntervalSince1970) % 100000)"

        app.buttons["Add new muscle group"].tap()
        let nameField = app.textFields["Calf"] // placeholder is the field's identifier
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Add sheet name field not found")
        nameField.tap()
        nameField.typeText(yogaName)

        // Switch the category picker from Gym to Yoga (menu picker → tap, then pick option by label).
        app.buttons["add.categoryPicker"].tap()
        let yogaOption = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Yoga")).firstMatch
        XCTAssertTrue(yogaOption.waitForExistence(timeout: 5), "Yoga option not found in category picker")
        yogaOption.tap()
        app.navigationBars.buttons["Save"].tap()

        // Tap the new yoga row — the modal must NOT open (gym-only guard).
        let yogaRow = app.staticTexts[yogaName]
        XCTAssertTrue(yogaRow.waitForExistence(timeout: 5), "Yoga row was not created")
        yogaRow.tap()
        XCTAssertFalse(app.navigationBars["Log"].waitForExistence(timeout: 2),
                       "Session log modal opened for a non-gym entry (should be gym-only)")
        attachScreenshot(app, name: "05-yoga-no-modal")
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
