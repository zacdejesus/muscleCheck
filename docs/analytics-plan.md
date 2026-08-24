# 📊 Plan de analítica — dónde se pierden los usuarios

> Snapshot al 2026-08-24. Pedido explícito del developer, así que **es una excepción
> consciente al "cero features"** del modo calidad de código: esto es instrumentación,
> no producto. No cambia ninguna pantalla.
>
> Este doc es la **fuente única** de nombres de eventos para iOS y Android. Se define
> una vez acá, se implementa dos veces. Mismo criterio que la paridad de test suites.

---

## 0. La pregunta

**¿En qué momento la gente deja de usar MuscleCheck, y por qué?**

Todo lo que sigue existe para responder eso. La regla que gobierna el doc entero:

> **Si un evento no responde una pregunta que ya nos estamos haciendo, no va.**

No se trackean "los clicks". Trackear clicks produce un lago de eventos que nadie
mira y que envejece mal. Se trackea un **funnel**, que es una hipótesis sobre dónde
se rompe la experiencia.

---

## 1. Estado actual (auditoría)

| | Estado |
|---|---|
| **iOS** | `FirebaseApp.configure()` en `MuscleCheckApp.swift:34` y **nada más**. Cero eventos propios. Solo llegan los automáticos: `first_open`, `session_start`, `screen_view`, `user_engagement`, `in_app_purchase` |
| **Android** | **Firebase no existe.** Ni dependencia, ni plugin de Google Services, ni `google-services.json`. La mitad de los usuarios es invisible |
| **Monetización** | RevenueCat ya da el funnel completo (paywall → compra → churn) en su dashboard. **No duplicar** |
| **Config** | `ios/MuscleCheck/GoogleService-Info.plist` está **commiteado** (los patrones del `.gitignore` no matchean después de la mudanza a monorepo). El `google-services.json` de Android debería seguir la misma política: si se ignora, el plugin **rompe el build** y CI se cae |

---

## 2. La trampa de medición específica de esta app

Esto es lo que un plan genérico se pierde, y es lo más importante del doc.

### 2.1 El éxito del producto es que el usuario abra menos la app

El posicionamiento es *"trackeá tu entrenamiento en 2 segundos"*. Hay widget, App
Intents/Siri y detección por HealthKit: **parte del uso ocurre fuera de la app**. Un
usuario que mira el widget, le dicta a Siri "entrené pecho" y nunca abre la app es un
usuario de **éxito máximo** — y en un dashboard de aperturas se lee como abandono.

Consecuencias de diseño, no negociables:

- La métrica de engagement es **"semanas con al menos un check registrado por
  cualquier vía"**, no aperturas ni sesiones.
- Todo evento de registro lleva un parámetro **`source`** (`app` / `siri` / `healthkit`)
  para poder separar "no lo usa" de "lo usa sin abrirlo".
- El widget hoy es read-only: el tap abre la app, así que no emite eventos propios.
  El App Intent sí puede emitirlos, y **tiene que hacerlo** o Siri queda como un
  agujero negro.

### 2.2 La retención diaria es la métrica equivocada

El modelo mental de la app es un **checklist semanal**. Medir D1/D7 la va a hacer ver
muerta, porque nadie *debería* entrar todos los días. La unidad natural es la **semana
ISO** — que además es la que el dominio ya usa (`MuscleEntry.isTrained(inWeekOf:)`).

Los benchmarks públicos de la industria son diarios (§5). No se comparan de forma
naive contra una app semanal.

### 2.3 Sin cuentas, el identificador es por instalación

No hay login. El id es el app-instance de Firebase: **reinstalar = usuario nuevo**.
Eso infla "nuevos usuarios" y rompe las curvas de retención larga. Se acepta como
límite conocido; **no se construye auth para arreglar la analítica**.

### 2.4 Los denominadores están sesgados

El coach de IA está gateado por iOS 26 + Apple Intelligence: para una porción de los
usuarios **el botón ni existe**. Medir `coach_opened / usuarios` y concluir "nadie usa
la IA" sería un error de lectura, no un hallazgo. Por eso la elegibilidad va como
**user property** (§9) y todos los ratios se calculan sobre la población elegible.

---

## 3. Marco: Goals → Signals → Metrics (HEART)

Se usa HEART (Google) porque separa lo que se puede inferir de los logs de lo que hay
que preguntar. Aplicado a MuscleCheck:

| | Goal | Signal | Métrica | ¿De logs? |
|---|---|---|---|---|
| **H**appiness | Que sienta que registrar no cuesta | Reviews, respuestas de testers | Rating, feedback cualitativo | ❌ Hay que preguntar |
| **E**ngagement | Que registre lo que entrena | Checks por semana activa | Mediana de checks/semana | ✅ |
| **A**doption | Que llegue al primer check | Install → primer tilde | % que tilda dentro de 24h | ✅ |
| **R**etention | Que vuelva la semana siguiente | Semanas consecutivas | % con ≥1 check en la semana 2 | ✅ |
| **T**ask success | Que encuentre cómo agregar | Alta abierta → alta guardada | % de altas completadas, tiempo hasta el check | ✅ |

**Happiness es la única que no se puede inferir de los logs.** Si el plan no incluye
hablar con usuarios (§13), esa fila queda vacía para siempre.

---

## 4. North Star y la unidad de tiempo correcta

> **North Star: semanas activas por usuario.**
> Una semana es activa si el usuario registró ≥1 entrenamiento en ella, por cualquier vía.

Lo lindo: **el producto ya calcula su propia North Star**. La racha semanal de
`StreakCalculator` es exactamente esta métrica vista desde adentro. La analítica solo
la mira desde afuera y agregada.

Métrica de calidad del hábito: **distribución de rachas** (cuánta gente llega a 2, 4,
8, 12 semanas). Es más honesta que un promedio, que va a estar dominado por la cola de
gente que probó una vez.

---

## 5. Benchmarks (y por qué casi no aplican todavía)

Rangos publicados para health & fitness, útiles como orden de magnitud:

- Retención **D1** entre ~20% y ~30-35%; los mejores llegan a ~45%.
- Retención **D7** entre ~7-8% y ~15-20%; top-tier ~30%.
- Retención **D30** entre ~3% y ~8-12%; los mejores ~25%.
- La activación en fitness cae de ~26% el día 1 a ~10% al día 28.

Tres advertencias, en orden de importancia:

1. **Son diarios.** Nuestro modelo es semanal (§2.2). Comparar directo lleva a
   conclusiones falsas.
2. **La dispersión entre fuentes es enorme** (D1 de 20% a 35% según quién mida). Sirven
   para saber si estamos en otro orden de magnitud, no para fijar un objetivo.
3. **Con la base de usuarios actual no aplican en absoluto.** Cinco usuarios no hacen
   un porcentaje.

---

## 6. El funnel de activación

El camino crítico, con **ventana temporal explícita** — un funnel sin ventana se
completa "eventualmente" y no mide nada:

```
install
  └→ onboarding_started
       └→ onboarding_completed            (o abandonado, con el paso)
            └→ activity_checked  #1        ← ACTIVACIÓN (ventana: 24 h)
                 └→ ≥1 check en la semana 2 ← HÁBITO (ventana: 14 días)
```

Además, **el tiempo hasta el valor es parte del producto**: la promesa es "2 segundos".
Por eso `activity_checked` lleva `seconds_since_open`. Si la mediana está en 8
segundos, el tagline es mentira y eso es un bug de producto, no un número feo.

---

## 7. Los cinco momentos de pérdida

Cada uno con su hipótesis, el par de eventos que la mide, y **qué se haría con la
respuesta**. Si la última columna está vacía, el evento no se instrumenta.

### 7.1 Onboarding → primer check
- **Hipótesis:** el usuario elige sus grupos en el onboarding y sale a una lista que no
  entiende que hay que tildar.
- **Mide:** `onboarding_completed` → `activity_checked` (primero).
- **Decisión:** si la caída es alta, el onboarding necesita terminar *dentro* del primer
  check (que el último paso sea tildar algo), no antes.

### 7.2 El alta de ejercicios
- **Hipótesis:** ya fue un problema real ("no encuentro cómo agregar") y se arregló con
  el FAB en la Feature 18. **No hay ninguna medición de si funcionó.**
- **Mide:** `exercise_add_started` (con `source`: fab / empty_state) → `exercise_add_completed`.
- **Decisión:** si el abandono sigue alto, el problema no era el descubrimiento sino el
  formulario. Si `source=empty_state` domina, el FAB sigue sin verse.

### 7.3 La profundidad (Feature 19)
- **Hipótesis:** los ejercicios dentro del grupo fueron caros de construir; puede que
  casi nadie descubra que tocando el nombre se entra.
- **Mide:** `group_detail_opened` sobre usuarios con ≥1 grupo de métrica ≠ `none`.
- **Decisión:** si es marginal, la pregunta no es "cómo lo promocionamos" sino si la
  feature merece seguir existiendo. Un dato así **justifica borrar código**.

### 7.4 La segunda semana
- **Hipótesis:** es la caída grande y estructural de toda app de hábitos.
- **Mide:** cohorte de instalación → ≥1 check en la semana 2.
- **Decisión:** es lo que le da sentido (o se lo quita) a la notificación de
  recordatorio y a la racha como mecánica de retención.

### 7.5 El coach de IA
- **Hipótesis:** se abre una vez por curiosidad y no vuelve.
- **Mide:** `coach_opened` / `coach_regenerated`, **sobre la población elegible** (§2.4).
- **Decisión:** si se usa una vez y nunca más, el problema es que sugiere sin poder
  actuar. Si se regenera mucho, la primera sugerencia es mala.

### 7.6 El paywall — **no se instrumenta**
RevenueCat ya tiene todo el funnel de monetización. Duplicarlo es trabajo con riesgo de
dos números que no coinciden y nadie sabe cuál creer.

---

## 8. Taxonomía de eventos

**Convención:** `objeto_acción`, en **pasado**, `snake_case`. Los **eventos** dicen
*qué pasó*; las **propiedades** dicen *quién / dónde / cómo*. Esa separación es lo que
evita la explosión de nombres (`add_from_fab`, `add_from_empty`… son un solo evento con
un parámetro).

| Evento | Cuándo | Parámetros |
|---|---|---|
| `onboarding_started` | Primera pantalla del first-run | — |
| `onboarding_completed` | Termina el flujo | `seed_count` |
| `onboarding_abandoned` | Sale antes de terminar | `step` |
| `activity_checked` | Se marca un grupo como entrenado | `category`, `metric`, `source`, `seconds_since_open` |
| `activity_unchecked` | Se destilda | `category` |
| `exercise_add_started` | Se abre el alta | `source` (`fab`/`empty_state`/`category`) |
| `exercise_add_completed` | Se guarda | `category`, `metric`, `from_preset`, `count` |
| `category_created` | Se crea una categoría custom | `metric` |
| `group_detail_opened` | Se abre el detalle de un grupo | `exercise_count_bucket` |
| `session_logged` | Se guardan valores | `metric`, `target` (`group`/`exercise`), `source` |
| `coach_opened` | Se abre el modal del coach | `cached` |
| `coach_regenerated` | "Dame otra" | — |
| `permission_result` | Respuesta a un permiso | `type` (`notifications`/`healthkit`/`photos`), `granted` |
| `history_opened` | Se abre el historial | — |

**Catorce.** Si esta lista llega a treinta antes de tener usuarios, algo salió mal.

Regla de vida: **el evento se borra junto con la feature que lo emite.** Los eventos
huérfanos son la forma en que una taxonomía se pudre.

---

## 9. User properties (los denominadores)

No son eventos: son los ejes con los que se segmenta cualquier funnel.

| Property | Valores | Para qué |
|---|---|---|
| `ai_available` | bool | El denominador honesto del coach (§2.4) |
| `is_pro` | bool | Separar comportamiento free/pago |
| `entries_bucket` | `0` / `1-5` / `6-10` / `11+` | Un usuario con 3 grupos no se compara con uno de 15 |
| `has_custom_categories` | bool | ¿La Feature 17 llegó a alguien? |
| `notifications_enabled` | bool | Denominador del efecto de los recordatorios |
| `healthkit_enabled` | bool | Ídem, y explica registros sin apertura |
| `weeks_since_install` | int | Cohortes |
| `app_language` | `es`/`en`/`fr`/`it` | Si una localización rinde distinto, suele ser un bug de copy |

---

## 10. Qué NO se instrumenta

- **Texto libre del usuario.** Nombres de ejercicios y de categorías custom pueden
  contener datos personales y además hacen explotar la cardinalidad. Va la **categoría**
  y el **`MetricType`**, que son enums cerrados.
- **Cualquier contenido de HealthKit.** Ver §12: no es una preferencia, es una regla de
  Apple.
- **`screen_view` de todas las pantallas.** Ruido con forma de dato.
- **Taps genéricos.** No responden ninguna pregunta de §7.
- **El funnel de compra.** Ya está en RevenueCat.

---

## 11. Arquitectura

- **Un seam propio**: `AnalyticsTracking` (protocolo), con la misma forma que
  `NotificationManagerProtocol` / `HealthKitManagerProtocol`. Firebase es *una*
  implementación. Hay además una NoOp (tests y UI tests — los UI tests **no deben
  ensuciar los datos**, y ya pasan `-uiTesting` para desactivar TipKit: mismo hook) y
  una que loguea a consola en debug.
- **Eventos tipados, nunca strings sueltos en las vistas.** Es la lección del
  `WidgetBridge`: un literal duplicado en dos lados es un typo esperando ocurrir, y en
  analítica el typo **no rompe nada** — el dato simplemente no existe, y te enterás tres
  semanas después mirando un dashboard vacío. El enum es además el único lugar donde se
  mapea evento → nombre + params, que es donde se aplican los límites de la plataforma.
- **Se dispara desde los ViewModels**, no desde las vistas. Los VMs ya tienen los verbos
  del dominio (`toggleActivity`, `addExercise`, `logExercise`, `generateRoutine`), así
  que el evento sobrevive a rediseños de UI y es testeable con un spy del protocolo.
  Excepciones legítimas: "abrí esta pantalla" y "abandoné este sheet", que son hechos de
  la vista.

**Límites de Firebase/GA4 que hay que conocer antes de diseñar params:**

- 25 parámetros por evento **incluyendo los automáticos** (quedan ~20 útiles).
- Nombre de evento ≤ 40 caracteres; nombres de parámetro de 1 a 40, empezando con letra.
- Los parámetros custom **no aparecen en los reportes hasta registrarlos como custom
  dimensions** (50 disponibles), y hay que registrarlos **antes** de que el evento se
  dispare. Trampa clásica: mandás el param, no lo ves, asumís que no llega.
- Los reportes tardan ~24 h. Para desarrollo se usa **DebugView**, que es tiempo real.
  No confundir "no llegó" con "todavía no se procesó".

**Android** necesita: dependencia `firebase-analytics`, plugin de Google Services y
`google-services.json` (ver la nota de política en §1).

---

## 12. Privacidad y compliance

- **HealthKit es innegociable.** Apple prohíbe expresamente enviar datos de HealthKit a
  terceros, y usarlos para publicidad o data mining. Mandar contenido de workouts a
  Firebase sería una violación de las guidelines y un rechazo en review. Se registra el
  **hecho** (`source=healthkit`), nunca el **payload**.
- **ATT/IDFA**: Firebase Analytics sin IDFA no requiere el prompt de ATT. Conviene
  desactivar explícitamente la recolección de ad_id y evitarse el prompt entero.
- **App Store privacy labels**: hay que declarar Usage Data → Product Interaction, no
  vinculado a identidad.
- **Play Data safety**: ídem del lado de Android. Recordatorio fresco: la app acaba de
  salir de una violación de política; declarar mal la recolección de datos es la forma
  más barata de conseguir otra.

---

## 13. El complemento cualitativo (no es opcional)

Con la base de usuarios actual, **ningún dashboard va a decir nada estadísticamente**.
Lo que se puede hacer con n chico:

- **Buscar acantilados, no diferencias.** Una caída de 100% a 20% se ve con 5 usuarios.
  Una mejora del 5% no se ve ni con 500. **Nada de A/B tests.**
- **Cinco usuarios en una sesión moderada descubren la gran mayoría de los problemas de
  usabilidad** (Nielsen). Veinte minutos con una tester dan más señal que el dashboard
  entero durante un mes.
- El funnel sirve como **disparador de la conversación**: "vi que abriste el alta tres
  veces y no guardaste ninguna, ¿qué pasó ahí?".

Guion mínimo, atado a §7: instalar delante tuyo sin ayuda, llegar al primer check,
agregar un ejercicio, encontrar lo de ayer. Callarse y mirar.

**La analítica no reemplaza esto. Le dice dónde mirar.**

---

## 14. Fases

- [ ] **Fase 0 — este doc.** Nombres y params congelados antes de escribir código.
- [ ] **Fase 1 — iOS, solo activación.** El seam + `onboarding_*`, `activity_checked`,
      `exercise_add_started/completed`. Registrar las custom dimensions en la consola
      **antes** de shipear. Verificar con DebugView.
- [ ] **Fase 2 — Android.** Firebase + los mismos eventos, verificados contra este doc.
- [ ] **Fase 3 — el resto** de la tabla de §8 y las user properties de §9.
- [ ] **Fase 4 — lectura.** Un funnel armado en la consola por cada momento de §7.
      BigQuery export solo si hace falta SQL (es gratis en el tier diario).

---

## 15. Cómo se lee

- **Un funnel por semana**, no un dashboard entero. Rotar entre los cinco de §7.
- **Escribir la regla de decisión ANTES de mirar el número.** "Si menos del X% completa
  el alta, rediseñamos el formulario." Sin pre-registro, el dato se racionaliza solo.
- **La cohorte manda.** Métricas absolutas con una base que crece son ilegibles.

---

## 16. Riesgos

| Riesgo | Mitigación |
|---|---|
| La analítica como procrastinación: instrumentar en vez de hablar con usuarios | Fase 1 es chica a propósito; §13 no es opcional |
| Vanity metrics (aperturas, sesiones) | §2.1 — la unidad es la semana activa, no la apertura |
| Drift entre plataformas | Este doc como fuente única; los nombres se revisan en el PR |
| Instrumentation rot | El evento se borra con la feature que lo emite (§8) |
| Sobreleer números con n chico | §13 — acantilados sí, diferencias no |

---

## Fuentes

- [Health & Fitness App Benchmarks (2026) — Business of Apps](https://www.businessofapps.com/data/health-fitness-app-benchmarks/)
- [Mobile App Retention Benchmarks by Industry (2026) — UXCam](https://uxcam.com/blog/mobile-app-retention-benchmarks/)
- [Mobile App Retention Benchmarks 2026 — Snoopr](https://www.snoopr.co/blog/mobile-app-retention-benchmarks-2026-what-good-looks-like-for-fitness-ecommerce-gaming-and-more)
- [Event Taxonomy 101: The Object-Action Framework](https://productanalyticshandbook.com/blog/event-taxonomy-object-action/)
- [Best Practices When Creating or Evolving Your Analytics Tracking — Amplitude](https://amplitude.com/blog/analytics-tracking-practices)
- [Product Analytics: An Event Taxonomy That Won't Rot](https://www.digitalapplied.com/blog/product-analytics-event-taxonomy-tracking-plan-2026)
- [HEART framework: measuring UX with Google's metrics model — Statsig](https://www.statsig.com/perspectives/heart-framework-measuring-ux)
- [How to Set UX Metrics with the Google HEART Framework — The Fountain Institute](https://www.thefountaininstitute.com/blog/goals-signals-metrics)
- [[GA4] Event collection limits — Analytics Help](https://support.google.com/firebase/answer/9237506)
