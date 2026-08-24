# 🧱 Deuda técnica — checklist de refactor

> Branch: `refactor/tech-debt` (desde `main`). Snapshot del review al 2026-08-18, sobre
> `ios/` (~8.000 LOC) + setup de `android/`.
> Modo calidad de código: **cero features**. Ver foco actual en `CLAUDE.md`.
>
> Orden pensado para que cada paso deje el terreno más limpio para el siguiente.
> Los ítems 1–6 son mecánicos y **no tocan datos persistidos**. El 7 es el único con
> migración real, y conviene hacerlo **antes** del release, mientras borrar el store
> sigue siendo una salida legítima (cero usuarios).
>
> Los números de línea son del snapshot original: el ítem 5 ya se hizo y corrió todo
> lo que está debajo de `ContentViewModel:100`.

---

## 0. ✅ Keystore de Android — cerrado

- [x] Reglas en el `.gitignore` **raíz** (`:70-72`): `android/keystore.properties`, `*.jks`,
      `*.keystore`. Llegaron a `main` con el commit de firma (`db471bc`, PR #33).
- [x] `.jks` **fuera del árbol del repo** → `~/Library/Mobile Documents/…/Documents/apps/`
      (iCloud Drive), con `storeFile` apuntando a la ruta absoluta.
- [x] Backup del `.jks` + las 3 contraseñas fuera de la laptop.

**Estado real:** la protección estaba bien implementada desde el principio, en el `.gitignore`
raíz. El comentario de `android/app/build.gradle.kts:11` que dice *"is gitignored"* **es
correcto** — no hay nada que corregir ahí.

**La ventana de riesgo ya está cerrada (2026-08-18).** Era angosta: las reglas vivían solo en
el commit de la PR #33, así que `main` —y cualquier branch salida de main, como
`refactor/tech-debt`— no las tenía, y trabajando parado ahí un `git add -A` habría staged las
credenciales. Se cerró mergeando #33 (`db471bc`, squash) y trayendo `main` al branch;
`git check-ignore -v android/keystore.properties` ahora responde `.gitignore:71` y el archivo
desapareció de `git status`. `git log --all --full-history` confirma que las credenciales nunca
entraron a la historia — el único match de `*keystore*` es `keystore.properties.example`, que es
el template. No hay nada que purgar.

> Nota de proceso: GitHub trató a #33 como *stacked PR* y rechazó tanto `gh pr merge` como el
> `PUT /pulls/33/merge` clásico. Hubo que usar el endpoint asíncrono
> (`PUT /repos/{owner}/{repo}/pulls/33/merge-async` + polling del UUID que devuelve).

⚠️ **Pendiente operacional:** el `.jks` vive en iCloud Drive. Con "Optimizar almacenamiento del
Mac" activado, macOS puede desalojarlo y dejar un placeholder → `bundleRelease` falla con un
keystore "presente" pero vacío. Si pasa, abrir la carpeta en Finder para forzar la descarga, o
tener una copia local además de la de iCloud. Al 2026-08-18 el archivo está materializado en
disco (2786 bytes, no placeholder).

Detalle del keystore (verificado): válido hasta **2053**, RSA 2048, SHA384withRSA. Cumple los
requisitos de Play (expiración ≥ 2033). **No hay que regenerarlo.** Ver apéndice al final.

---

## 1. Borrar código muerto y reglas contradictorias

Primero, para reducir superficie antes de refactorizar.

- [ ] `MuscleEntryManager.addDefaultEntries(names:)` (`:179`) — sin llamadores, y usa
      predicado de nombre **exacto** mientras `addEntry` usa `normalizedName` case-insensitive
      (`:63-67`). Dos definiciones de "ya existe" en la misma clase.
- [x] `MuscleEntryManager.toggleActivity(for:on:)` (`:162`) — duplica
      `ContentViewModel.toggleActivity` con semántica distinta (sin tips, sin refresh).
      Borrado con el ítem 4 (escribía el flag). Ídem `fetchEntries(forWeek:year:)` y el
      caso `MuscleEntryError.invalidWeekOrYear` que solo él tiraba.
- [ ] `MuscleEntryManager.update(_:)` (`:143`) — ignora el parámetro, solo llama `save()`.
- [ ] `ContentViewModel.saveSession(_:for:)` (`:252`) — sin llamadores desde Fase 2; solo lo
      sostienen dos tests (`ContentViewModelTests:100`, `:115`). Borrar método + tests.
- [ ] `SessionLogView`: el caso `.none` plegado en `.strength`.
- [ ] Mover `extension ModelContext: ModelContextProtocol {}` fuera de `ContentView.swift:311`
      (conformance de infraestructura escondida en una vista) a `ModelContextProtocol.swift`.

## 2. `context` no-opcional por init (two-phase init)

- [ ] Inyectar `ModelContextProtocol` por `init` en `ContentViewModel`; borrar los opcionales
      `context` y `muscleEntryManager` (`:16-18`) y `setup(context:entries:)`.
- [ ] Eliminar los ~15 `context?.save()`.
- [ ] Revisar los errores que hoy se tragan: `logHealthKitWorkout` hace
      `guard let manager else { return }` (`:345`) y `catch { return }` (`:368-370`).

**Por qué:** con el campo opcional, cualquier guardado antes de `setup()` es un no-op
**silencioso**. `ContentView` ya tiene el `context` por `@Environment` antes del primer body,
así que la opcionalidad no compra nada.

## 3. Unificar `@Query` vs ViewModel (doble fuente de verdad)

- [ ] Elegir dueño único: `@Query` como fuente + VM derivando (menos código con SwiftData),
      o VM dueño y se va el `@Query` de `ContentView.swift:32`.
- [ ] Eliminar el refetch de `updateCurrentEntries()` (`fetchAllEntries()` completo).
      (El filtro semanal ya se fue con el ítem 4; queda el refetch y el `@Query`.)

**Por qué:** hoy cada tap en un check dispara **dos** pipelines sobre los mismos datos:
mutar → `updateCurrentEntries()` (refetch + refiltrado + reagrupado + streak O(n²) + JSON del
widget), y en paralelo `@Query` se invalida sola → `onChange(of: entries)` (`:183`) →
`updateCurrentEntries()` **otra vez**.

## 4. ✅ `isChecked` como computed (denormalización) — hecho

- [x] `isChecked` → `isTrained(inWeekOf: Date())`, sobre `sessions`. La comparación se le
      pide al calendario (`isDate(_:equalTo:toGranularity:.weekOfYear)`), no a los
      componentes: una semana a caballo del año nuevo tiene un número de semana y **dos**
      años calendario, así que comparar ints da falso negativo ~7 días al año.
- [x] Borrado `resetCheckedEntriesIfnewWeek()` y los flags `lastResetWeek`/`lastResetYear`.
- [x] `weekOfYear`/`year` fuera del modelo. Se fueron con ellos el filtro semanal de
      `updateCurrentEntries` (que solo pasaba porque el reset re-estampaba todas las
      entries) y `MuscleEntryManager.fetchEntries(forWeek:year:)`, sin llamadores.
- [x] **Decisión de producto:** destildar = "no entrené esto esta semana" → borra todas las
      sesiones de la semana en curso (`removeSessions(inWeekOf:)`). Borrar solo la del día
      dejaba el check prendido si sobrevivía otra sesión de la misma semana.
- [x] `WeeklyResetTip` conservado con donante nuevo: la home compara el lunes de esta semana
      contra `UserDefaultsManager.lastSeenWeekStart` (**un `Date`**, no el par de ints).
- [x] 18 tests nuevos en `MuscleEntryWeekCheckTests` + regresión del bug lunes/miércoles en
      `ContentViewModelTests`. Suite completa: 229 tests en verde.

**Pendiente antes de mergear:** sacar 3 atributos de un `@Model` es cambio de schema — falta
el ensayo store viejo → build nuevo para saber si SwiftData migra solo o si cae en el borrado
de `MuscleCheckApp.swift:75-88`.

**Decisión abierta:** al destildar la semana del grupo, las sesiones de esa semana **dentro de
`Exercise.sessions`** siguen ahí. Hoy es comportamiento accidental, no decidido.

**Por qué:** hoy hay 4 caminos que mantienen las dos representaciones a mano y pueden
desincronizarse: `toggleActivity` (`:296-316`), `setTodaySession`, `logExercise`,
`MuscleEntryManager.toggleActivity`. Como computed, la clase de bug desaparece y el
reset semanal deja de existir como concepto.

## 5. ✅ Romper el god object `ContentViewModel` (374 líneas, 7 responsabilidades) — hecho

- [x] Extraer el coach de IA (`:22-102`, ~80 líneas) a `RoutineCoachViewModel`. No comparte
      nada con el resto salvo `entries` — que ahora se pasa por parámetro en vez de guardarse,
      así no hay una segunda copia de la lista que mantener sincronizada.
- [x] Extraer el sync del widget (`:193-206`) a un `WidgetBridge` **compartido por ambos targets**:
      hoy el App Group `"group.zadkiel.musclecheck"` y las 3 claves `widget*` están hardcodeadas
      duplicadas en `ContentViewModel.swift:199-202` y `MuscleCheckWidget.swift:5-8`. Un typo
      ahí rompe el widget en silencio.
- [x] De yapa: `SharedMuscleEntry` estaba duplicado en los dos targets. Quedó una sola copia
      (`MuscleCheck/models/`), compartida por `membershipExceptions` igual que el `.xcstrings`.

`ContentViewModel` pasó de 374 a 273 líneas.

## 6. Perf de las calculadoras puras

- [ ] `StreakCalculator.uniqueTrainingDays` (`:19`) es O(n²) — `contains` lineal dentro del loop.
- [ ] `StatsCalculator` usa `dayStart.description` como clave de `Set<String>` (`:37`, `:58`).
      Formatear fecha a string para deduplicar es caro y frágil por locale → `Set<Date>` de
      `startOfDay`.
- [ ] `MuscleEntry`: `lastWeight`/`lastSets`/`lastReps`/`lastDuration`/`lastDistance` son
      **5 escaneos independientes** del array, por fila, por render. Un solo scan que devuelva
      la última sesión relevante.

## 7. `WorkoutSession` → `@Model` (el techo real de escalabilidad)

- [ ] `WorkoutSession` como `@Model` con relación real a `MuscleEntry`.
- [ ] Ídem las `sessions` anidadas dentro de `Exercise`.
- [ ] Agregar el modelo a `AppSchema.models`.
- [ ] Reescribir stats/streak/historial con `#Predicate` por rango de fechas en vez de full scan.

**Por qué:** hoy `sessions` y `exercises` son blobs Codable dentro de la fila →
**nada es consultable**. Toda lectura histórica es full scan en memoria
(`StatsCalculator.daysTrainedPerWeek:33` itera entries × sesiones × 8 semanas) y crece sin
techo: 2 años × 7 grupos × ~100 sesiones + ejercicios adentro se cargan enteros para pintar
la home.

**Riesgo:** es la única migración de datos real de la lista. La estrategia actual ante schema
mismatch es **borrar el store** (`MuscleCheckApp.swift:75-88`) — aceptable con cero usuarios,
no después del release.

---

## Menores / seguimiento

- [ ] `HistoryView.swift:10` — `StateObject(wrappedValue: HistoryViewModel.create(with: entries))`
      captura `entries` en la primera construcción y nunca se actualiza. Hoy no se nota porque
      la vista se pushea nueva cada vez; es una trampa cargada.
- [ ] `UserDefaultsManager` — singleton concreto, 42 usos, **el único manager sin protocolo**,
      justo el que gobierna onboarding, reset semanal y cache de IA.
- [ ] Bug de `-resetOnboarding` (orden intra-suite de `OnboardingUITests`): `MuscleCheckApp`
      puentea el manager con `UserDefaults.standard` crudo por strings (`:24-26`, `:40`),
      duplicando dos claves que el manager ya define. **El bypass es donde vive el bug.**
      Se arregla solo al darle protocolo al manager (ítem anterior).

## Android

La duplicación del dominio en Kotlin (`MonthCalendarCalculator`, `StreakCalculator`, modelos)
es real pero **no se toca**: KMP para dos apps de un side project es ceremonia que no rinde.
Lo que sí se mantiene barato es la **paridad de test suites** — que los mismos casos borde
existan de los dos lados es lo que hace sostenible la duplicación.

---

## Apéndice — cómo tratar el keystore de Android (para alguien que viene de iOS)

**El modelo mental de iOS no aplica.** En iOS, si perdés el certificado de distribución lo
revocás en el portal y generás otro; Apple es la autoridad y la App Store re-firma tu app.
En Android la clave **es** la identidad: no hay portal donde revocar y reemitir.

Lo que salva el día es **Play App Signing** (obligatorio para apps nuevas desde ago-2021, así
que MuscleCheck lo va a usar sí o sí). Ahí hay **dos** claves:

| Clave | Quién la tiene | Si se pierde |
|---|---|---|
| **App signing key** — firma lo que instalan los usuarios | Google | No la tenés vos: no la podés perder |
| **Upload key** — solo prueba a Play que el upload es tuyo (tu `.jks`) | Vos | Recuperable: se pide reset a soporte de Play (días de demora) |

Es decir: con Play App Signing, perder tu `.jks` es **molesto, no fatal**. Sin Play App Signing
(no es el caso) sería fatal: nunca más podrías actualizar la app, y habría que publicar un
listing nuevo perdiendo instalaciones y reviews.

Reglas prácticas:

1. **Nunca al repo** — ni el `.jks` ni el `keystore.properties`. Ver ítem 0.
2. **Fuera del árbol del repo** — hoy en `~/Library/Mobile Documents/…/Documents/apps/`
   (iCloud Drive), con `storeFile` en ruta absoluta. Ver la advertencia de desalojo en el ítem 0.
3. **Backup en el gestor de contraseñas**, no solo en la laptop: el `.jks` **y** las 3
   contraseñas (store, key, alias). El alias actual es `musclecheck`.
4. **Para CI**: nunca el archivo. Se sube el `.jks` en base64 como secret de GitHub Actions,
   se decodifica en un step, y las contraseñas van como secrets aparte.
5. **El build ya degrada bien**: sin `keystore.properties`, `hasReleaseSigning` es false y el
   release compila sin firmar (`android/app/build.gradle.kts:20`, branch de firma). Eso mantiene
   `bundleRelease` verificable en CI sin exponer nada.
