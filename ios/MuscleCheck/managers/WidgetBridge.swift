//
//  WidgetBridge.swift
//  MuscleCheck
//
//  The ONE definition of the app-group contract between the app and the widget.
//  Both targets compile this file (the widget picks it up through the project's
//  membershipExceptions, same as Localizable.xcstrings), so the suite name and the
//  keys physically cannot drift apart — before this, they were duplicated string
//  literals on both sides and a typo broke the widget silently.
//

import Foundation
import WidgetKit

enum WidgetBridge {

    static let appGroup = "group.zadkiel.musclecheck"

    private enum Key {
        static let entries = "widgetEntries"
        static let currentStreak = "widgetCurrentStreak"
        static let maxStreak = "widgetMaxStreak"
    }

    /// Everything the widget renders, read in one shot.
    struct Snapshot {
        let entries: [SharedMuscleEntry]
        let currentStreak: Int
        let maxStreak: Int

        static let empty = Snapshot(entries: [], currentStreak: 0, maxStreak: 0)
    }

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    // MARK: - App side

    /// Publishes the current week to the shared suite and asks the widget to redraw.
    /// A failure here only makes the widget stale, never breaks the app, so it asserts
    /// in debug and is ignored in release.
    static func publish(entries: [SharedMuscleEntry], currentStreak: Int, maxStreak: Int) {
        guard let defaults else {
            assertionFailure("App group \(appGroup) unavailable")
            return
        }
        do {
            defaults.set(try JSONEncoder().encode(entries), forKey: Key.entries)
            defaults.set(currentStreak, forKey: Key.currentStreak)
            defaults.set(maxStreak, forKey: Key.maxStreak)
        } catch {
            assertionFailure("Failed to encode widget entries: \(error)")
            return
        }

        // Without this the widget only redraws on its own hourly timeline, so a check
        // could sit unreflected on the home screen for up to an hour. This is the only
        // place that knows the shared data just changed, which is what keeps it from
        // being forgotten again.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Widget side

    /// Reads the last published snapshot. Absent or undecodable data degrades to
    /// `.empty` — the widget shows its zero state instead of failing to render.
    static func read() -> Snapshot {
        guard let defaults else { return .empty }

        var entries: [SharedMuscleEntry] = []
        if let data = defaults.data(forKey: Key.entries),
           let decoded = try? JSONDecoder().decode([SharedMuscleEntry].self, from: data) {
            entries = decoded
        }

        return Snapshot(
            entries: entries,
            currentStreak: defaults.integer(forKey: Key.currentStreak),
            maxStreak: defaults.integer(forKey: Key.maxStreak)
        )
    }
}
