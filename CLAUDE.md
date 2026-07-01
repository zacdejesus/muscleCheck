# MuscleCheck — Contexto del Proyecto

## Foco actual (hasta el próximo release al App Store)

> **MODO CALIDAD DE CÓDIGO.** No proponer ni planificar features nuevos. La única excepción es **Feature 11: Peso por grupo muscular** (ver roadmap). Todo el resto del esfuerzo va a:
> - Refactors arquitectónicos (god objects, two-phase init, denormalización)
> - Testing y cobertura
> - Limpieza de warnings y code smells
> - Consistencia de patrones entre managers
> - **CI/CD: agregar pipeline en GitHub Actions** (build + tests en cada PR; idealmente lint y, a futuro, distribución a TestFlight)
> Apple Watch y cualquier otra feature quedan diferidos hasta después del próximo release.

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
- **Coach IA: día sugerido** — el botón de IA sugiere un *par muscular coherente* del día con ejercicios de ejemplo, en vez de un solo músculo. **Free, on-device, no tilda nada** (solo guía). Diseño completo en **Feature 12** del roadmap.
- **Detección de desbalances** — "Entrenas pecho 3x más que espalda, cuidado con la postura"
- **Streaks y motivación** — racha **semanal** (semanas consecutivas con ≥1 entreno; el descanso NO la rompe, alineado con el modelo de checklist semanal). El cálculo viejo era diario-consecutivo y chocaba con la app (vivía en 0). La card muestra la unidad ("semanas seguidas"). Gracia para la semana en curso: solo cae a 0 si esta semana **y** la anterior están vacías. ✅
- **Plan semanal generado** — lunes pecho, martes espalda... basado en historial real

> **Idea de gamificación/retención (sin construir):** premiar rachas largas con Pro — p.ej. al llegar a **12 semanas** de racha, regalar **1 mes de Pro gratis**. Refuerza el hábito y es un canal de conversión a Pro de bajo costo (RevenueCat soporta promotional/grant de entitlements). Definir: ¿una sola vez o recurrente?, ¿se resetea el "cobro" del premio si se corta la racha?

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

> **Gateo real hoy (no aspiracional):** solo **HealthKit (detección automática)** y **Progress photos** están detrás de Pro en el código. **Estadísticas y notificaciones shipean gratis** — el paywall (`PlanComparisonView`) ya lo refleja. Los ítems Pro marcados *(planeado/diferido)* todavía no existen. Si en el futuro se decide gatear stats/notifs, hay que tocar `StatsView`/Settings **y** la tabla del paywall **y** esta tabla a la vez.

| Gratis | Pro |
|--------|-----|
| Checklist semanal | HealthKit: detección automática |
| Historial (calendario + detalle) | Progress photos con timeline |
| Widget | Detección de desbalances *(planeado)* |
| Coach IA: día sugerido + ejercicios (ilimitado) | Plan semanal auto-generado *(planeado)* |
| Categorías + presets básicos | Apple Watch app *(diferido)* |
| Estadísticas (Swift Charts) | |
| Notificaciones / recordatorios | |

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
- HealthKit (workout detection + sync)
- PhotosUI (progress photos)
- WatchKit (Apple Watch app futura)

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
- 1.8.0 — Customizable Activities & Categories ✅
- 1.9.0 — Progress Photos ✅
- 2.0.0 — HealthKit integration ✅
- 2.1.0 — Peso por grupo muscular + refactors de calidad
- 2.2.0 — Apple Watch app (diferido)

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

### ✅ Feature 7: Customizable Activities & Categories (branch: `feature/app-intents`)
Implementado. ActivityCategory enum con 7 disciplinas, presets por categoría, icon selection grid, grouped sections en ContentView.

Archivos: `models/ActivityCategory.swift` (nuevo), modificados: MuscleEntry, SharedMuscleEntry (x2), ContentViewModel, MuscleEntryManager, UserDefaultsManager, SettingsViewModel, MuscleEntryRowView, AddMuscleGroupView, ContentView, SettingsView, Widget, MuscleAppEntity.

---

### ✅ Feature 8: Progress Photos (branch: `feature/app-intents`)
Implementado. ProgressPhoto SwiftData model (imágenes en disco, no en DB). ProgressPhotoManager con CRUD + file I/O. Gallery con grid mensual, PhotoCompareView con slider antes/después, AddProgressPhotoView con PhotosPicker. Pro-gated.

Archivos nuevos: `models/ProgressPhoto.swift`, `managers/ProgressPhotoManager.swift`, `viewModels/ProgressPhotoViewModel.swift`, `Views/ProgressPhotosView.swift`, `Views/PhotoCompareView.swift`, `Views/AddProgressPhotoView.swift`. Modificados: MuscleCheckApp, ContentView.

---

### ✅ Feature 9: HealthKit Integration (branch: `feature/healthkit`)
Implementado. HealthKitManager singleton con authorization, workout fetching (últimos 7 días), mapeo HKWorkoutActivityType→ActivityCategory. HealthKitSuggestionsView banner en ContentView con botones Log/Dismiss. Pro-gated toggle en Settings. Foreground-first (sin background delivery en v1).

Archivos nuevos: `managers/HealthKitManager.swift`, `managers/protocols/HealthKitManagerProtocol.swift`, `Views/HealthKitSuggestionsView.swift`. Modificados: MuscleCheck.entitlements, Info.plist, UserDefaultsManager, SettingsViewModel, SettingsView, ContentView, ContentViewModel.

---

### ⏳ Feature 10: Apple Watch App (branch: `feature/apple-watch`) — DIFERIDO
Diferido hasta después del release 2.1.0. Log desde la muñeca con complication y UI mínima.

**Funcionalidad:**
- Complication que muestra racha actual
- Tap en complication abre lista de actividades de la semana
- Un tap para marcar como entrenado
- Sincronización vía WatchConnectivity o shared SwiftData (iOS 17+)

**Stack:** WatchKit, WatchConnectivity, WidgetKit (complications)

**Versión:** 2.2.0

---

### ⏳ Feature 11: Peso por grupo muscular (branch: `feature/muscle-weight`)
Trackear la carga (peso) usada en cada grupo muscular para ver progreso real, no solo asistencia.

**Funcionalidad (2.1.0):**
- Campo de peso opcional por entrada (último peso usado), solo para la categoria gym, la de yoga por ejemplo no lo necesita ✅
- Historial de pesos por sesión, junto a `activityDates` ✅ (`WorkoutSession.weight`)
- UI mínima: input numérico al marcar como entrenado (no romper el flujo "2 segundos") ✅ (`ModalWeightView`, auto-focus al abrir)
- Toggle kg / lbs en Settings ✅ (`WeightUnit`, sección Units)
- Label pequeño con el peso al lado del nombre del músculo, solo para gym ✅ (`MuscleEntry.formattedLastWeight` + `MuscleEntryRowView`)
- Tap en ícono / nombre / label abre el modal (solo gym) ✅
- Strings localizadas ES/EN/FR para el modal y Settings ✅

**Diferido a 2.2.0:**
- Stats: evolución de peso por grupo muscular (Swift Charts, línea temporal)
- Swipe leading para abrir el modal — descartado por UX (tap ya cubre el caso, swipe leading requería botón visible feo)

**Decisiones abiertas:**
- El peso es opcional que arranca con un valor default
- agrega (empezar simple: un peso por sesión)
- ¿Modelo nuevo `WeightEntry` o array embebido en `MuscleEntry`?

**Stack:** SwiftData (modelo nuevo o extensión), Swift Charts

**Versión:** 2.1.0 (próximo release al App Store)

---

### ⏳ Feature 12: AI Coach — día de entrenamiento sugerido (DISEÑADO, diferido)
Reemplaza el botón actual de "review" (`reviewLastMonthWorkouts`). En vez de devolver un mensaje de texto con un solo músculo, sugiere un día coherente con ejercicios.

**Comportamiento:**
- **Coach, no logger:** sugiere, **nunca tilda**. El usuario marca los grupos a mano (tildar = "lo entrené"; no se ensucia la semántica).
- **Free** (no Pro): el modelo on-device no tiene costo por llamada, así que no se gatea.
- Genera desde el historial (sin inputs/chips en v1).
- **PPL como ancla blanda** → **exactamente 2 grupos coherentes** (par muscular: pecho+tríceps, espalda+bíceps, piernas+abdomen), **3 ejercicios de ejemplo** por grupo (read-only, ideas — no programa obligatorio).
- Lógica del prompt: rotación entre días (inferida del historial) → coherencia dentro del día → excluir lo ya entrenado hoy → descanso como desempate.
- **"Dame otra"** = regenerar (un tap).
- **Cacheada por el día** (UserDefaults): reabrible en el gym, misma sugerencia hasta "dame otra" o cambio de día.
- **Solo gym.** iOS 26 gated (FoundationModels) con degradación elegante (botón oculto si no hay IA).

**Output (`@Generable`, iOS 26):**
```swift
@Generable struct WorkoutSuggestion {
  var focus: String          // "Push", "Pull", "Piernas"
  var blocks: [Block]        // exactamente 2
  var rationale: String
}
@Generable struct Block {
  var groupIndex: Int        // índice en los grupos de gym numerados → robusto, sin fuzzy matching
  var exercises: [String]    // ~3 ejemplos
}
```
Validar `groupIndex` en rango y `blocks.count == 2`; descartar/recortar lo inválido. Mapear índice → `MuscleEntry`.

**Arquitectura:**
- `MuscleCheckAI.suggestWorkout(...)` (iOS 26) → `WorkoutSuggestion`. Mapear a un struct plano version-agnostic (`RoutineSuggestion`) para que `ContentViewModel` (iOS 18) lo guarde — mismo patrón de gating ya usado para FoundationModels.
- Prompt: grupos numerados + historial (descanso por grupo, entrenado-hoy) + instrucciones (PPL blando, 2 grupos, rotación, excluir hoy, 3 ejercicios/grupo, idioma por locale).
- Modal: focus + rationale + 2 grupos con sus ejercicios + "Dame otra" + cerrar. Sin botón "agregar".
- **Usar `streamResponse` (no `respond`)** para mostrar la sugerencia generándose progresivamente (mejor UX que un spinner).

**Modelo:** on-device ~3B de Apple (FoundationModels). Suficiente para esta tarea acotada (conocimiento común de ejercicios + split simple + output estructurado); flojo en razonamiento profundo, mitigado con tarea acotada + "dame otra".

**Diferido a v2:** chips (tiempo/energía), discovery de grupos nuevos ("considerá agregar X"), historial completo de sugerencias, catálogo curado de ejercicios (el modelo selecciona por índice en vez de generar), pista de rotación precomputada.

**Fuente candidata de catálogo (pendiente licencia):** ExerciseDB v1 (mirror `github.com/hasaneyldrm/exercises-dataset`, 1.324 ejercicios, JSON + GIF/JPG, instrucciones EN/ES/IT/TR, metadata body part/target/secondary muscles). Encaja con el "catálogo curado" diferido: el modelo elegiría ejercicios por índice en vez de generarlos → cero alucinación + GIFs read-only. **Blockers:** (1) el mirror es non-commercial → habría que licenciar ExerciseDB en la fuente (AscendAPI/RapidAPI) ya que la app es monetizada; (2) los 1.324 assets inflarían el bundle → embeber solo un subset chico por grupo muscular o fetch on-demand; (3) usar solo como ideas visuales gym-only, no derivar a logging de ejercicios (eso es Feature 13).

**Stack:** FoundationModels (`@Generable`), SwiftUI, UserDefaults (cache).

**Tuning de prompt (hecho, en device real):** ver `docs/feature12-prompt-tuning.md`. Hallazgo clave: el modelo on-device **no puede rotar** (no razona el historial) → la **rotación y la variedad van en código** (filtrar grupos elegibles, pasarle solo esos; excluir lo recién sugerido para "dame otra"). El modelo solo elige 2 coherentes + 3 ejercicios. El doc tiene la instrucción ganadora.

**Versión:** post-2.1.0 (diseñado, no construido — modo calidad de código).

---

### ✅ Feature 17: Categorías definidas por el usuario (branch: `feature/custom-categories`, PR #23)
Implementado. El usuario crea categorías propias (nombre + ícono + toggle "registrar peso") más allá de las 7 built-in, en **Settings → Activity Presets → Custom Categories**. Las custom aparecen en el picker de alta; si optan por peso, se comportan como gym.

**Arquitectura (test-first, aditiva — no rompe versiones anteriores):**
- `CustomCategory` (`@Model`) cuyo `id` es el mismo string que ya guarda `MuscleEntry.category` → migración **aditiva**, entries viejas intactas.
- `CategoryResolver` (puro): unifica built-in (enum) + custom; built-in siempre gana; categoría borrada degrada a "Custom" sin crashear.
- `CategoryStore` (CRUD sobre `ModelContextProtocol`, ids UUID anti-colisión, validación, orden post built-ins).
- `ActivityCategory.tracksWeight` reemplaza los `== .gym` hardcodeados en `MuscleEntryRowView` / `WeekDetailSection`. El AI Coach se deja **gym-only** (es por diseño, no por peso).
- Widget sin cambios (renderiza ícono+nombre por entry).

Archivos nuevos: `models/CustomCategory.swift`, `models/CategoryResolver.swift`, `managers/CategoryStore.swift`, `managers/protocols/CategoryStoreProtocol.swift`, `Views/ManageCategoriesView.swift`, tests `CategoryResolverTests`/`CategoryStoreTests`. Modificados: ActivityCategory, MuscleCheckApp (schema), MuscleEntryRowView, WeekDetailSection, ContentView, HistoryView, AddMuscleGroupView, SettingsView, Localizable.xcstrings.

**Decisiones abiertas:** categorías custom empiezan vacías; borrar una **no** borra sus entries (quedan huérfanas → "Custom", no-destructivo). Evaluar cascade-delete o reasignación.

**Versión:** 2.1.x

---

## Backlog de feedback de usuarios (EN EVALUACIÓN — no construir aún)

> Recomendaciones que salieron del review de la tester (Ro) y no se aplicaron en el release 2.1.x. Quedan acá registradas con su trade-off para decidir más adelante. **No son features aprobados** — varios tensionan el posicionamiento core. Lo que sí se aplicó de ese review: fix de sensibilidad de tap ("se borra todo"), validación de add-group con error inline, y comparación Free vs Pro en el paywall.

### 🤔 Feature 13: Logging detallado (sets / reps / peso por set) — EN EVALUACIÓN
La tester pidió poder loggear cada set/rep/peso, estilo planilla.

**Tensión estratégica (importante):** esto es **exactamente lo que NO somos**. El Pilar 1 ("zero-effort tracking", "la app para gente que odia logear") se define *en oposición* a Maxine/planillas. Feature 11 (peso por grupo, opcional, un valor por sesión) ya es el límite deliberado de cuánto detalle pedimos sin romper el flujo "2 segundos".

**Si se hace, cómo:** solo como **modo avanzado opcional**, off por default, jamás en el camino feliz del check. Gatear detrás de una preferencia explícita ("modo detallado") para no contaminar la UX de quien solo quiere tildar. Construir **solo si varios usuarios lo piden** — una sola voz no justifica mover el posicionamiento.

**Recomendación:** diferir hasta tener señal de demanda real. No es el diferenciador; es competir en el terreno de Maxine.

### 🤔 Feature 14: "Iniciar entrenamiento" — sesión en vivo (estilo Strava/Adidas/Garmin) — EN EVALUACIÓN
Un botón "empezar entreno" que abre una sesión activa (timer, en curso, "finalizar").

**Tensión:** introduce el concepto de **sesión cronometrada** en una app cuyo modelo mental es un **checklist semanal**, no un tracker de actividad en tiempo real. Acopla con HealthKit (Feature 9 ya detecta workouts post-hoc) — pisarse con eso sería confuso.

**Valor potencial:** engagement/ritual; algunos usuarios quieren el "modo gym" activo. Pero es un cambio de paradigma, no un add-on.

**Recomendación:** diferir. Si se explora, primero validar que no canibaliza la simplicidad del check. Mantener separado del flujo actual.

### 🤔 Feature 15: Perfil con peso corporal + altura — EN EVALUACIÓN
Métricas del usuario (peso corporal, altura) en el perfil.

**Trade-off:** bajo costo de implementación (campos en Settings/perfil), pero **sin uso claro hoy** — no alimenta ninguna feature. Sin un consumidor (IMC, evolución de peso corporal en Stats, contexto para el AI Coach) es data muerta.

**Recomendación:** construir **solo junto a la feature que la consuma** (p.ej. tracking de peso corporal en el tiempo, o input para recomendaciones). No agregar campos huérfanos. Nota: HealthKit ya puede ser la fuente de peso/altura si en algún momento se necesita.

### 🤔 Feature 16: Filtro día a día en el Historial — SEGUIMIENTO MENOR
Ver el detalle de un día específico (no solo la semana).

**Estado:** el rediseño del calendario (Feature de historial, PR #20) ya da navegación mensual + detalle **por semana** al tocar un día. Esto sería el incremento natural: tap en un día → detalle solo de ESE día.

**Trade-off:** la decisión de UX consciente fue mostrar la **semana** al tocar (más contenido por tap, resaltado de semana funcional). Pasar a día-único reduce densidad de info. Posible alternativa: mantener semana, pero permitir colapsar a un día.

**Recomendación:** seguimiento de bajo riesgo del calendario ya existente. Evaluar a ojo si la vista semanal se siente suficiente antes de agregar otro nivel.

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

## Instrucciones para Claude
**IMPORTANTE:** El developer es senior, con foco histórico en desarrollo de SDKs. Está refrescando la parte de UI/SwiftUI, no aprendiendo iOS desde cero — asumí ese nivel. **NO escribas código a menos que te lo pida explícitamente.** Tu rol es discutir arquitectura como par, hacer code review crítico, proponer trade-offs y responder dudas puntuales (sobre todo del lado de vistas/UI cuando aplique). Si el developer no pide código, solo orientá con palabras.

---

## Notas Importantes
- `group.zadkiel.musclecheck` — App Group para widget
- Bundle ID: `com.zadkiel.musclecheck`
- Calendario empieza en lunes (`firstWeekday = 2`)
- Localización ES/EN/FR via `Localizable.xcstrings`
- `PrimaryButtonColor` — color asset en xcassets (usado en botones principales)
- SF Symbols para iconos de actividades (nativo, no requiere assets custom)
