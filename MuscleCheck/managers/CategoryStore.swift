//
//  CategoryStore.swift
//  MuscleCheck — Feature: user-defined categories
//
//  CRUD for user-defined categories over SwiftData, injected with
//  ModelContextProtocol like the other managers (testable with a real
//  in-memory context). Ids are UUIDs so they can never collide with a
//  built-in ActivityCategory rawValue.
//

import Foundation
import SwiftData

enum CategoryStoreError: LocalizedError {
    case invalidName
    case duplicateName(String)

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return NSLocalizedString("error_invalid_name", comment: "")
        case .duplicateName(let name):
            return String(format: NSLocalizedString("error_duplicate_entry %@", comment: ""), name)
        }
    }
}

@MainActor
final class CategoryStore: CategoryStoreProtocol {
    private let context: ModelContextProtocol

    init(context: ModelContextProtocol) {
        self.context = context
    }

    func fetchAll() throws -> [CustomCategory] {
        try context.fetch(
            FetchDescriptor<CustomCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        )
    }

    @discardableResult
    func add(name: String, icon: String, tracksWeight: Bool) throws -> CustomCategory {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CategoryStoreError.invalidName }

        let existing = try fetchAll()
        guard !existing.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            throw CategoryStoreError.duplicateName(trimmed)
        }

        // Place after the built-ins (sortOrder 0…allCases.count-1) and any existing custom.
        let nextOrder = (existing.map(\.sortOrder).max() ?? (ActivityCategory.allCases.count - 1)) + 1
        let category = CustomCategory(
            id: UUID().uuidString,
            name: trimmed,
            icon: icon,
            sortOrder: nextOrder,
            tracksWeight: tracksWeight
        )
        context.insert(category)
        try context.save()
        return category
    }

    func delete(_ category: CustomCategory) throws {
        // Entries that referenced this category become orphans; CategoryResolver
        // degrades them to the neutral "Custom" label, so no crash and no data loss.
        context.delete(category)
        try context.save()
    }
}
