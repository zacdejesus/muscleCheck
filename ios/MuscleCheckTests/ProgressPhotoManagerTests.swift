//
//  ProgressPhotoManagerTests.swift
//  MuscleCheckTests
//
//  Guards the ProgressPhoto persistence path. `testProgressPhotoPersistsAlongsideMuscleEntry`
//  covers the regression where the App Intents actor created the shared store without
//  ProgressPhoto in its schema → "no such table: ZPROGRESSPHOTO".
//
//  Uses a throwaway on-disk store (unique temp URL) rather than isStoredInMemoryOnly:
//  the in-memory store traps on insert / doesn't reflect deletes reliably here, while
//  an on-disk store gives deterministic insert/delete/fetch semantics.
//

import Testing
@testable import MuscleCheck
import Foundation
import SwiftData

@MainActor
struct ProgressPhotoManagerTests {

    /// Fresh on-disk container at a unique temp URL, with an explicit (autosave-off)
    /// context so saves are deterministic. The store file is removed afterwards.
    private func makeContext() throws -> (ModelContext, URL) {
        let url = URL.temporaryDirectory.appending(path: "mc-tests-\(UUID().uuidString).store")
        let container = try ModelContainer(
            for: MuscleEntry.self, ProgressPhoto.self,
            configurations: ModelConfiguration(url: url)
        )
        return (ModelContext(container), url)
    }

    private func cleanup(_ url: URL) {
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }

    @Test
    func testProgressPhotoPersistsAlongsideMuscleEntry() throws {
        let (ctx, url) = try makeContext()
        defer { cleanup(url) }

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
        let (ctx, url) = try makeContext()
        defer { cleanup(url) }
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
        let (ctx, url) = try makeContext()
        defer { cleanup(url) }

        let photo = ProgressPhoto(fileName: "x.jpg")
        ctx.insert(photo)
        try ctx.save()

        let manager = ProgressPhotoManager(context: ctx)
        try manager.deletePhoto(photo)
        #expect(try manager.fetchAllPhotos().isEmpty)
    }
}
