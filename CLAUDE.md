# MuscleCheck — Contexto del Proyecto

## Instrucciones para Claude

> **IMPORTANTE:** El developer está aprendiendo iOS. **NO escribas código a menos que te lo pida explícitamente.** Tu rol es guiar, explicar conceptos, sugerir arquitectura y responder preguntas. Si el developer no pide código, solo orientá con palabras.

## Visión y Posicionamiento

**Tagline:** "Trackea tu entrenamiento en 2 segundos. La IA se encarga del resto."

MuscleCheck compite en el espacio opuesto a apps como Maxine (que requieren loggear cada set/rep/peso). Nuestro diferenciador es la **simplicidad radical** combinada con **IA que trabaja por el usuario**. No es solo para gym — soporta yoga, pilates, calistenia, cardio, stretching y cualquier disciplina que el usuario quiera trackear.

---

## Estrategia de Producto

### Pilar 1: "Zero-effort tracking" — La app más simple para entrenar
Maxine requiere que logees cada set/rep/peso. Mucha gente abandona eso. MuscleCheck ya tiene la ventaja de ser un simple checklist. Doblar esa apuesta:

- **Actividades personalizables** — no solo gym: yoga, pilates, calistenia, cardio, stretching con presets por disciplina
- **Siri/App Intents** — "Hoy hice pecho" y listo ✅
- **Apple Watch complication** — un tap desde la muñeca
- **Check automático con ubicación** — detectar que llegaste al gym y preguntar "¿Qué entrenaste hoy?" con un tap
- **Notificación inteligente** — a la hora habitual del gym, pregunta qué hiciste ✅
- **HealthKit integration** — detectar workouts automáticamente y sugerir qué logear

**Mensaje:** "La app de entrenamiento para gente que odia logear"

### Pilar 2: AI Coach personal — el diferenciador ya existe, amplificarlo
Ya tiene FoundationModels integrado. Maxine tiene IA básica. Ir mucho más lejos:

- **Recomendación diaria push** — "Hoy te conviene piernas, llevas 5 días sin entrenarlas"
- **Detección de desbalances** — "Entrenas pecho 3x más que espalda, cuidado con la postura"
- **Streaks y motivación** — "Llevas 4 semanas entrenando 4+ días, nuevo récord" ✅
- **Plan semanal generado** — lunes pecho, martes espalda... basado en historial real

**Mensaje:** "Tu entrenador que te conoce, no una planilla"

### Pilar 3: Progreso visual y ecosistema Apple
- **Progress photos** — fotos mensuales con slider antes/después (retention driver)
- **HealthKit sync** — importar datos de Apple Watch (heart rate, calorías)
- **Apple Watch app** — log desde la muñeca con complication
- **Widget con iconos** — ver de un vistazo qué actividades hiciste ✅

**Mensaje:** "Tu progreso, visible en todo el ecosistema Apple"

### Pilar 4: Social/accountability (futuro)
- Compartir progreso con amigos — estilo BeReal del gym
- Grupos de gym — ver qué entrenan tus amigos esta semana
- Desafíos semanales

---

## Monetización

**Modelo:** Freemium con "AI Pro" via RevenueCat

| Gratis | Pro |
|--------|-----|
| Checklist semanal | IA ilimitada |
| Historial básico | Detección de desbalances |
| Widget | Estadísticas avanzadas (Swift Charts) |
| 1 consulta IA/semana | Notificaciones inteligentes |
| Categorías + presets básicos | Plan semanal auto-generado |
| | Progress photos con timeline |
| | Apple Watch app |

**Precios sugeridos:** $1.99/mes · $14.99/año · $29.99 lifetime

---

## Arquitectura

**Patrón:** MVVM + Manager pattern con protocol-based DI (igual que `ModelContextProtocol`/`MockContext`)

**Stack:**
- SwiftUI + SwiftData
- FoundationModels (Apple Intelligence, on-device)
- AppIntents (Siri integration)
- RevenueCat (monetización)
- Firebase (Analytics + Crashlytics)
- Swift Charts (estadísticas, nativo)
- WidgetKit + App Groups (`group.zadkiel.musclecheck`)
- HealthKit (sincronización futura)
- WatchKit (Apple Watch app futura)
- PhotosUI (fotos de progreso futuras)

---

## Gitflow (Solo Developer)

```
main (always deployable, tagged for releases)
  ├── feature/<description>
  ├── fix/<description>
  ├── refactor/<description>
  └── chore/<description>
```

**Workflow:** branch → commits atómicos → PR → merge → tag si es milestone

**Commits:** `feat:`, `fix:`, `refactor:`, `test:`, `chore:`

**Versiones:**
- 1.2.0 — RevenueCat integration ✅
- 1.3.0 — Settings/Profile screen ✅
- 1.4.0 — Daily streak ✅
- 1.5.0 — Statistics (Swift Charts) ✅
- 1.6.0 — Local notifications ✅
- 1.7.0 — App Intents / Siri ✅
- 1.8.0 — Customizable Activities & Categories
- 1.9.0 — Progress Photos
- 2.0.0 — HealthKit integration
- 2.1.0 — Apple Watch app

---

## Roadmap de Features

### ✅ Feature 1: RevenueCat Integration (branch: `feature/revenuecat-integration`)
Implementado. StoreManager, PaywallView, ProFeatureGate.

### ✅ Feature 2: Settings/Profile Screen (branch: `feature/settings-profile`)
Implementado. SettingsView con Subscription, Appearance, Notifications, About.

### ✅ Feature 3: Daily Streak (branch: `feature/daily-streak`)
Implementado. StreakCalculator, StreakViewModel, StreakCardView, widget con racha.

### ✅ Feature 4: Statistics — Swift Charts (branch: `feature/statistics-charts`)
Implementado. StatsCalculator, StatsViewModel, StatsView, WeeklyTrainingChart, MuscleFrequencyChart.

### ✅ Feature 5: Local Notifications (branch: `feature/local-notifications`)
Implementado. NotificationManager con protocol, reminders de inactividad, sección en Settings.

### ✅ Feature 6: App Intents / Siri (branch: `feature/app-intents`)
Implementado. Archivos en `AppIntents/`:
- `MuscleDataActor.swift` — @ModelActor para acceso SwiftData desde intents
- `MuscleAppEntity.swift` — AppEntity representando grupo muscular
- `MuscleEntityQuery.swift` — EnumerableEntityQuery + EntityStringQuery
- `LogMuscleIntent.swift` — Intent principal: marca músculo como entrenado
- `GetWeeklyProgressIntent.swift` — Retorna progreso semanal
- `MuscleCheckShortcuts.swift` — AppShortcutsProvider con frases Siri

Frases: "Log MuscleCheck", "I trained [muscle] in MuscleCheck", "What did I train this week in MuscleCheck"

---

### ⏳ Feature 7: Customizable Activities & Categories (branch: `feature/customizable-activities`)
Expandir más allá del gym. Soportar yoga, pilates, calistenia, cardio, stretching.

**Modelo:**
- `ActivityCategory` enum — gym, yoga, pilates, calisthenics, cardio, stretching, custom
- `MuscleEntry` recibe `category: String` e `icon: String` (SF Symbol)
- Cada categoría tiene presets predefinidos con iconos apropiados

**UI:**
- `AddMuscleGroupView` — picker de categoría + selección de icono
- `MuscleEntryRowView` — muestra SF Symbol antes del nombre
- `ContentView` — agrupa entries por categoría con Section headers
- `SettingsView` — sección "Activity Presets" para agregar disciplinas completas con un tap

**Archivos nuevos:**
- `models/ActivityCategory.swift`

**Archivos modificados:**
- `models/MuscleEntry.swift` — agregar `category`, `icon`
- `models/SharedMuscleEntry.swift` (x2) — agregar `icon`
- `viewModels/ContentViewModel.swift` — grouping logic
- `managers/MuscleEntryManager.swift` — `addPresetEntries(for:)`
- `managers/UserDefaultsManager.swift` — `addedActivityPresets`
- `viewModels/SettingsViewModel.swift` — preset management
- `Views/MuscleEntryRowView.swift`, `AddMuscleGroupView.swift`, `ContentView.swift`, `SettingsView.swift`
- `MuscleCheckWidget/MuscleCheckWidget.swift` — iconos en widget
- `AppIntents/MuscleAppEntity.swift` — typeDisplayRepresentation actualizado

**Versión:** 1.8.0

---

### ⏳ Feature 8: Progress Photos (branch: `feature/progress-photos`)
Fotos mensuales del cuerpo con timeline y comparación antes/después.

**Modelo:**
- `ProgressPhoto` — @Model con `id`, `imageData: Data`, `dateTaken: Date`, `note: String?`
- Almacenamiento local vía SwiftData (las fotos nunca salen del dispositivo)

**UI:**
- `ProgressPhotosView` — grid de fotos ordenadas por fecha
- `PhotoCompareView` — slider antes/después con dos fotos seleccionadas
- `AddPhotoView` — captura desde cámara o galería via PhotosUI
- Acceso desde SettingsView o tab dedicado

**Stack:** PhotosUI, SwiftData

**Versión:** 1.9.0

---

### ⏳ Feature 9: HealthKit Integration (branch: `feature/healthkit`)
Detectar workouts automáticamente y sincronizar con el checklist.

**Funcionalidad:**
- Leer workouts de HealthKit (tipo strength training, yoga, etc.)
- Cuando se detecta un workout nuevo, enviar notificación: "Parece que entrenaste. ¿Qué hiciste?"
- Mapear `HKWorkoutActivityType` a `ActivityCategory`
- Escribir actividad de MuscleCheck a HealthKit (opcional)

**Stack:** HealthKit, background delivery

**Versión:** 2.0.0

---

### ⏳ Feature 10: Apple Watch App (branch: `feature/apple-watch`)
Log desde la muñeca con complication y UI mínima.

**Funcionalidad:**
- Complication que muestra racha actual
- Tap en complication abre lista de actividades de la semana
- Un tap para marcar como entrenado
- Sincronización vía WatchConnectivity o shared SwiftData (iOS 17+)

**Stack:** WatchKit, WatchConnectivity, WidgetKit (complications)

**Versión:** 2.1.0

---

## Convenciones de Código

- PascalCase para tipos, camelCase para propiedades/métodos
- `@State private var` para estado SwiftUI
- `ObservableObject` + `@Published` (no migrar a `@Observable` todavía, mantener consistencia)
- Managers como singletons con `.shared`
- Protocolo para cada manager nuevo (para testabilidad con mocks)
- Swift Testing framework (`@Test`, `#expect`) para unit tests
- `@MainActor` en ViewModels y Managers que tocan UI
- Sin Combine — usar async/await

---

## Notas Importantes

- `group.zadkiel.musclecheck` — App Group para widget
- Bundle ID: `com.zadkiel.musclecheck`
- Calendario empieza en lunes (`firstWeekday = 2`)
- Localización ES/EN via `Localizable.xcstrings`
- `PrimaryButtonColor` — color asset en xcassets (usado en botones principales)
- SF Symbols para iconos de actividades (nativo, no requiere assets custom)
