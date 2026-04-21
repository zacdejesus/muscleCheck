# MuscleCheck — Contexto del Proyecto

## Instrucciones para Claude

> **IMPORTANTE:** El developer está aprendiendo iOS. **NO escribas código a menos que te lo pida explícitamente.** Tu rol es guiar, explicar conceptos, sugerir arquitectura y responder preguntas. Si el developer no pide código, solo orientá con palabras.

## Visión y Posicionamiento

**Tagline:** "Trackea tu gym en 2 segundos. La IA se encarga del resto."

MuscleCheck compite en el espacio opuesto a apps como Maxine (que requieren loggear cada set/rep/peso). Nuestro diferenciador es la **simplicidad radical** combinada con **IA que trabaja por el usuario**.

---

## Estrategia de Producto

### Pilar 1: "Zero-effort tracking" — La app más simple del gym
Maxine requiere que logees cada set/rep/peso. Mucha gente abandona eso. MuscleCheck ya tiene la ventaja de ser un simple checklist. Doblar esa apuesta:

- **Check automático con ubicación** — detectar que llegaste al gym y preguntar "¿Qué entrenaste hoy?" con un tap
- **Siri/App Intents** — "Hoy hice pecho" y listo
- **Apple Watch complication** — un tap desde la muñeca
- **Notificación inteligente** — a la hora habitual del gym, pregunta qué hiciste

**Mensaje:** "La app de gym para gente que odia logear"

### Pilar 2: AI Coach personal — el diferenciador ya existe, amplificarlo
Ya tiene FoundationModels integrado. Maxine tiene IA básica. Ir mucho más lejos:

- **Recomendación diaria push** — "Hoy te conviene piernas, llevas 5 días sin entrenarlas"
- **Detección de desbalances** — "Entrenas pecho 3x más que espalda, cuidado con la postura"
- **Streaks y motivación** — "Llevas 4 semanas entrenando 4+ días, nuevo récord"
- **Plan semanal generado** — lunes pecho, martes espalda... basado en historial real

**Mensaje:** "Tu entrenador que te conoce, no una planilla"

### Pilar 3: Social/accountability (futuro)
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
| | Plan semanal auto-generado |

**Precios sugeridos:** $1.99/mes · $14.99/año · $29.99 lifetime

---

## Arquitectura

**Patrón:** MVVM + Manager pattern con protocol-based DI (igual que `ModelContextProtocol`/`MockContext`)

**Stack:**
- SwiftUI + SwiftData
- FoundationModels (Apple Intelligence, on-device)
- RevenueCat (monetización)
- Firebase (Analytics + Crashlytics)
- Swift Charts (estadísticas, nativo)
- WidgetKit + App Groups (`group.zadkiel.musclecheck`)

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
- 1.2.0 — RevenueCat integration
- 1.3.0 — Settings/Profile screen
- 1.4.0 — Daily streak
- 1.5.0 — Statistics (Swift Charts)
- 1.6.0 — Local notifications

---

## Roadmap de Features

### ✅ Feature 1: RevenueCat Integration (branch: `feature/revenuecat-integration`)
**Estado:** Código implementado, pendiente agregar SPM en Xcode

Archivos nuevos:
- `managers/protocols/StoreManagerProtocol.swift`
- `managers/StoreManager.swift` — requiere `YOUR_REVENUECAT_API_KEY`
- `viewModels/PaywallViewModel.swift`
- `Views/PaywallView.swift`
- `Views/ProFeatureGate.swift`
- `MuscleCheckTests/shared/MockStoreManager.swift`
- `MuscleCheckTests/StoreManagerTests.swift`

Modificados:
- `MuscleCheckApp.swift` — `StoreManager.configure()` + `.environmentObject(storeManager)`
- `ContentView.swift` — AI button gated behind `storeManager.isPro`

**Pendiente del developer:**
1. Agregar SPM: `https://github.com/RevenueCat/purchases-ios-spm` (producto: RevenueCat)
2. Reemplazar `YOUR_REVENUECAT_API_KEY` en `StoreManager.swift`
3. Aceptar Program License Agreement en developer.apple.com
4. Configurar productos en App Store Connect + RevenueCat dashboard
5. Crear entitlement `pro` en RevenueCat

### ⏳ Feature 2: Settings/Profile Screen (branch: `feature/settings-profile`)
Archivos a crear:
- `Views/SettingsView.swift` — Subscription, Appearance, About
- `viewModels/SettingsViewModel.swift`

Modificaciones:
- `UserDefaultsManager.swift` — agregar `appTheme`
- `ContentView.swift` — toolbar gear icon → SettingsView
- `MuscleCheckApp.swift` — `.preferredColorScheme()`

### ⏳ Feature 3: Daily Streak (branch: `feature/daily-streak`)
Motivar al usuario mostrando cuántos días consecutivos entrenó.

**Lógica:** Tomar todos los `activityDates` de todas las `MuscleEntry`, extraer días únicos, ordenar descendente y contar días consecutivos desde hoy hacia atrás.

**Datos:**
- `currentStreak` — días consecutivos activos hasta hoy
- `maxStreak` — racha máxima histórica
- `lastTrainedDate` — último día que entrenó (para saber si la racha sigue viva)

**UI:**
- Widget actualizado mostrando la racha actual con fuego 🔥
- Banner/card en `ContentView` con racha actual
- Animación cuando se extiende la racha

**Archivos a crear:**
- `managers/StreakCalculator.swift` — struct estático con funciones puras (igual que `StatsCalculator`)
- `viewModels/StreakViewModel.swift`
- `Views/StreakCardView.swift` — card reutilizable para ContentView
- `MuscleCheckTests/StreakCalculatorTests.swift`

**Modificaciones:**
- `ContentView.swift` — mostrar `StreakCardView` arriba de la lista
- `MuscleCheckWidget/MuscleCheckWidget.swift` — agregar racha al widget

**Versión:** 1.4.0

---

### ⏳ Feature 4: Statistics — Swift Charts (branch: `feature/statistics-charts`)
Sin SDK externo, todo nativo con `import Charts`.

Archivos a crear:
- `managers/StatsCalculator.swift` — struct estático, funciones puras
- `viewModels/StatsViewModel.swift`
- `Views/StatsView.swift`
- `Views/charts/WeeklyTrainingChart.swift`
- `Views/charts/MuscleFrequencyChart.swift`
- `Views/charts/StreakView.swift`
- `MuscleCheckTests/StatsCalculatorTests.swift`

### ⏳ Feature 5: Local Notifications (branch: `feature/local-notifications`)
Sin servidor. `UNUserNotificationCenter` con lógica de inactividad basada en `activityDates`.

Archivos a crear:
- `managers/protocols/NotificationManagerProtocol.swift`
- `managers/NotificationManager.swift`
- `MuscleCheckTests/shared/MockNotificationManager.swift`
- `MuscleCheckTests/NotificationManagerTests.swift`

Modificaciones:
- `UserDefaultsManager.swift` — `notificationsEnabled`, `reminderHour`, `reminderMinute`
- `Views/SettingsView.swift` — sección Notifications
- `MuscleCheckApp.swift` — schedule on `.background` scenePhase

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
