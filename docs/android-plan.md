# MuscleCheck Android — Plan de migración

**Decisión:** rewrite nativo en Kotlin + Jetpack Compose (opción elegida sobre KMP y Skip).
Repo separado: `~/Desktop/sideProjects/musclecheck-android`. Package `com.zadkiel.musclecheck`
(mismo que el bundle ID iOS → mismo proyecto RevenueCat y Firebase).

## Mapeo de stack

| iOS | Android |
|---|---|
| SwiftUI | Jetpack Compose (Material 3) |
| SwiftData | Room (entities + DAOs con Flow) |
| UserDefaults / App Group | DataStore Preferences |
| WidgetKit | Glance |
| ObservableObject + @Published | ViewModel + StateFlow |
| Manager + protocolo + .shared | Repository + interface + Hilt |
| Swift Charts | Charts hand-rolled en Compose (2 charts simples, sin dependencia) |
| UNUserNotificationCenter | WorkManager + POST_NOTIFICATIONS |
| RevenueCat iOS | RevenueCat Android (purchases-android) |
| HealthKit | Health Connect (**diferido a v2**) |
| FoundationModels (AI Coach) | **Sin equivalente — diferido** (Gemini Nano no cubre toda la base) |
| AppIntents / Siri | Diferido |
| Localizable.xcstrings | strings.xml ES/EN/FR/IT |

## Decisiones técnicas

- **minSdk 26, target/compile 35.** Single module.
- **Semántica de semana:** `WeekFields(MONDAY, minimalDays=1)` — NO `WeekFields.ISO`
  (Apple usa `minimumDaysInFirstWeek = 1`; ISO usa 4 y numeraría distinto algunas semanas de borde de año).
- **Íconos:** la DB guarda los mismos IDs de SF Symbols que iOS (`figure.yoga`, …) para
  portabilidad de datos; la UI los mapea a Material Symbols. Ícono desconocido → fallback estrella.
- **Pesos siempre en kg** en storage; conversión kg/lbs en el borde de display (igual que iOS).
- **Sessions:** tabla propia con FK a entry (relacional idiomático), no JSON embebido como SwiftData.
- **Tests del dominio portados de las suites Swift** — son la spec de las semánticas finas
  (racha semanal con gracia, degradación de categoría huérfana, grid 6×7 lunes-first).

## Fases

1. ✅ Toolchain (JDK 21 brew, Android cmdline-tools, platform 35)
2. ✅ Scaffold Gradle + dominio puro con tests (JVM)
3. ✅ Data layer: Room + DataStore + repositories
4. ✅ UI core loop: checklist semanal + add group + modal de peso
5. ✅ Historial + stats + streak card
6. ✅ Settings (units, theme, custom categories, presets) + onboarding
7. Notificaciones (WorkManager) ✅ · widget Glance ✅ · progress photos (pendiente)
   - Notificaciones: `InactivityCalculator` (dominio puro, 11 tests portados de la suite iOS),
     `ReminderScheduler` (periodic daily + one-shot inactividad mañana 10:00, re-encolado
     al ir a background vía ProcessLifecycleOwner), workers con @HiltWorker, toggle + time
     picker en Settings con permiso POST_NOTIFICATIONS (API 33+). El resumen de inactividad
     se computa al momento de disparar (no al agendar, como iOS) → nunca queda stale.
   - Widget: Glance 2×2 con racha (🔥 actual / 🏆 máx) + checklist de la semana (hasta 5).
     Lee Room directo vía Hilt EntryPoint (sin App Group). `MuscleRepository` refresca el
     widget tras cada mutación (espejo del reloadTimelines de iOS). Sin íconos por actividad
     en v1 (Glance no renderiza ImageVectors; evaluar drawables por categoría).
8. RevenueCat + paywall, localización FR/IT, build final

## Blockers externos (requieren acción del developer)

- **Play Console:** cuenta (USD 25) + closed test de 14 días con ~12 testers antes de producción.
- **Firebase:** agregar app Android al proyecto existente → `google-services.json` (el código queda listo con Analytics/Crashlytics opcionales hasta tenerlo).
- **RevenueCat:** agregar app Android al proyecto + API key pública Android + productos en Play Billing.
