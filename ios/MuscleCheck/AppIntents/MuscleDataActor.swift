//
//  MuscleDataActor.swift
//  MuscleCheck
//

import Foundation
import SwiftData

@ModelActor
actor MuscleDataActor {

    // Shares AppSchema with MuscleCheckApp — both open the same default.store, so the
    // entity sets must match or SwiftData refuses to open it ("could not open default.store").
    static let sharedContainer: ModelContainer = {
        do {
            return try ModelContainer(for: AppSchema.schema)
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

        // Logging from Siri is just a session: the weekly check derives from it, so
        // the week-reset bookkeeping that used to live here is gone.
        entry.addSession(Date())
        try modelContext.save()

        return String(localized: "intent_muscle_logged \(name)")
    }

    func getWeeklyProgress() throws -> [String] {
        let entries = try modelContext.fetch(FetchDescriptor<MuscleEntry>())
        let calendar = Date.appCalendar
        let now = Date()

        return entries.filter { entry in
            entry.sessions.contains { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        }.map { $0.name }
    }
}
