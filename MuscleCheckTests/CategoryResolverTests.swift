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
        tracksWeight: Bool = false
    ) -> CustomCategory {
        CustomCategory(id: id, name: name, icon: icon, sortOrder: 99, tracksWeight: tracksWeight)
    }

    @Test
    func builtInResolvesFromEnum() {
        let r = CategoryResolver.resolve("gym", custom: [])
        #expect(r.isBuiltIn)
        #expect(r.id == "gym")
        #expect(r.tracksWeight)                       // gym is the weight-tracking category
        #expect(!r.displayName.isEmpty)
        #expect(r.icon == ActivityCategory.gym.defaultIcon)
    }

    @Test
    func builtInNonGymDoesNotTrackWeight() {
        let r = CategoryResolver.resolve("yoga", custom: [])
        #expect(r.isBuiltIn)
        #expect(!r.tracksWeight)
    }

    @Test
    func customResolvesFromStore() {
        let cat = customCat("escalada", name: "Escalada", icon: "figure.climbing", tracksWeight: true)
        let r = CategoryResolver.resolve("escalada", custom: [cat])
        #expect(!r.isBuiltIn)
        #expect(r.id == "escalada")
        #expect(r.displayName == "Escalada")
        #expect(r.icon == "figure.climbing")
        #expect(r.tracksWeight)
    }

    @Test
    func builtInWinsOverCustomWithSameId() {
        // A custom category must never shadow a built-in rawValue.
        let shadow = customCat("gym", name: "Hacked", tracksWeight: false)
        let r = CategoryResolver.resolve("gym", custom: [shadow])
        #expect(r.isBuiltIn)
        #expect(r.tracksWeight)                       // still the real gym, not the shadow
    }

    @Test
    func orphanStringFallsBackGracefully() {
        // Category whose CustomCategory was deleted: must not crash, must degrade sanely.
        let r = CategoryResolver.resolve("deleted-cat", custom: [])
        #expect(!r.isBuiltIn)
        #expect(r.id == "deleted-cat")
        #expect(r.displayName == "deleted-cat")       // shows the raw string, not empty
        #expect(!r.tracksWeight)
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
