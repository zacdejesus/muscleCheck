//
//  MuscleEntryMetricTests.swift
//  MuscleCheckTests — Feature: per-exercise metrics
//
//  The metric lives on the entry; the category only supplies the default. These
//  tests pin the lazy migration (empty metricRaw = pre-metric entry) and the
//  new duration/distance session plumbing.
//

import Testing
import SwiftData
@testable import MuscleCheck
import Foundation

struct MuscleEntryMetricTests {

    // MARK: - Lazy resolution (the migration path)

    @Test
    func legacyGymEntryResolvesStrength() {
        let entry = MuscleEntry(name: "Pecho", category: "gym")
        entry.metricRaw = ""    // simulate a pre-metric store
        #expect(entry.metric == .strength)
    }

    @Test
    func legacyYogaEntryResolvesDuration() {
        let entry = MuscleEntry(name: "Vinyasa", category: "yoga")
        entry.metricRaw = ""
        #expect(entry.metric == .duration)
    }

    @Test
    func legacyOrphanCategoryResolvesNone() {
        let entry = MuscleEntry(name: "Algo", category: "DEAD-UUID")
        entry.metricRaw = ""
        #expect(entry.metric == MetricType.none)
    }

    @Test
    func explicitMetricOverridesCategoryDefault() {
        let entry = MuscleEntry(name: "Plancha", category: "gym", metric: .duration)
        #expect(entry.metric == .duration)
    }

    @Test
    func initFollowsCategoryDefaultWhenNil() {
        #expect(MuscleEntry(name: "Pecho", category: "gym").metric == .strength)
        #expect(MuscleEntry(name: "Correr", category: "running").metric == .distanceDuration)
    }

    // MARK: - Session values

    @Test
    func setTodaySessionStoresDurationAndDistance() {
        let entry = MuscleEntry(name: "Correr", category: "running")
        entry.setTodaySession(weight: nil, durationSeconds: 1800, distanceMeters: 5000)
        #expect(entry.sessions.count == 1)
        #expect(entry.lastDurationSeconds == 1800)
        #expect(entry.lastDistanceMeters == 5000)
        #expect(entry.isChecked)
    }

    @Test
    func lastValuesLookBackAcrossSessions() {
        let entry = MuscleEntry(name: "Correr", category: "running")
        let cal = Date.appCalendar
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        entry.sessions.append(WorkoutSession(durationSeconds: 2400, distanceMeters: 8000, date: yesterday))
        entry.addSession(Date())    // today, no values

        #expect(entry.lastDurationSeconds == 2400)
        #expect(entry.lastDistanceMeters == 8000)
    }

    // MARK: - formattedLastMetric

    @Test
    func formattedLastMetricPerType() {
        let run = MuscleEntry(name: "Correr", category: "running")
        run.setTodaySession(weight: nil, durationSeconds: 1920, distanceMeters: 5200)
        #expect(run.formattedLastMetric == "5.2 km · 32 min")

        let yoga = MuscleEntry(name: "Vinyasa", category: "yoga")
        yoga.setTodaySession(weight: nil, durationSeconds: 2700)
        #expect(yoga.formattedLastMetric == "45 min")

        let stretch = MuscleEntry(name: "Full body", category: "stretching")
        stretch.setTodaySession(weight: nil)
        #expect(stretch.formattedLastMetric == nil)
    }

    @Test
    func formattedLastMetricNilWhenNothingRecorded() {
        let run = MuscleEntry(name: "Correr", category: "running")
        #expect(run.formattedLastMetric == nil)
    }

    // MARK: - Backfill

    @MainActor
    @Test
    func backfillPersistsDerivedMetricIncludingCustomCategories() throws {
        let container = try ModelContainer(
            for: MuscleEntry.self, CustomCategory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        // Legacy custom category that tracked weight (pre-metric).
        let custom = CustomCategory(id: "CUSTOM-1", name: "Escalada", icon: "x", sortOrder: 9)
        custom.tracksWeight = true
        custom.defaultMetricRaw = ""
        context.insert(custom)

        let gymEntry = MuscleEntry(name: "Pecho", category: "gym")
        gymEntry.metricRaw = ""
        let customEntry = MuscleEntry(name: "Boulder", category: "CUSTOM-1")
        customEntry.metricRaw = ""
        context.insert(gymEntry)
        context.insert(customEntry)
        try context.save()

        try MuscleEntryManager(context: context).backfillMetricTypes()

        #expect(gymEntry.metricRaw == "strength")
        #expect(customEntry.metricRaw == "strength")   // via the tracksWeight fallback
    }
}
