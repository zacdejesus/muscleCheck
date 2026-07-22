//
//  MuscleEntityQuery.swift
//  MuscleCheck
//

import AppIntents
import SwiftData

struct MuscleEntityQuery: EnumerableEntityQuery, EntityStringQuery {

    func allEntities() async throws -> [MuscleAppEntity] {
        let actor = MuscleDataActor(modelContainer: MuscleDataActor.sharedContainer)
        let names = try await actor.fetchAllMuscleNames()
        return names.map { MuscleAppEntity(id: $0, name: $0) }
    }

    func entities(for identifiers: [String]) async throws -> [MuscleAppEntity] {
        let all = try await allEntities()
        return all.filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [MuscleAppEntity] {
        let all = try await allEntities()
        return all.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }
}
