//
//  MuscleEntryManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 30/05/2025.
//

import Foundation
import SwiftData

/// Custom errors for MuscleEntryManager operations
enum MuscleEntryError: LocalizedError {
    case duplicateEntry(String)
    case invalidName
    case invalidWeekOrYear
    case entryNotFound
    
    var errorDescription: String? {
        switch self {
        case .duplicateEntry(let name):
            return String(format: NSLocalizedString("error_duplicate_entry %@", comment: ""), name)
        case .invalidName:
            return NSLocalizedString("error_invalid_name", comment: "")
        case .invalidWeekOrYear:
            return "Week must be between 1-53 and year must be positive"
        case .entryNotFound:
            return "The specified entry was not found"
        }
    }
}

@MainActor
final class MuscleEntryManager {
    private let context: ModelContextProtocol

    init(context: ModelContextProtocol) {
        self.context = context
    }

    /// Canonical name normalization for duplicate detection — the ONE definition of
    /// "already exists", shared with the add screen's preset-chip filter (so a chip
    /// never shows for a name the save path would reject, and vice versa).
    static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Adds a new muscle entry with validation
    /// - Parameters:
    ///   - name: The name of the exercise/muscle group
    ///   - metric: What the entry logs. Nil = the category's default (resolved here
    ///     so custom-category entries don't silently fall to `.none`).
    /// - Throws: MuscleEntryError.duplicateEntry if entry already exists (case-insensitive), MuscleEntryError.invalidName if name is invalid
    func addEntry(name: String, category: String = ActivityCategory.gym.rawValue, icon: String = ActivityCategory.gym.defaultIcon, metric: MetricType? = nil) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw MuscleEntryError.invalidName
        }

        // Case-insensitive: "chest" vs "Chest" are the same exercise to the user.
        // The entry set is small, so fetching all beats predicate contortions.
        let normalized = Self.normalizedName(trimmedName)
        let existing = try context.fetch(FetchDescriptor<MuscleEntry>())
        guard !existing.contains(where: { Self.normalizedName($0.name) == normalized }) else {
            throw MuscleEntryError.duplicateEntry(trimmedName)
        }

        let resolvedMetric = try metric ?? defaultMetric(forCategory: category)
        let entry = MuscleEntry(name: trimmedName, category: category, icon: icon, metric: resolvedMetric)
        context.insert(entry)
        try context.save()
    }

    /// Adds all preset entries for a given activity category, skipping duplicates
    /// (same case-insensitive rule as `addEntry`).
    func addPresetEntries(for category: ActivityCategory) throws {
        let existing = try context.fetch(FetchDescriptor<MuscleEntry>())
        var existingNames = Set(existing.map { Self.normalizedName($0.name) })

        for preset in category.presetEntries {
            let name = NSLocalizedString(preset.nameKey, comment: "")
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }
            guard existingNames.insert(Self.normalizedName(trimmedName)).inserted else { continue }

            let entry = MuscleEntry(name: trimmedName, category: category.rawValue, icon: preset.icon)
            context.insert(entry)
        }
        try context.save()
    }

    /// Category default metric, resolver-aware so custom categories count.
    private func defaultMetric(forCategory category: String) throws -> MetricType {
        let customs = try context.fetch(FetchDescriptor<CustomCategory>())
        return CategoryResolver.resolve(category, custom: customs).defaultMetric
    }

    /// Persists the lazily-derived metric for pre-metric entries (empty `metricRaw`).
    /// Idempotent and cheap — the empty raw IS the "needs backfill" flag, so there's
    /// nothing to do on every launch after the first.
    func backfillMetricTypes() throws {
        let pending = try context.fetch(
            FetchDescriptor<MuscleEntry>(predicate: #Predicate { $0.metricRaw == "" })
        )
        guard !pending.isEmpty else { return }

        let customs = try context.fetch(FetchDescriptor<CustomCategory>())
        for entry in pending {
            entry.metric = CategoryResolver.resolve(entry.category, custom: customs).defaultMetric
        }
        try context.save()
    }

    /// Fetches all muscle entries
    /// - Returns: Array of all muscle entries
    /// - Throws: Database fetch errors
    func fetchAllEntries() throws -> [MuscleEntry] {
        try context.fetch(FetchDescriptor<MuscleEntry>())
    }

    /// Fetches muscle entries for a specific week and year
    /// - Parameters:
    ///   - week: Week number (1-53)
    ///   - year: Year number
    /// - Returns: Array of muscle entries for the specified week/year
    /// - Throws: MuscleEntryError.invalidWeekOrYear if parameters are invalid, database fetch errors
    func fetchEntries(forWeek week: Int, year: Int) throws -> [MuscleEntry] {
        guard week >= 1 && week <= 53 && year > 0 else {
            throw MuscleEntryError.invalidWeekOrYear
        }
        
        let predicate = #Predicate<MuscleEntry> {
            $0.weekOfYear == week && $0.year == year
        }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    /// Updates an existing muscle entry
    /// - Parameter entry: The muscle entry to update
    /// - Throws: Database save errors
    func update(_ entry: MuscleEntry) throws {
        // Note: In SwiftData, changes to model objects are automatically tracked
        // This method exists for explicit save operations
        try context.save()
    }

    /// Deletes a muscle entry
    /// - Parameter entry: The muscle entry to delete
    /// - Throws: Database save errors
    func delete(_ entry: MuscleEntry) throws {
        context.delete(entry)
        try context.save()
    }

    /// Toggles the activity status for a muscle entry on a specific date
    /// - Parameters:
    ///   - entry: The muscle entry to toggle
    ///   - date: The date to toggle activity for (defaults to current date)
    /// - Throws: Database save errors
    func toggleActivity(for entry: MuscleEntry, on date: Date = Date()) throws {
        // Fix: Check the current state before toggling
        let wasChecked = entry.isChecked
        
        if wasChecked {
            entry.removeSession(matching: date)
        } else {
            entry.addSession(date)
        }
        
        entry.isChecked.toggle()
        try context.save()
    }
    
    /// Adds multiple default muscle entries in a batch operation
    /// - Parameter names: Array of muscle group names
    /// - Throws: Database save errors
    func addDefaultEntries(names: [String]) throws {
        var entriesToInsert: [MuscleEntry] = []
        
        for name in names {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }
            
            // Check for duplicates in the batch
            let exists = try context.fetch(FetchDescriptor<MuscleEntry>(predicate: #Predicate { $0.name == trimmedName }))
            guard exists.isEmpty else { continue }
            
            let entry = MuscleEntry(name: trimmedName)
            entriesToInsert.append(entry)
        }
        
        // Insert all entries at once
        for entry in entriesToInsert {
            context.insert(entry)
        }
        
        try context.save()
    }
}
