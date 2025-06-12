//
//  MuscleEntryManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 30/05/2025.
//

import Foundation
import SwiftData

@MainActor
final class MuscleEntryManager {
    private let context: ModelContextProtocol

    init(context: ModelContextProtocol) {
        self.context = context
    }

    func addEntry(name: String) throws {
        let exists = try context.fetch(FetchDescriptor<MuscleEntry>(predicate: #Predicate { $0.name == name }))
        guard exists.isEmpty else { return }

        let entry = MuscleEntry(name: name)
        context.insert(entry)
        try context.save()
    }

    func fetchAllEntries() throws -> [MuscleEntry] {
        try context.fetch(FetchDescriptor<MuscleEntry>())
    }

    func fetchEntries(forWeek week: Int, year: Int) throws -> [MuscleEntry] {
        let predicate = #Predicate<MuscleEntry> {
            $0.weekOfYear == week && $0.year == year
        }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    func update(_ entry: MuscleEntry) throws {
        try context.save()
    }

    func delete(_ entry: MuscleEntry) throws {
        context.delete(entry)
        try context.save()
    }

    func toggleActivity(for entry: MuscleEntry, on date: Date = Date()) throws {
        if entry.isChecked {
            entry.removeActivityDate(date)
        } else {
            entry.addActivityDate(date)
        }
        entry.isChecked.toggle()
        try context.save()
    }
}
