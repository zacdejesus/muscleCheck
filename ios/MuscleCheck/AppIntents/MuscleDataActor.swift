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
    //
    // Opening it used to `fatalError`: cualquier invocación de Siri o Atajos con un
    // schema que no abre mataba el proceso, y encima antes de que Crashlytics existiera,
    // así que no quedaba ni un evento. Ahora el fallo se guarda y se convierte en un
    // error del intent — Siri dice que no pudo, la app sigue viva y el motivo se reporta.
    private static let containerResult = Result { try ModelContainer(for: AppSchema.schema) }

    /// El actor listo para usar, o un error del intent si el store no abre.
    static func makeActor() throws -> MuscleDataActor {
        switch containerResult {
        case .success(let container):
            return MuscleDataActor(modelContainer: container)
        case .failure(let error):
            CrashDiagnostics.record(error, operation: "app_intent_container")
            throw error
        }
    }

    func fetchAllMuscleNames() throws -> [String] {
        let entries = try modelContext.fetch(FetchDescriptor<MuscleEntry>())
        let names = Set(entries.map { $0.name })
        return Array(names).sorted()
    }

    /// Lo que deja un registro por Siri: el diálogo para el usuario y, si la semana del grupo
    /// pasó a "entrenada", lo que necesita `activity_checked`. El actor no habla con la
    /// analítica: decide el intent.
    struct LogOutcome: Sendable {
        let message: String
        let newlyTrained: NewlyTrained?
    }

    struct NewlyTrained: Sendable, Equatable {
        let category: String
        let metric: MetricType
    }

    func logMuscle(named name: String) throws -> LogOutcome {
        let predicate = #Predicate<MuscleEntry> { $0.name == name }
        let entries = try modelContext.fetch(FetchDescriptor(predicate: predicate))

        guard let entry = entries.first else {
            return LogOutcome(message: String(localized: "intent_muscle_not_found \(name)"), newlyTrained: nil)
        }

        let now = Date()
        let wasTrained = entry.isTrained(inWeekOf: now)
        // Logging from Siri is just a session: the weekly check derives from it, so
        // the week-reset bookkeeping that used to live here is gone.
        entry.addSession(now)
        try modelContext.save()

        return LogOutcome(
            message: String(localized: "intent_muscle_logged \(name)"),
            newlyTrained: wasTrained ? nil : NewlyTrained(category: entry.category, metric: entry.metric)
        )
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
