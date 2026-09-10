//
//  HomeStaleEntryTests.swift
//  MuscleCheckTests
//
//  EVIDENCE, not regression tests (yet). Two reviews disagreed about the production
//  crash `MuscleEntry.exercisesSummary.getter / EXC_BREAKPOINT`, so these settle the
//  factual questions with a real SwiftData store instead of an argument:
//
//    A. Does the view model keep publishing an entry that was deleted through some
//       OTHER path (AddExerciseView.unadd), i.e. does the stale window exist at all?
//    B. Does `updateCurrentEntries()` actually clear it, i.e. is the ONLY problem that
//       nobody calls it on that path?
//    C. What does `isDeleted` return after the delete is SAVED? (One review proposed
//       it as the guard; the other claims it reports false once committed.)
//    D. Does touching a persisted property on that stale reference really trap?
//
//  C and D are quarantined behind `.disabled` on purpose: if they trap they take the
//  whole test runner down with them. Run them one at a time, deliberately:
//      xcodebuild test ... -only-testing:MuscleCheckTests/HomeStaleEntryTests/<name>
//
//  These use a real in-memory ModelContainer (MockContext can't fault anything, so it
//  cannot reproduce this class of bug).
//

import Testing
import SwiftData
import Foundation
@testable import MuscleCheck

@MainActor
struct HomeStaleEntryTests {

    /// Real store, same schema as the app.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func seed(_ context: ModelContext, names: [String]) throws -> [MuscleEntry] {
        let manager = MuscleEntryManager(context: context)
        for name in names {
            try manager.addEntry(name: name, category: ActivityCategory.gym.rawValue,
                                 icon: "figure.strengthtraining.traditional", metric: .strength)
        }
        return try manager.fetchAllEntries()
    }

    private func makeViewModel(_ context: ModelContext, entries: [MuscleEntry]) async -> ContentViewModel {
        let vm = ContentViewModel(context: context)
        await vm.setup(context: context, entries: entries)
        return vm
    }

    // MARK: - A. Does the stale window exist?

    /// Reproduces `AddExerciseView.unadd()`: the entry is deleted through a manager the
    /// view model knows nothing about. If the view model still publishes it, the home
    /// can render a row whose backing data is gone — which is the crash.
    /// REGRESIÓN del crash. Antes: el view model publicaba la lista y seguía conteniendo
    /// la entry borrada por `AddExerciseView.unadd()` (probado — ver el commit anterior).
    /// Ahora la home la deriva del `@Query` en cada body, así que lo que desaparece del
    /// store desaparece de la lista sin que nadie tenga que acordarse de refrescar.
    ///
    /// Si alguien vuelve a cachear la lista en el view model, esto se pone rojo.
    @Test
    func theDerivedListDropsAnEntryDeletedElsewhere() async throws {
        let context = try makeContext()
        let entries = try seed(context, names: ["Pecho", "Espalda", "Piernas"])
        _ = await makeViewModel(context, entries: entries)
        #expect(ContentViewModel.group(entries).flatMap { $0.entries }.count == 3)

        // Exactamente lo que hace el undo del sheet de alta: su propio manager, su save.
        let victim = try #require(entries.first { $0.name == "Espalda" })
        try MuscleEntryManager(context: context).delete(victim)

        // Lo que hace la vista en el body: leer del store y derivar.
        let fresh = try MuscleEntryManager(context: context).fetchAllEntries()
        let names = ContentViewModel.group(fresh).flatMap { $0.entries }.map(\.name)

        #expect(!names.contains("Espalda"))
        #expect(names.count == 2)
    }

    /// El agrupado es una función pura de lo que se le pasa: no hay estado que se
    /// desincronice, y el orden de categorías es estable.
    @Test
    func groupingIsPureAndStable() throws {
        let context = try makeContext()
        let entries = try seed(context, names: ["Pecho", "Espalda"])

        let once = ContentViewModel.group(entries)
        let twice = ContentViewModel.group(entries)

        #expect(once.map(\.category) == twice.map(\.category))
        #expect(once.flatMap { $0.entries }.count == 2)
        #expect(ContentViewModel.group([]).isEmpty)
    }

    /// The store itself is consistent — it's only the view model's copy that lags.
    @Test
    func theStoreItselfNoLongerHasIt() async throws {
        let context = try makeContext()
        let entries = try seed(context, names: ["Pecho", "Espalda"])
        _ = await makeViewModel(context, entries: entries)

        let victim = try #require(entries.first { $0.name == "Espalda" })
        try MuscleEntryManager(context: context).delete(victim)

        let fresh = try MuscleEntryManager(context: context).fetchAllEntries().map(\.name)
        #expect(fresh == ["Pecho"])
    }

    // MARK: - B. Is refreshing enough?

    /// The swipe path calls this synchronously after deleting, which is why it is the
    /// narrow case. If this clears the array, the fix is about WHO refreshes and when.
    /// `updateCurrentEntries()` ya no publica la lista, pero sí mantiene lo que la home
    /// deriva y no renderiza (widget, racha, keys de Crashlytics). Eso tiene que seguir
    /// viendo el store fresco.
    @Test
    func updateCurrentEntriesRefreshesTheDerivedState() async throws {
        let context = try makeContext()
        let entries = try seed(context, names: ["Pecho", "Espalda"])
        let vm = await makeViewModel(context, entries: entries)

        let victim = try #require(entries.first { $0.name == "Espalda" })
        try MuscleEntryManager(context: context).delete(victim)
        vm.updateCurrentEntries()

        #expect(vm.entries.map(\.name) == ["Pecho"])
    }

    // MARK: - C. Is `isDeleted` a usable guard?  (run alone)

    /// One review wants `if entry.isDeleted { skip }` as the defensive guard. The other
    /// says that after `save()` the object has left the context's deleted set, so this
    /// returns false on a row that is already gone — a guard that guards nothing.
    @Test(.disabled("Experimento ya corrido — resultado: isDeleted=false, modelContext=nil (borrado por el MISMO contexto)"))
    func isDeletedAfterASavedDelete() async throws {
        let context = try makeContext()
        let entries = try seed(context, names: ["Pecho", "Espalda"])
        _ = await makeViewModel(context, entries: entries)

        let victim = try #require(entries.first { $0.name == "Espalda" })
        try MuscleEntryManager(context: context).delete(victim)   // delete + save

        // No hay assert "correcto" acá: el valor ES el resultado del experimento.
        let deletedFlag = victim.isDeleted
        let stillAttached = victim.modelContext != nil
        Issue.record("isDeleted = \(deletedFlag), modelContext != nil = \(stillAttached)")
    }

    // MARK: - D. Does the stale reference actually trap?  (run alone)

    /// The production stack dies reading `exercises` through the @Model accessor. This
    /// is that exact read, on a reference the view model is still publishing. If it
    /// traps, the crash is reproduced at unit level and the diagnosis is closed.
    @Test(.disabled("Experimento ya corrido — resultado: NO trapea, devuelve nil"))
    func readingExercisesOnTheStaleReferenceTraps() async throws {
        let context = try makeContext()
        let entries = try seed(context, names: ["Pecho", "Espalda"])
        _ = await makeViewModel(context, entries: entries)

        let victim = try #require(entries.first { $0.name == "Espalda" })
        try MuscleEntryManager(context: context).delete(victim)

        let stale = try #require(entries.first { $0.name == "Espalda" })
        let summary = stale.exercisesSummary            // ← el frame del crash
        Issue.record("NO trapeó. exercisesSummary = \(String(describing: summary))")
    }

    // MARK: - E/F. ¿Qué SÍ trapea?
    //
    // D no trapeó: con el store en memoria y el borrado hecho por el MISMO contexto,
    // el objeto queda DESPRENDIDO (modelContext == nil, ver C) y SwiftData devuelve
    // valores vacíos en vez de ir al store. Eso no es lo que pasa en producción, donde
    // el stack muere en `_SD_get_faulting_backingdata_tsd`, o sea INTENTANDO leer del
    // store. Para que eso ocurra el objeto tiene que seguir ATADO a su contexto y su
    // fila tiene que haber desaparecido por debajo — es decir, borrada desde OTRO
    // contexto o coordinador. Estos dos experimentos modelan eso.

    /// Mismo container, dos contextos. El objeto vive en A, la fila la borra B.
    @Test(.disabled("Experimento ya corrido — resultado: modelContext!=nil, isDeleted=false, NO trapea"))
    func readingAfterDeleteFromAnotherContextSameContainer() async throws {
        let container = try ModelContainer(
            for: AppSchema.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let contextA = ModelContext(container)
        let entries = try seed(contextA, names: ["Pecho", "Espalda"])
        let stale = try #require(entries.first { $0.name == "Espalda" })

        let contextB = ModelContext(container)
        let victimInB = try #require(
            try contextB.fetch(FetchDescriptor<MuscleEntry>()).first { $0.name == "Espalda" }
        )
        contextB.delete(victimInB)
        try contextB.save()

        Issue.record("antes de leer: modelContext != nil = \(stale.modelContext != nil), isDeleted = \(stale.isDeleted)")
        let summary = stale.exercisesSummary
        Issue.record("NO trapeó. exercisesSummary = \(String(describing: summary))")
    }

    /// Dos containers sobre el MISMO archivo en disco: modela lo que hace
    /// `MuscleDataActor`, que abre su propio ModelContainer sobre el mismo default.store.
    @Test(.disabled("Experimento ya corrido — resultado: modelContext!=nil, isDeleted=false, NO trapea"))
    func readingAfterDeleteFromAnotherContainerOnDisk() async throws {
        let url = URL.temporaryDirectory.appending(path: "stale-\(UUID().uuidString).store")
        let containerA = try ModelContainer(for: AppSchema.schema,
                                            configurations: ModelConfiguration(url: url))
        let contextA = ModelContext(containerA)
        let entries = try seed(contextA, names: ["Pecho", "Espalda"])
        let stale = try #require(entries.first { $0.name == "Espalda" })

        let containerB = try ModelContainer(for: AppSchema.schema,
                                            configurations: ModelConfiguration(url: url))
        let contextB = ModelContext(containerB)
        let victimInB = try #require(
            try contextB.fetch(FetchDescriptor<MuscleEntry>()).first { $0.name == "Espalda" }
        )
        contextB.delete(victimInB)
        try contextB.save()

        Issue.record("antes de leer: modelContext != nil = \(stale.modelContext != nil), isDeleted = \(stale.isDeleted)")
        let summary = stale.exercisesSummary
        Issue.record("NO trapeó. exercisesSummary = \(String(describing: summary))")
    }
}
