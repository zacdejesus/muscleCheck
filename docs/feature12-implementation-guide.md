# Feature 12 — Guía de implementación (AI Coach: día sugerido)

Guía de los cambios de código pendientes para cerrar Feature 12. Diseño en `CLAUDE.md`,
hallazgos del tuning en `docs/feature12-prompt-tuning.md`. **Esta guía explica QUÉ hacer y POR QUÉ;
los snippets son esquemas/firmas, no implementación.**
           

## Principio rector (de los experimentos)
El modelo on-device **no razona** sobre el historial. Entonces:
- **La rotación la hace el CÓDIGO** (filtrar grupos elegibles).
- **El modelo solo** elige 2 grupos coherentes de los que le pasamos + 3 ejercicios c/u.
- Todo lo de FoundationModels va detrás de `@available(iOS 26, *)` (mismo patrón ya usado).

## Documentación Apple
- Framework: https://developer.apple.com/documentation/FoundationModels
- `LanguageModelSession`: https://developer.apple.com/documentation/foundationmodels/languagemodelsession
- Generar contenido / tareas: https://developer.apple.com/documentation/FoundationModels/generating-content-and-performing-tasks-with-foundation-models
- Guided generation (`@Generable`/`@Guide`, ejemplo completo): https://developer.apple.com/documentation/FoundationModels/generate-dynamic-game-content-with-guided-generation-and-tools
- WWDC25 "Meet the Foundation Models framework": https://developer.apple.com/videos/play/wwdc2025/286/
- WWDC25 "Deep dive into the Foundation Models framework" (streaming/PartiallyGenerated): https://developer.apple.com/videos/play/wwdc2025/301/

---

## Paso 1 — Elegibilidad / rotación (en código) ⭐ el cambio clave

**Por qué:** el modelo re-sugería lo entrenado ayer y se fijaba en "Piernas". Filtrando nosotros, eso desaparece.

**Qué:** una función pura que, dado el array de `MuscleEntry`, devuelve los grupos de **gym** elegibles para hoy = los que NO se entrenaron en los últimos ~1 día (excluye hoy y ayer). Cada `MuscleEntry` tiene `sessions: [WorkoutSession]`; la última fecha es `sessions.map(\.date).max()`.

**Dónde:** archivo nuevo **`MuscleCheck/managers/WorkoutEligibility.swift`**, siguiendo el patrón de calculators puros que ya existe (`StreakCalculator`, `StatsCalculator`): un `struct` con `static func`. Es **lógica pura**, **NO va gateada a iOS 26** (no toca FoundationModels). Lo llama `ContentViewModel.generateRoutine()` y le pasa el resultado a `MuscleCheckAI.suggestWorkout(eligible:)`.

```swift
// Esquema — implementalo vos. Va en MuscleCheck/managers/WorkoutEligibility.swift
struct WorkoutEligibility {
    static func eligibleGymGroups(from entries: [MuscleEntry],
                                  excluding excluded: Set<String> = [],   // para "dame otra"
                                  restDays: Int = 1) -> [MuscleEntry] {
        return entries.filter { e in
            e.category == ActivityCategory.gym.rawValue && !e.isDeleted
            && !excluded.contains(e.name)
            // elegible si nunca se entrenó o su última sesión fue hace > restDays
            // (usá Date.appCalendar para comparar por día)
        }
    }
}
```

Flujo end-to-end:
```
ContentViewModel.generateRoutine()
   → WorkoutEligibility.eligibleGymGroups(from: entries, excluding: ...)
   → MuscleCheckAI.suggestWorkout(eligible:)   // iOS 26 gated
   → RoutineSuggestion                         // se cachea + se muestra
```

**Fallback (importante):** si quedan **menos de 2** elegibles (entrenaste casi todo), NO filtres —
usá todos los grupos de gym (o los 2 más descansados). Si no, el modelo no tiene de dónde elegir.

---

## Paso 2 — `MuscleCheckAI.suggestWorkout` (ajustar lo que ya está)

Hoy pasa **todos** los grupos + historial. Cambiarlo para que reciba **solo los elegibles** y soporte exclusión.

```swift
// Firma sugerida (RoutineSuggestion es el struct plano que ya existe).
func suggestWorkout(eligible: [MuscleEntry]) async throws -> RoutineSuggestion
```

Dentro:
1. Numerar SOLO los elegibles (`0=Espalda, 1=Bíceps, ...`).
2. Prompt = esa lista (sin historial — la rotación ya está resuelta).
3. `streamResponse(...)` (ver Paso 4) con `WorkoutSuggestion.self`.
4. Mapear `groupIndex → eligible[i].name`, descartar fuera de rango, **recortar a 2**.
5. Devolver `RoutineSuggestion`.

**Tip de esquema (`@Guide` con `.count`):** en vez de confiar en el prompt para los conteos, fijalos en el schema. `@Guide` soporta restricciones de cantidad para arrays:
```swift
@Generable struct WorkoutSuggestion {
    @Guide(description: "...") var focus: String
    @Guide(description: "Exactamente 2 grupos coherentes", .count(2)) var blocks: [WorkoutBlock]
    @Guide(description: "...") var rationale: String
}
@Generable struct WorkoutBlock {
    @Guide(description: "Índice de la lista provista") var groupIndex: Int
    @Guide(description: "3 ejercicios específicos de ese grupo", .count(3)) var exercises: [String]
}
```
Esto reduce la dependencia del prompt (el prompt solo no garantizaba el conteo). Verificá la sintaxis exacta de `.count` en la doc de guided generation linkeada.

**Derivar `focus` en código (opcional, recomendado):** el modelo a veces puso un focus raro ("Piernas" para bíceps+tríceps). Mapeá vos los 2 grupos elegidos → "Empuje"/"Tirón"/"Piernas" y descartá el `focus` del modelo.

---

## Paso 3 — `LocalizedInstructions` (simplificar a la versión ganadora)

Reemplazar `coachInstructions` por la **instrucción ganadora** (Round 4) y `coachPrompt` por una versión **sin historial** (solo lista numerada). Texto exacto ES/EN/FR en `docs/feature12-prompt-tuning.md`. La instrucción ya NO debe pedir rotación (eso es código ahora).

---

## Paso 4 — Streaming para UX (`streamResponse`)

**Por qué:** mostrar la sugerencia llenándose progresivamente (focus → grupos → ejercicios) se siente más rápido que un spinner.

**Cómo:** `streamResponse(to:generating:)` devuelve un **AsyncSequence de snapshots**. El macro `@Generable` genera `WorkoutSuggestion.PartiallyGenerated` (mismo struct pero con todas las props **opcionales**). Cada snapshot es el estado parcial.

```swift
// Esquema.
let stream = session.streamResponse(to: prompt, generating: WorkoutSuggestion.self, options: opts)
for try await partial in stream {
    // partial.content: WorkoutSuggestion.PartiallyGenerated (props opcionales)
    // publicá lo que ya llegó para ir pintando la UI
}
// al terminar el loop tenés el resultado completo → recién ahí mapeás índices + validás
```

**Decisión de diseño:** el **mapeo índice→entry + validación** hacelo sobre el snapshot **final/completo** (los índices necesitan datos completos). Durante el stream, podés ir mostrando `focus`/`rationale`/nombres a medida que aparecen, pero la `RoutineSuggestion` definitiva (la que cacheás) se arma al final.

Doc: ver WWDC "Deep dive" (sección streaming) y la doc de `LanguageModelSession`.

---

## Paso 5 — `ContentViewModel`

- **Estado nuevo:**
  ```swift
  @Published var routineSuggestion: RoutineSuggestion?   // RoutineSuggestion ya es Codable
  @Published var isGeneratingRoutine = false
  private var lastSuggestedGroups: Set<String> = []      // para "dame otra"
  ```
- **`generateRoutine(regenerate: Bool = false) async`** (gated `#available(iOS 26)`):
  1. `WorkoutEligibility.eligibleGymGroups(from: entries, excluding: regenerate ? lastSuggestedGroups : [])` (Paso 1).
  2. `try await muscleCheckAI.suggestWorkout(eligible:)` (consumiendo el stream).
  3. Guardar en `routineSuggestion`, actualizar `lastSuggestedGroups`, **cachear** (Paso 6).
  4. Manejar error → estado de error (string localizado).
- **Sacar el path viejo:** `reviewLastMonthWorkouts()` y `workoutSuggested`. El `import`/uso ya están gateados; al borrarlos, actualizá `ContentView` (Paso 7).
- Recordá que `muscleCheckAI` se accede por el accessor lazy gateado que ya existe.

---

## Paso 6 — Cache por día (`UserDefaultsManager`)

**Por qué:** reabrir la sugerencia en el gym sin regenerar.

- `RoutineSuggestion` ya es `Codable`. Guardá: los `Data` (JSON) + la fecha.
  ```swift
  var cachedRoutineData: Data?    // JSONEncoder().encode(routineSuggestion)
  var cachedRoutineDate: Date?
  ```
- En `setup()` del ViewModel: si `cachedRoutineDate` es **hoy** (`Date.appCalendar.isDate(_:inSameDayAs:)`), decodificá y poné `routineSuggestion`; si no, queda nil.
- No necesitás App Group salvo que después quieras la sugerencia en el widget.
- Doc UserDefaults: https://developer.apple.com/documentation/foundation/userdefaults

---

## Paso 7 — UI (`RoutineSuggestionView` + `ContentView`)

**`RoutineSuggestionView` (nuevo, modal):**
- `focus` (título) + `rationale` + lista de `blocks` (nombre del grupo + sus 3 ejercicios) + botón **"Dame otra"** (llama `generateRoutine(regenerate: true)`) + cerrar.
- Estado de carga mientras `isGeneratingRoutine` (o el llenado progresivo del streaming).
- **Sin botón "Agregar"** — es solo guía (el user tilda en la lista principal como siempre).

**`ContentView`:**
- Reemplazar el botón/sheet viejo de "review" por el nuevo.
- **Sacar el Pro gate** (la feature es **free**): el bloque queda solo `if viewModel.isAppleIntelligenceAvailable() { boton }` — sin el `if storeManager.isPro { ... } else { ProFeatureGate }`.

---

## Paso 8 — Strings (`Localizable.xcstrings`)
Agregar ES/EN/FR para: título/acciones del modal ("Dame otra", cerrar), estado de carga, y mensaje de error de generación. (Los textos del prompt/instrucciones ya viven en `LocalizedInstructions`, no en xcstrings.)

---

## Paso 9 — Limpieza
- **Borrar `MuscleCheckTests/PromptExperiment.swift`** (harness temporal).

---

## Edge cases / gotchas
- **<2 elegibles** → fallback a todos los de gym (Paso 1). Probalo entrenando "todo ayer".
- **Modelo no disponible** (iOS <26, hardware no apto, AI apagado) → el botón ya se oculta vía `isAppleIntelligenceAvailable()`. No toques eso.
- **Mislabel de ejercicios** (bíceps↔tríceps): residuo conocido del modelo, read-only, tolerable. No intentes "arreglarlo" con más reglas en el prompt (empeora).
- **Cold start**: la 1ra llamada puede tirar un error transitorio. El `prewarm` que ya existe ayuda; consideralo al entrar a la pantalla.
- **Grupos custom raros**: el modelo tiende a ignorarlos y elegir los familiares. Limitación conocida (ver findings); aceptable para v1.
- **Variedad**: garantizada por el `exclude` de "dame otra" (Paso 1/5), no por temperature sola.

## Testing
- El output real **solo se valida en device** iOS 26 + Apple Intelligence (no en simulador).
- La lógica pura (Paso 1: `eligibleGymGroups`, fallback, mapeo de índices) **sí es testeable** en simulador con Swift Testing → vale la pena cubrirla (es donde vive la inteligencia real).
