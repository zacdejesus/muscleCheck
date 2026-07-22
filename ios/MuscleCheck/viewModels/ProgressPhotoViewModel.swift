//
//  ProgressPhotoViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import Foundation
import SwiftData
import UIKit

@MainActor
final class ProgressPhotoViewModel: ObservableObject {
    private var context: ModelContextProtocol?
    private var manager: ProgressPhotoManager?

    @Published private(set) var photos: [ProgressPhoto] = []
    @Published private(set) var groupedPhotos: [(month: String, photos: [ProgressPhoto])] = []

    // Compare mode
    @Published var comparePhotoA: ProgressPhoto?
    @Published var comparePhotoB: ProgressPhoto?
    @Published var isCompareMode: Bool = false

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    func setup(context: ModelContextProtocol) {
        self.context = context
        self.manager = ProgressPhotoManager(context: context)
        loadPhotos()
    }

    func loadPhotos() {
        guard let manager else { return }
        do {
            photos = try manager.fetchAllPhotos()
            groupPhotos()
        } catch {
            photos = []
            groupedPhotos = []
        }
    }

    func addPhoto(image: UIImage, note: String) {
        guard let manager else { return }
        do {
            try manager.addPhoto(image: image, note: note)
            loadPhotos()
        } catch {
            // Error handled silently — photo not added
        }
    }

    func deletePhoto(_ photo: ProgressPhoto) {
        guard let manager else { return }
        do {
            try manager.deletePhoto(photo)
            loadPhotos()

            // Clear compare selections if deleted photo was selected
            if comparePhotoA?.id == photo.id { comparePhotoA = nil }
            if comparePhotoB?.id == photo.id { comparePhotoB = nil }
        } catch {
            // Error handled silently
        }
    }

    func toggleCompareSelection(_ photo: ProgressPhoto) {
        if comparePhotoA?.id == photo.id {
            comparePhotoA = nil
        } else if comparePhotoB?.id == photo.id {
            comparePhotoB = nil
        } else if comparePhotoA == nil {
            comparePhotoA = photo
        } else if comparePhotoB == nil {
            comparePhotoB = photo
        }
    }

    var canCompare: Bool {
        comparePhotoA != nil && comparePhotoB != nil
    }

    func clearCompareSelection() {
        comparePhotoA = nil
        comparePhotoB = nil
        isCompareMode = false
    }

    // MARK: - Private

    private func groupPhotos() {
        let grouped = Dictionary(grouping: photos) { photo in
            Self.monthFormatter.string(from: photo.dateTaken)
        }

        // Maintain order: newest month first (photos are already sorted desc)
        var seen = Set<String>()
        var orderedKeys: [String] = []
        for photo in photos {
            let key = Self.monthFormatter.string(from: photo.dateTaken)
            if seen.insert(key).inserted {
                orderedKeys.append(key)
            }
        }

        groupedPhotos = orderedKeys.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (month: key, photos: items)
        }
    }
}
