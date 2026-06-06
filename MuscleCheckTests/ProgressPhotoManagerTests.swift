//
//  ProgressPhotoManagerTests.swift
//  MuscleCheckTests
//
//  Guards the ProgressPhoto persistence path. `testProgressPhotoPersistsAlongsideMuscleEntry`
//  specifically covers the regression where the App Intents actor created the shared
//  on-disk store without ProgressPhoto in its schema → "no such table: ZPROGRESSPHOTO".
//  Saving a ProgressPhoto in a container that also declares MuscleEntry asserts the
//  schema is complete.
//

import Testing
@testable import MuscleCheck
import Foundation
import SwiftData

@MainActor
struct ProgressPhotoManagerTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: MuscleEntry.self, ProgressPhoto.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return container.mainContext
    }

    @Test
    func testProgressPhotoPersistsAlongsideMuscleEntry() throws {
        let ctx = try makeContext()
        ctx.insert(ProgressPhoto(fileName: "leg.jpg", note: "leg day"))
        // Throws "no such table: ZPROGRESSPHOTO" if ProgressPhoto were missing from the schema.
        try ctx.save()

        let photos = try ProgressPhotoManager(context: ctx).fetchAllPhotos()
        #expect(photos.count == 1)
        #expect(photos.first?.note == "leg day")
        #expect(photos.first?.fileName == "leg.jpg")
    }

    @Test
    func testFetchAllPhotosSortedNewestFirst() throws {
        let ctx = try makeContext()
        let cal = Date.appCalendar
        ctx.insert(ProgressPhoto(fileName: "old.jpg",
                                 dateTaken: cal.date(byAdding: .day, value: -5, to: Date())!))
        ctx.insert(ProgressPhoto(fileName: "new.jpg", dateTaken: Date()))
        try ctx.save()

        let photos = try ProgressPhotoManager(context: ctx).fetchAllPhotos()
        #expect(photos.map(\.fileName) == ["new.jpg", "old.jpg"])
    }

    @Test
    func testDeletePhotoRemovesRecord() throws {
        let ctx = try makeContext()
        let photo = ProgressPhoto(fileName: "x.jpg")
        ctx.insert(photo)
        try ctx.save()

        let manager = ProgressPhotoManager(context: ctx)
        try manager.deletePhoto(photo)
        #expect(try manager.fetchAllPhotos().isEmpty)
    }
}
