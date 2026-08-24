# ⚠️ Pendientes — por dónde arrancar

> Snapshot al 2026-07-22. Empezar por CI, que es lo que quedó a mitad de camino.

## 🔜 Arrancar acá: CI (paso a paso)

- Se **removieron** los workflows de GitHub Actions a propósito — se van a armar paso a paso.
- Objetivo: build + unit tests por plataforma en cada PR, con **path-filters**
  (cambios en `ios/**` disparan solo iOS; `android/**` solo Android).
- Notas para cuando se retome:
  - **iOS** → runner `macos`, `xcodebuild test -project ios/MuscleCheck.xcodeproj -scheme MuscleCheck -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MuscleCheckTests` (solo unit — las UI tests tienen un flaky de orden en `OnboardingUITests`).
  - **Android** → runner `ubuntu`, JDK 21, `cd android && ./gradlew testDebugUnitTest assembleDebug`.
  - Dos archivos separados (`ios.yml`, `android.yml`) con `paths:` filtrando por carpeta.

## 📊 Analítica (pedido explícito — excepción al "cero features")

- Plan completo en **`docs/analytics-plan.md`**: qué medir para saber dónde se pierden
  los usuarios, taxonomía de 14 eventos, arquitectura del seam y compliance.
- Estado: iOS tiene Firebase configurado **sin un solo evento propio**; Android no tiene
  Firebase en absoluto. RevenueCat ya cubre el funnel de monetización.
- Arrancar por la Fase 1 (activación, solo iOS). Registrar las custom dimensions en la
  consola **antes** de shipear, si no los params no aparecen en los reportes.

## 📤 Operacional (cuando el dev quiera)

- **Pushear el monorepo** — hay commits en `main` local sin subir (incluye el reorg
  a `ios/` + la historia atómica de Android). `git push origin main`.
- **Archivar/borrar** el repo viejo `~/Desktop/sideProjects/musclecheck-android` —
  quedó redundante (su código ya vive acá en `android/`).
- **Subir 2.2.0 (build 1)** a TestFlight.
- **Screenshots** App Store: iPhone 6.9" (16 Pro Max) + iPad 13" (Pro), en ES y EN.

## 🧹 Modo calidad de código (iOS)

- **CI/CD** (lo de arriba).
- Bug de test: `OnboardingUITests` falla por orden intra-suite (el hook `-resetOnboarding`
  no restaura el first-run tras un onboarding ya completado en el mismo clone).
- Dead code: `ContentViewModel.saveSession(_:for:)` quedó sin llamadores tras Fase 2
  (está testeado — decidir si se saca).
- Cleanup menor: el caso `.none` plegado en `.strength` dentro de `SessionLogView`.
- Deuda vieja del foco: god objects, two-phase init, denormalización.

## ⏸️ Diferido (features — NO construir en modo código)

- **iOS:** stats de peso por ejercicio (Swift Charts), catálogo ExerciseDB, AI Coach
  sobre ejercicios reales, Apple Watch (Feature 10). Backlog en evaluación: Features 13
  (resto planilla) / 14 / 15 / 16.
- **Android:** la **arquitectura Pro ya está construida** — seam `ProAccessManager`
  (interface) + `LocalProAccessManager` (stub DataStore con el punto de swap documentado),
  paywall, gate en progress photos, sección en Settings, strings ES/EN/FR/IT y tests.
  Lo único que queda es **swappear el stub por el SDK real de RevenueCat** (una sola clase),
  **bloqueado por setup externo:** cuenta Play Console (USD 25 + closed test 14 días),
  productos en Play Billing, API key pública Android, app Android en el proyecto RevenueCat.

## ✅ Cerrado

- Compras iOS (contrato Paid Apps activo).
- Fase 2 iOS: ejercicios dentro del grupo + métricas por ejercicio + alta unificada + FAB.
- Localización ES/EN/FR/IT en ambas plataformas.
- Monorepo armado (iOS `ios/` + Android `android/` con historia atómica).
