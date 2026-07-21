//
//  MetricTypeTests.swift
//  MuscleCheckTests — Feature: per-exercise metrics
//
//  Pins the raw values (they are persisted in the store — changing one silently
//  breaks every saved entry) and the per-category default table.
//

import Testing
@testable import MuscleCheck

struct MetricTypeTests {

    @Test
    func rawValuesAreStable() {
        #expect(MetricType.none.rawValue == "none")
        #expect(MetricType.strength.rawValue == "strength")
        #expect(MetricType.duration.rawValue == "duration")
        #expect(MetricType.distanceDuration.rawValue == "distanceDuration")
    }

    @Test
    func categoryDefaultsTable() {
        #expect(ActivityCategory.gym.defaultMetric == .strength)
        #expect(ActivityCategory.running.defaultMetric == .distanceDuration)
        #expect(ActivityCategory.cardio.defaultMetric == .duration)
        #expect(ActivityCategory.yoga.defaultMetric == .duration)
        #expect(ActivityCategory.pilates.defaultMetric == .duration)
        #expect(ActivityCategory.calisthenics.defaultMetric == MetricType.none)
        #expect(ActivityCategory.stretching.defaultMetric == MetricType.none)
        #expect(ActivityCategory.custom.defaultMetric == MetricType.none)
    }

    @Test
    func formattingHelpers() {
        #expect(SessionFormatting.formatDuration(seconds: 2700) == "45 min")
        #expect(SessionFormatting.formatDuration(seconds: 59) == "0 min")
        #expect(SessionFormatting.formatDistance(meters: 5200) == "5.2 km")
        #expect(SessionFormatting.formatDistance(meters: 10000) == "10.0 km")
    }
}
