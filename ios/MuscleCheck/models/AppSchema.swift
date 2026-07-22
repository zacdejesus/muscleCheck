//
//  AppSchema.swift
//  MuscleCheck
//
//  Single source of truth for the SwiftData entity set. BOTH containers that open
//  the app's `default.store` MUST use this — the main app (MuscleCheckApp) and the
//  App Intents actor (MuscleDataActor). A mismatched entity set between two containers
//  on the same store makes SwiftData refuse to open it ("could not open default.store").
//  Adding a new @Model = add it here, and both containers pick it up.
//

import SwiftData

enum AppSchema {
    static let models: [any PersistentModel.Type] = [
        MuscleEntry.self,
        ProgressPhoto.self,
        CustomCategory.self,
    ]

    static var schema: Schema { Schema(models) }
}
