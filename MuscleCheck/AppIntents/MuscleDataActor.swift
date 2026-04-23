//
//  MuscleDataActor.swift
//  MuscleCheck
//

import Foundation
import SwiftData

@ModelActor
actor MuscleDataActor {

    static let sharedContainer: ModelContainer = {
        do {
            return try ModelContainer(for: MuscleEntry.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    func fetchAllMuscleNames() throws -> [String] {
        let entries = try modelContext.fetch(FetchDescriptor<MuscleEntry>())
        let names = Set(entries.map { $0.name })
        return Array(names).sorted()
    }

    func logMuscle(named name: String) throws -> String {
        let predicate = #Predicate<MuscleEntry> { $0.name == name }
        let entries = try modelContext.fetch(FetchDescriptor(predicate: predicate))

        guard let entry = entries.first else {
            return String(localized: "intent_muscle_not_found \(name)")
        }

        let calendar = Date.appCalendar
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())

        // Reset if a new week started since the app was last opened
        if entry.weekOfYear != currentWeek || entry.year != currentYear {
            entry.isChecked = false
            entry.weekOfYear = currentWeek
            entry.year = currentYear
        }

        let today = Date()
        entry.addActivityDate(today)
        entry.isChecked = true
        try modelContext.save()

        return String(localized: "intent_muscle_logged \(name)")
    }

    func getWeeklyProgress() throws -> [String] {
        let entries = try modelContext.fetch(FetchDescriptor<MuscleEntry>())
        let calendar = Date.appCalendar
        let now = Date()

        return entries.filter { entry in
            entry.activityDates.contains { date in
                calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }
        }.map { $0.name }
    }
}
