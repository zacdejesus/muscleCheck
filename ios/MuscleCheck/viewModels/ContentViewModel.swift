//
//  ContentViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/05/2025.
//

import Foundation
import SwiftData
import HealthKit
import TipKit

@MainActor
final class ContentViewModel: ObservableObject {
  
  private var context: ModelContextProtocol?
  private(set) var entries: [MuscleEntry] = []
  private var muscleEntryManager: MuscleEntryManager?
  @Published private(set) var weekEntries: [MuscleEntry] = []
  @Published private(set) var groupedCurrentWeekEntries: [(category: String, entries: [MuscleEntry])] = []

  func setup(context: ModelContextProtocol, entries: [MuscleEntry]) async {
    self.context = context
    self.entries = entries

    self.muscleEntryManager = .init(context: context)

    // One-time persist of the lazily-derived metric for pre-metric entries. A
    // failure is NOT fatal (entries keep metricRaw == "" and the backfill retries
    // on the next launch), but it must not pass silently: custom-category entries
    // can't self-heal through the getter fallback (built-in-only), so a swallowed
    // error here would leave them rendered as check-only.
    do {
      try muscleEntryManager?.backfillMetricTypes()
    } catch {
      assertionFailure("Metric backfill failed (will retry next launch): \(error)")
    }

    insertDefaultMuscleEntries()
    donateWeeklyResetTipIfWeekChanged()

    updateCurrentEntries()
  }

  /// The weekly list clears itself now (the check derives from the week's sessions),
  /// so there is no reset step left to hook the tip onto. What the tip teaches is the
  /// MOMENT the user first sees their checkmarks gone — the first launch of a new week
  /// after a week in which they actually trained.
  ///
  /// The week is remembered as a `Date` (its Monday), not as a week/year int pair: one
  /// value that can't disagree with itself, and no week numbering to get wrong when a
  /// week straddles New Year.
  private func donateWeeklyResetTipIfWeekChanged() {
    guard let thisWeek = Date().startOfWeek() else { return }

    let lastSeen = UserDefaultsManager.shared.lastSeenWeekStart
    UserDefaultsManager.shared.lastSeenWeekStart = thisWeek

    // First launch ever, or same week: nothing was cleared. `<` rather than `!=` so a
    // clock moved backwards can't fake a reset.
    guard let lastSeen, lastSeen < thisWeek else { return }

    // Only teach it when there were checks to lose: someone who trained nothing last
    // week sees no change, and the tip would explain something that didn't happen.
    guard entries.contains(where: { $0.isTrained(inWeekOf: lastSeen) }) else { return }

    Task { await WeeklyResetTip.didResetWeek.donate() }
  }

  func updateCurrentEntries() {
      do {
          guard let fetchEntries = try muscleEntryManager?.fetchAllEntries() else { return }
          entries = fetchEntries

          // No filtering: the old `weekOfYear == currentWeek` test only ever passed
          // because the weekly reset re-stamped every entry. "Current week" is not a
          // property of the row — it's a question about its sessions, answered by
          // `MuscleEntry.isChecked`.
          if weekEntries != entries {
              weekEntries = entries
          }

          // Group entries by category in stable order
          let grouped = Dictionary(grouping: weekEntries) { $0.category }
          groupedCurrentWeekEntries = grouped
              .sorted { lhs, rhs in
                  // Built-ins keep their declared order; custom categories (no enum match)
                  // share the trailing bucket, so break ties on the key for a STABLE order
                  // — Swift's sort isn't stable, and without this several customs jittered.
                  let lOrder = ActivityCategory(rawValue: lhs.key)?.sortOrder ?? 99
                  let rOrder = ActivityCategory(rawValue: rhs.key)?.sortOrder ?? 99
                  if lOrder != rOrder { return lOrder < rOrder }
                  return lhs.key < rhs.key
              }
              .map { (category: $0.key, entries: $0.value) }

          let sharedEntries = weekEntries.map { SharedMuscleEntry(name: $0.name, isChecked: $0.isChecked, icon: $0.icon) }
          let currentStreak = StreakCalculator.currentStreak(from: entries)
          let maxStreak = StreakCalculator.maxStreak(from: entries)
          Task.detached {
              WidgetBridge.publish(entries: sharedEntries, currentStreak: currentStreak, maxStreak: maxStreak)
          }
      } catch {
          assertionFailure("Failed to fetch entries: \(error)")
      }
  }
  
  func insertDefaultMuscleEntries() {

    // The initial seed is chosen in onboarding now; this stays only as a safety net
    // for the odd state "onboarded but never seeded" (e.g. pre-onboarding installs
    // whose defaults survived a store wipe).
    guard UserDefaultsManager.shared.hasCompletedOnboarding else { return }
    guard !UserDefaultsManager.shared.defaultEntriesCreated else { return }
    
    let defaultGroups = [
      NSLocalizedString("group_chest", comment: ""),
      NSLocalizedString("group_back", comment: ""),
      NSLocalizedString("group_legs", comment: ""),
      NSLocalizedString("group_shoulders", comment: ""),
      NSLocalizedString("group_biceps", comment: ""),
      NSLocalizedString("group_triceps", comment: ""),
      NSLocalizedString("group_abdomen", comment: "")
    ]
    
    for group in defaultGroups {
      let entry = MuscleEntry(name: group)
      context?.insert(entry)
    }
    
    UserDefaultsManager.shared.defaultEntriesCreated = true
    do {
      try context?.save()
    } catch  {
      assertionFailure("Failed to save context after resetting entries: \(error)")
    }
  }
  
  /// Saves today's session (whatever fields the entry's metric captures).
  /// Premise: "if I log something today, I trained today", so this also marks the entry as
  /// checked for the current week. Values arrive in canonical storage units (kg/s/m).
  func saveSession(_ input: SessionInput, for entry: MuscleEntry) {
    entry.setTodaySession(
      weight: input.weightKg,
      sets: input.sets,
      reps: input.reps,
      durationSeconds: input.durationSeconds,
      distanceMeters: input.distanceMeters
    )
    do {
      try context?.save()
    } catch {
      assertionFailure("Failed to save session: \(error)")
    }
    updateCurrentEntries()
  }

  // MARK: - Exercises (Fase 2)

  /// Logs today's values for one exercise inside a group. `MuscleEntry.logExercise`
  /// also marks the group trained today, so the check/streak/stats keep working.
  func logExercise(_ exercise: Exercise, _ input: SessionInput, in group: MuscleEntry) {
    group.logExercise(id: exercise.id, input: input)
    persist("Failed to log exercise")
  }

  func addExercise(name: String, metric: MetricType, icon: String, to group: MuscleEntry) {
    group.addExercise(name: name, metric: metric, icon: icon)
    persist("Failed to add exercise")
  }

  func deleteExercise(_ exercise: Exercise, from group: MuscleEntry) {
    group.deleteExercise(id: exercise.id)
    persist("Failed to delete exercise")
  }

  private func persist(_ message: String) {
    do {
      try self.context?.save()
    } catch {
      assertionFailure("\(message): \(error)")
    }
    updateCurrentEntries()
  }

  func toggleActivity(for entry: MuscleEntry) {
    let today = Date()
    // Read the derived state BEFORE mutating: the answer changes with the sessions.
    if entry.isTrained(inWeekOf: today) {
      // Un-checking means "I did not train this this week", so the whole week goes.
      // Dropping only today's session would leave the check ON whenever an earlier
      // day of the same week still had one — the tap would look like a no-op.
      entry.removeSessions(inWeekOf: today)
    } else {
        entry.addSession(today)
        // First-ever check completes the "how to check" lesson; checking a strength
        // entry makes the weight-log tip eligible (the tip copy is weight-worded).
        CheckActivityTip().invalidate(reason: .actionPerformed)
        if entry.metric == .strength {
          Task { await LogWeightTip.didCheckGymActivity.donate() }
        }
    }
    do {
      try context?.save()
    } catch  {
      assertionFailure("Failed to save context after resetting entries: \(error)")
    }
    updateCurrentEntries()
  }
  
  func deleteEntries(at offsets: IndexSet) {
    for index in offsets {
      guard let entry = entries[safe: index] else { return  }
      context?.delete(entry)
    }
    try? context?.save()
  }
  
  func deleteEntries(from sectionEntries: [MuscleEntry], at offsets: IndexSet) {
    for index in offsets {
      guard let entry = sectionEntries[safe: index] else { return }
      context?.delete(entry)
    }
    try? context?.save()
    updateCurrentEntries()
  }
  
  /// Logs a HealthKit workout against the user-chosen entries. HealthKit only knows the
  /// activity type (e.g. "strength training"), not which muscles — so the caller picks the
  /// targets. If `targets` is empty (the category has no entries yet) a generic entry is
  /// created from the workout as a fallback.
  func logHealthKitWorkout(_ workout: HKWorkout, to targets: [MuscleEntry]) {
    guard let manager = muscleEntryManager else { return }

    let workoutDate = workout.startDate

    do {
      var entriesToLog = targets
      if entriesToLog.isEmpty {
        let category = HealthKitManager.mapToCategory(workout.workoutActivityType)
        let name = HealthKitManager.suggestedName(for: workout)
        let icon = HealthKitManager.iconForWorkout(workout)
        try manager.addEntry(name: name, category: category.rawValue, icon: icon)
        guard let created = try manager.fetchAllEntries()
          .first(where: { $0.name == name && $0.category == category.rawValue }) else { return }
        entriesToLog = [created]
      }

      for target in entriesToLog {
        // The session is the check: if the workout falls in the current week, the
        // entry reads as checked on its own (that `if` WAS the derivation, by hand).
        target.addSession(workoutDate)
        try manager.update(target)
      }
    } catch {
      return
    }

    updateCurrentEntries()
  }
}
