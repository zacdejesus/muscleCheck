//
//  CustomCategory.swift
//  MuscleCheck — Feature: user-defined categories
//
//  A category the user creates beyond the built-in ActivityCategory cases.
//  `id` is the stable string persisted in MuscleEntry.category (same field that
//  already stores built-in rawValues), so adding these is ADDITIVE — old entries
//  are untouched. Built-in rawValues are reserved and must not be used as `id`.
//

import Foundation
import SwiftData

@Model
final class CustomCategory {
    @Attribute(.unique) var id: String
    var name: String
    var icon: String
    var sortOrder: Int
    /// Pre-metric flag, kept stored because removing a property is also a schema
    /// change. Still written by the `defaultMetric` setter for coherence; only read
    /// as the migration source in the getter fallback.
    var tracksWeight: Bool
    /// Raw `MetricType`. Empty string = category created before metrics existed —
    /// resolved lazily from `tracksWeight` (that fallback IS the migration).
    var defaultMetricRaw: String = ""

    /// Default metric for NEW entries in this category (mirror of
    /// `ActivityCategory.defaultMetric` for user-defined categories).
    var defaultMetric: MetricType {
        get { MetricType(rawValue: defaultMetricRaw) ?? (tracksWeight ? .strength : .none) }
        set {
            defaultMetricRaw = newValue.rawValue
            tracksWeight = newValue == .strength
        }
    }

    init(id: String, name: String, icon: String, sortOrder: Int, defaultMetric: MetricType = .none) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.tracksWeight = defaultMetric == .strength
        self.defaultMetricRaw = defaultMetric.rawValue
    }
}
