//
//  ProgressPhoto.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import Foundation
import SwiftData
import UIKit

@Model
class ProgressPhoto: Identifiable, Hashable, Equatable {
    @Attribute(.unique) var id: UUID
    var fileName: String
    var dateTaken: Date
    var note: String

    init(fileName: String, dateTaken: Date = Date(), note: String = "") {
        self.id = UUID()
        self.fileName = fileName
        self.dateTaken = dateTaken
        self.note = note
    }

    static func == (lhs: ProgressPhoto, rhs: ProgressPhoto) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Full file URL in the app's Documents/ProgressPhotos directory
    var fileURL: URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return dir?.appendingPathComponent("ProgressPhotos").appendingPathComponent(fileName)
    }

    /// Load the UIImage from disk
    func loadImage() -> UIImage? {
        guard let url = fileURL else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
