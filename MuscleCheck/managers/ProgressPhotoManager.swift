//
//  ProgressPhotoManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import Foundation
import SwiftData
import UIKit

/// Custom errors for ProgressPhotoManager operations
enum ProgressPhotoError: LocalizedError {
    case saveFailed
    case invalidImage
    case photoNotFound

    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save the photo to disk"
        case .invalidImage:
            return "The selected image could not be processed"
        case .photoNotFound:
            return "The specified photo was not found"
        }
    }
}

@MainActor
final class ProgressPhotoManager {
    private let context: ModelContextProtocol

    init(context: ModelContextProtocol) {
        self.context = context
    }

    /// Returns the directory where progress photos are stored on disk
    static func photosDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("ProgressPhotos")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Saves a UIImage to disk as JPEG and returns the file name
    func saveImageToDisk(_ image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ProgressPhotoError.invalidImage
        }
        let fileName = "progress_\(UUID().uuidString).jpg"
        let fileURL = Self.photosDirectory().appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileName
    }

    /// Deletes a photo file from disk
    func deleteImageFromDisk(_ fileName: String) {
        let fileURL = Self.photosDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Adds a new progress photo: saves image to disk and creates SwiftData record
    @discardableResult
    func addPhoto(image: UIImage, note: String = "") throws -> ProgressPhoto {
        let fileName = try saveImageToDisk(image)
        let photo = ProgressPhoto(fileName: fileName, note: note)
        context.insert(photo)
        try context.save()
        return photo
    }

    /// Fetches all progress photos sorted by date taken (newest first)
    func fetchAllPhotos() throws -> [ProgressPhoto] {
        let descriptor = FetchDescriptor<ProgressPhoto>(
            sortBy: [SortDescriptor(\.dateTaken, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Deletes a progress photo: removes from SwiftData and deletes file from disk
    func deletePhoto(_ photo: ProgressPhoto) throws {
        deleteImageFromDisk(photo.fileName)
        context.delete(photo)
        try context.save()
    }
}
