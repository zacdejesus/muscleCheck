//
//  CalendarDayCellSnapshotTests.swift
//  MuscleCheckTests
//
//  Created by z Air on 09/08/2026.
//

import Testing
import SnapshotTesting
import SwiftUI
import Foundation
@testable import MuscleCheck

/// Snapshot coverage for the month-grid cell. Layout here is emergent — no single
/// property says "the cell looks right" — so it's asserted against an approved image
/// instead of `#expect`.
///
/// `@MainActor` is load-bearing: `.image` renders through a `UIHostingController`, and
/// Swift Testing runs tests in parallel on the cooperative pool (XCTest gave you the
/// main thread for free; this doesn't). Without it the UIKit access is a race that the
/// Swift 5 language mode won't flag at compile time.
@MainActor
struct CalendarDayCellSnapshotTests {

    // MARK: - Fixtures

    /// The cell draws `Date.appCalendar.component(.day, ...)`, so a live `Date()` would
    /// bake today's number into the reference and fail tomorrow. Noon-anchored and built
    /// with the app calendar, same as `MonthCalendarCalculatorTests`.
    private static let fixedDate: Date = date(1995, 3, 27)

    /// The cell is `maxWidth: .infinity`, so it has no intrinsic width and `.sizeThatFits`
    /// collapses it to its 32pt content — a geometry the app never renders. In
    /// `MonthCalendarView` seven cells split the card: ~393pt screen − 64pt of padding
    /// (`.padding()` + `.padding(.horizontal)`) ÷ 7 ≈ 47pt. Height matches the view's own
    /// `.frame(height: 46)`.
    private static let cellSize = CGSize(width: 47, height: 46)

    private static let cellLayout = SwiftUISnapshotLayout.fixed(
        width: cellSize.width,
        height: cellSize.height
    )

    // MARK: - Tests

    @Test
    func testPlainDayInMonth() {
        let day = CalendarDay(date: Self.fixedDate, isInDisplayedMonth: true)
        let view = CalendarDayCell(day: day, isToday: false, isSelected: false, intensity: 0)

        assertSnapshot(of: view, as: .image(layout: Self.cellLayout))
    }

    // MARK: - Helpers

    /// Noon-anchored date (dodges midnight/DST edges), built with the app calendar.
    private static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour
        return Date.appCalendar.date(from: c)!
    }
}
