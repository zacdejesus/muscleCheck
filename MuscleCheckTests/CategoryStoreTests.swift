//
//  CategoryStoreTests.swift
//  MuscleCheck — Feature: user-defined categories
//
//  Uses a real in-memory SwiftData context (ModelContext conforms to
//  ModelContextProtocol), which also proves CustomCategory is wired into a
//  working store.
//

import Testing
import SwiftData
@testable import MuscleCheck

@MainActor
struct CategoryStoreTests {

    private func makeStore() throws -> CategoryStore {
        let container = try ModelContainer(
            for: CustomCategory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return CategoryStore(context: ModelContext(container))
    }

    @Test
    func addPersistsAndFetchReturnsIt() throws {
        let store = try makeStore()
        let cat = try store.add(name: "Escalada", icon: "figure.climbing", defaultMetric: .none)
        let all = try store.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.id == cat.id)
        #expect(all.first?.name == "Escalada")
    }

    @Test
    func addTrimsAndRejectsEmptyName() throws {
        let store = try makeStore()
        #expect(throws: CategoryStoreError.self) {
            try store.add(name: "   ", icon: "star.fill", defaultMetric: .none)
        }
    }

    @Test
    func addRejectsDuplicateNameCaseInsensitive() throws {
        let store = try makeStore()
        try store.add(name: "Escalada", icon: "x", defaultMetric: .none)
        #expect(throws: CategoryStoreError.self) {
            try store.add(name: "escalada", icon: "y", defaultMetric: .none)
        }
    }

    @Test
    func customIdsAreUniqueAndNeverShadowBuiltIns() throws {
        let store = try makeStore()
        let a = try store.add(name: "A", icon: "x", defaultMetric: .none)
        let b = try store.add(name: "B", icon: "y", defaultMetric: .strength)
        #expect(a.id != b.id)
        #expect(ActivityCategory(rawValue: a.id) == nil)   // a UUID is never a built-in rawValue
    }

    @Test
    func sortOrderComesAfterBuiltIns() throws {
        let store = try makeStore()
        let a = try store.add(name: "A", icon: "x", defaultMetric: .none)
        #expect(a.sortOrder >= ActivityCategory.allCases.count)
    }

    @Test
    func addStrengthMetricKeepsLegacyTracksWeightCoherent() throws {
        // Older builds read only tracksWeight — a strength category must keep it true.
        let store = try makeStore()
        let strength = try store.add(name: "Pesas", icon: "dumbbell.fill", defaultMetric: .strength)
        #expect(strength.tracksWeight)
        #expect(strength.defaultMetric == .strength)

        let timed = try store.add(name: "Cinta", icon: "figure.run", defaultMetric: .duration)
        #expect(!timed.tracksWeight)
        #expect(timed.defaultMetric == .duration)
    }

    @Test
    func deleteRemovesIt() throws {
        let store = try makeStore()
        let cat = try store.add(name: "Tmp", icon: "x", defaultMetric: .none)
        try store.delete(cat)
        #expect(try store.fetchAll().isEmpty)
    }
}
