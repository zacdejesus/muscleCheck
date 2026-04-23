//
//  MuscleAppEntity.swift
//  MuscleCheck
//

import AppIntents

struct MuscleAppEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Activity"
    static var defaultQuery = MuscleEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}
