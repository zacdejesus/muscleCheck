//
//  CategoryMigrationTests.swift
//  MuscleCheck — Feature: user-defined categories
//
//  Reproduces the device-only failure ("No se ha podido abrir el archivo
//  default.store") when upgrading from a store created WITHOUT CustomCategory
//  (a previous app version) to one WITH it, at the SAME on-disk url. A fresh
//  in-memory store never migrates — which is why CategoryStoreTests missed this.
//

import Testing
import SwiftData
import Foundation
@testable import MuscleCheck

@MainActor
struct CategoryMigrationTests {

    @Test
    func addingCustomCategoryEntityMigratesExistingStore() throws {
        let url = URL.temporaryDirectory.appending(path: "mig-\(UUID().uuidString).store")
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
            }
        }

        // 1. OLD schema: MuscleEntry + ProgressPhoto, no CustomCategory.
        do {
            let oldSchema = Schema([MuscleEntry.self, ProgressPhoto.self])
            let container = try ModelContainer(
                for: oldSchema,
                configurations: ModelConfiguration(schema: oldSchema, url: url)
            )
            let ctx = ModelContext(container)
            ctx.insert(MuscleEntry(name: "Pecho"))
            try ctx.save()
        }

        // 2. NEW schema adds CustomCategory at the SAME url → migration happens here.
        let newSchema = Schema([MuscleEntry.self, ProgressPhoto.self, CustomCategory.self])
        let container = try ModelContainer(
            for: newSchema,
            configurations: ModelConfiguration(schema: newSchema, url: url)
        )
        let ctx = ModelContext(container)

        // 3. Pre-existing data survived the migration.
        #expect(try ctx.fetch(FetchDescriptor<MuscleEntry>()).count == 1)

        // 4. Inserting a CustomCategory must work — this is exactly where the device failed.
        ctx.insert(CustomCategory(id: UUID().uuidString, name: "Escalada", icon: "figure.climbing", sortOrder: 8))
        try ctx.save()
        #expect(try ctx.fetch(FetchDescriptor<CustomCategory>()).count == 1)
    }

    @Test
    func appIntentsContainerSharesTheFullSchema() {
        // Regression: MuscleDataActor (App Intents / Siri) opened the SAME default.store
        // with a stale 2-entity schema (missing CustomCategory). Two containers with
        // different entity sets on one store → "could not open default.store" on upgraded
        // devices. Both must declare AppSchema's entities.
        let actorEntities = Set(MuscleDataActor.sharedContainer.schema.entities.map(\.name))
        let appEntities = Set(AppSchema.schema.entities.map(\.name))
        #expect(actorEntities == appEntities)
        #expect(actorEntities.contains("CustomCategory"))
    }
}
