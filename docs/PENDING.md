# ⚠️ Pendientes — por dónde arrancar

> Snapshot al 2026-09-12. 2.2.1 aprobada; en `main` se prepara 2.2.2 (pedido de reseña +
> analítica de activación).

## 🔜 Próximo build: 2.2.2 (1)

El código está en `main`. Antes de subir:

- [ ] **Liberar 2.2.1** si quedó en *Pending Developer Release*: mientras no esté a la venta,
      App Store Connect no deja crear la versión 2.2.2.
- [ ] **Registrar las custom dimensions** en Firebase **antes de TestFlight** (si no, los
      params no aparecen en los reportes): `category`, `metric`, `source`,
      `seconds_since_open`, `seed_count`, `skipped`, `from_preset`, `count`.
- [ ] **DebugView:** correr Debug con `-analyticsDebug YES -FIRDebugEnabled` y ver llegar
      los eventos.
- [ ] **Pedido de reseña a mano:** hace falta data con racha de 2 semanas (en Debug iOS lo
      muestra siempre).
- [ ] **App Privacy** en App Store Connect: Usage Data → Product Interaction, no vinculado a
      identidad, sin tracking.
- [ ] **What's New** de 2.2.2 en ES/EN/FR/IT.

## 👀 Cuando 2.2.1 llegue a usuarios

- Crashlytics: confirmar que no vuelve `MuscleEntry.exercisesSummary.getter`
  (EXC_BREAKPOINT). Es la validación real del fix.

## 🤖 Android

- **Revisar ya:** Pro sigue siendo el stub `LocalProAccessManager`, que activa Pro localmente
  sin cobrar. Si la versión publicada en Play muestra el paywall, alguien puede
  "suscribirse" gratis con precios que no se cobran.
- Swap del stub por RevenueCat real (una sola clase): bloqueado por setup externo —
  productos en Play Billing, API key pública Android, app Android en el proyecto RevenueCat.
- Analítica Fase 2: Firebase + los mismos eventos, verificados contra
  `docs/analytics-plan.md`.

## 📣 Marketing

- Prerrequisitos del plan: pedido de reseña y analítica → salen en 2.2.2.
- Falta en la ficha: subtítulo, keywords y screenshots en ES y EN (iPhone 6.9" + iPad 13"),
  y links de campaña (`ct=`) por canal.

## 🔐 Operacional

- El keystore de Android (`.jks`) vive solo en iCloud Drive: tener una copia fuera de iCloud
  (ver `docs/tech-debt.md` §0).
- Archivar/borrar el repo viejo `~/Desktop/sideProjects/musclecheck-android` si todavía
  existe (su código vive en `android/`).

## 🧹 Modo calidad de código (iOS)

- Bug de test: `OnboardingUITests` falla por orden intra-suite (el hook `-resetOnboarding`
  no restaura el first-run tras un onboarding ya completado en el mismo clone).
- Dead code: `ContentViewModel.saveSession(_:for:)` quedó sin llamadores tras Fase 2
  (está testeado — decidir si se saca).
- Cleanup menor: el caso `.none` plegado en `.strength` dentro de `SessionLogView`.
- Copy en español mezcla tú y vos ("Elegí otra semana", "Todavía no agregaste
  ejercicios"): unificar en tú, que es lo que usa el resto de la app.
- CI: sumar lint y, a futuro, distribución a TestFlight.

## ⏸️ Diferido (features — NO construir en modo código)

- **iOS:** stats de peso por ejercicio (Swift Charts), catálogo ExerciseDB, AI Coach
  sobre ejercicios reales, Apple Watch (Feature 10). Backlog en evaluación: Features 13
  (resto planilla) / 14 / 15 / 16.

## ✅ Cerrado

- CI: build + unit tests por plataforma en cada PR, con path-filters.
- 2.2.1: fix del crash de la home + diagnóstico en Crashlytics + App Intents sin
  `fatalError` (#37, aprobada).
- Pedido de reseña + analítica de activación, Fase 1 — código (#39).
- Landing con Google Play y tabla de Pro alineada con el gateo real (#38).
- Subtítulo del paywall alineado con su tabla (2.2.2).
- Compras iOS (contrato Paid Apps activo).
- Fase 2 iOS: ejercicios dentro del grupo + métricas por ejercicio + alta unificada + FAB.
- Localización ES/EN/FR/IT en ambas plataformas.
- Monorepo armado y pusheado (iOS `ios/` + Android `android/` con historia atómica).
