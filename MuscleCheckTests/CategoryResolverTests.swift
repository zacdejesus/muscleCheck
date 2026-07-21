//
//  CategoryResolverTests.swift
//  MuscleCheck — Feature: user-defined categories
//
//  The resolver unifies built-in categories (the ActivityCategory enum) with
//  user-defined ones (CustomCategory). These tests pin the contract that keeps
//  PREVIOUS app versions working: any category string an old entry stored must
//  still resolve, and a deleted custom category must degrade without crashing.
//

import Testing
@testable import MuscleCheck

struct CategoryResolverTests {

    private func customCat(
        _ id: String,
        name: String = "Custom",
        icon: String = "star.fill",
        defaultMetric: MetricType = .none
    ) -> CustomCategory {
        CustomCategory(id: id, name: name, icon: icon, sortOrder: 99, defaultMetric: defaultMetric)
    }

    @Test
    func builtInResolvesFromEnum() {
        let r = CategoryResolver.resolve("gym", custom: [])
        #expect(r.isBuiltIn)
        #expect(r.id == "gym")
        #expect(r.defaultMetric == .strength)         // gym defaults to weight logging
        #expect(!r.displayName.isEmpty)
        #expect(r.icon == ActivityCategory.gym.defaultIcon)
    }

    @Test
    func builtInDefaultMetrics() {
        #expect(CategoryResolver.resolve("running", custom: []).defaultMetric == .distanceDuration)
        #expect(CategoryResolver.resolve("yoga", custom: []).defaultMetric == .duration)
        #expect(CategoryResolver.resolve("stretching", custom: []).defaultMetric == MetricType.none)
    }

    @Test
    func customResolvesFromStore() {
        let cat = customCat("escalada", name: "Escalada", icon: "figure.climbing", defaultMetric: .strength)
        let r = CategoryResolver.resolve("escalada", custom: [cat])
        #expect(!r.isBuiltIn)
        #expect(r.id == "escalada")
        #expect(r.displayName == "Escalada")
        #expect(r.icon == "figure.climbing")
        #expect(r.defaultMetric == .strength)
    }

    @Test
    func legacyCustomCategoryDerivesMetricFromTracksWeight() {
        // A category saved by a pre-metric app version has an empty defaultMetricRaw;
        // the tracksWeight flag is the migration source.
        let legacy = customCat("vieja", name: "Vieja")
        legacy.tracksWeight = true
        legacy.defaultMetricRaw = ""
        let r = CategoryResolver.resolve("vieja", custom: [legacy])
        #expect(r.defaultMetric == .strength)

        legacy.tracksWeight = false
        #expect(CategoryResolver.resolve("vieja", custom: [legacy]).defaultMetric == MetricType.none)
    }

    @Test
    func builtInWinsOverCustomWithSameId() {
        // A custom category must never shadow a built-in rawValue.
        let shadow = customCat("gym", name: "Hacked", defaultMetric: .none)
        let r = CategoryResolver.resolve("gym", custom: [shadow])
        #expect(r.isBuiltIn)
        #expect(r.defaultMetric == .strength)         // still the real gym, not the shadow
    }

    @Test
    func orphanStringFallsBackGracefully() {
        // Category whose CustomCategory was deleted: must not crash, must degrade sanely.
        let r = CategoryResolver.resolve("DEAD-BEEF-UUID", custom: [])
        #expect(!r.isBuiltIn)
        #expect(r.id == "DEAD-BEEF-UUID")             // preserves the id (for round-tripping)
        #expect(!r.displayName.isEmpty)               // neutral label, never the raw UUID
        #expect(r.displayName != "DEAD-BEEF-UUID")    // must NOT echo the opaque id
        #expect(r.defaultMetric == MetricType.none)
        #expect(!r.icon.isEmpty)                      // always a usable icon
    }

    @Test
    func oldEntryCategoryStillResolves() {
        // Back-compat: an entry saved by a previous app version resolves identically.
        for category in ActivityCategory.allCases {
            let r = CategoryResolver.resolve(category.rawValue, custom: [])
            #expect(r.isBuiltIn)
            #expect(r.id == category.rawValue)
        }
    }
}
