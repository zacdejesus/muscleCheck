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
            return "An entry with name '\(name)' already exists"
        case .invalidName:
            return "Entry name cannot be empty or contain only whitespace"
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

    /// Adds a new muscle entry with validation
    /// - Parameter name: The name of the muscle group
    /// - Throws: MuscleEntryError.duplicateEntry if entry already exists, MuscleEntryError.invalidName if name is invalid
    func addEntry(name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw MuscleEntryError.invalidName
        }
        
        let exists = try context.fetch(FetchDescriptor<MuscleEntry>(predicate: #Predicate { $0.name == trimmedName }))
        guard exists.isEmpty else {
            throw MuscleEntryError.duplicateEntry(trimmedName)
        }

        let entry = MuscleEntry(name: trimmedName)
        context.insert(entry)
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
            entry.removeActivityDate(date)
        } else {
            entry.addActivityDate(date)
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
