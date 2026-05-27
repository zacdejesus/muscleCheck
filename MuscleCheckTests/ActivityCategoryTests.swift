//
//  ActivityCategoryTests.swift
//  MuscleCheck
//
//  Covers the category contract: sort order (drives grouping in ContentView),
//  presets, default icons and rawValue round-tripping.
//

import Testing
@testable import MuscleCheck

struct ActivityCategoryTests {

    @Test
    func testSortOrderMatchesDeclaredOrder() {
        for (index, category) in ActivityCategory.allCases.enumerated() {
            #expect(category.sortOrder == index)
        }
    }

    @Test
    func testSortOrdersAreUnique() {
        let orders = ActivityCategory.allCases.map { $0.sortOrder }
        #expect(Set(orders).count == orders.count)
    }

    @Test
    func testRawValueRoundTrips() {
        for category in ActivityCategory.allCases {
            #expect(ActivityCategory(rawValue: category.rawValue) == category)
        }
    }

    @Test
    func testEveryCategoryHasNonEmptyDefaultIcon() {
        for category in ActivityCategory.allCases {
            #expect(!category.defaultIcon.isEmpty)
        }
    }

    @Test
    func testNonCustomCategoriesHaveNonEmptyPresets() {
        for category in ActivityCategory.allCases where category != .custom {
            #expect(!category.presetEntries.isEmpty)
        }
    }

    @Test
    func testCustomCategoryHasNoPresets() {
        #expect(ActivityCategory.custom.presetEntries.isEmpty)
    }

    @Test
    func testPresetEntriesHaveNonEmptyKeysAndIcons() {
        for category in ActivityCategory.allCases {
            for preset in category.presetEntries {
                #expect(!preset.nameKey.isEmpty)
                #expect(!preset.icon.isEmpty)
            }
        }
    }
}
