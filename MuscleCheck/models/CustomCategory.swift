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
    /// Whether activities in this category prompt for weight (the gym behaviour,
    /// generalized). Off by default; the user opts in per category.
    var tracksWeight: Bool

    init(id: String, name: String, icon: String, sortOrder: Int, tracksWeight: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.tracksWeight = tracksWeight
    }
}
