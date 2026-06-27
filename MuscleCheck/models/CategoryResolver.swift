//
//  CategoryResolver.swift
//  MuscleCheck — Feature: user-defined categories
//
//  Single point that turns a stored category string into display info, whether
//  it came from the built-in ActivityCategory enum or a user-defined
//  CustomCategory. Pure (takes the custom list as input) so it's trivially
//  testable and side-effect free. Built-ins always win over a custom with the
//  same id, so a custom can never shadow a reserved category.
//

import Foundation

struct ResolvedCategory: Equatable {
    let id: String
    let displayName: String
    let icon: String
    let tracksWeight: Bool
    let isBuiltIn: Bool
}

enum CategoryResolver {

    static func resolve(_ raw: String, custom: [CustomCategory]) -> ResolvedCategory {
        // 1. Built-in takes precedence — reserved rawValues can't be overridden.
        if let builtIn = ActivityCategory(rawValue: raw) {
            return ResolvedCategory(
                id: raw,
                displayName: builtIn.displayName,
                icon: builtIn.defaultIcon,
                tracksWeight: builtIn.tracksWeight,
                isBuiltIn: true
            )
        }
        // 2. A user-defined category.
        if let match = custom.first(where: { $0.id == raw }) {
            return ResolvedCategory(
                id: raw,
                displayName: match.name,
                icon: match.icon,
                tracksWeight: match.tracksWeight,
                isBuiltIn: false
            )
        }
        // 3. Orphan: the custom category was deleted but entries still reference it.
        //    Degrade gracefully — show the raw string, no weight, a usable icon.
        return ResolvedCategory(
            id: raw,
            displayName: raw,
            icon: ActivityCategory.custom.defaultIcon,
            tracksWeight: false,
            isBuiltIn: false
        )
    }
}
