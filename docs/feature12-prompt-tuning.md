# Feature 12 — AI Coach: hallazgos de tuning de prompt/instrucción

Resultados de tunear las instrucciones/prompt del coach contra el modelo **real on-device**
(FoundationModels, iOS 26) en un **iPhone 15 Pro físico**. ~70 generaciones en 4 rounds
(2026-05-27). Harness: `MuscleCheckTests/PromptExperiment.swift` (temporal, borrar al cerrar la feature).

## TL;DR — la conclusión que manda

**La rotación NO la puede hacer el modelo de forma confiable. Hay que hacerla en código.**
El modelo on-device (~3B) falla al razonar sobre el historial. La solución que funciona:

1. **Código filtra los grupos elegibles** (excluye los entrenados en los últimos ~1-2 días) y le pasa al modelo **solo esos**.
2. **Código maneja "dame otra"**: excluye también lo recién sugerido → fuerza un día distinto (confirmado).
3. **El modelo hace solo lo acotado**: elegir 2 grupos coherentes de los disponibles + 3 ejercicios c/u.

Con la tarea así de acotada, el modelo es **confiable**. Cuando se le pedía razonar (rotación), fallaba.

## Instrucción ganadora (Round 4)

> Sos un entrenador de gimnasio. De la lista de grupos DISPONIBLES, elegí EXACTAMENTE 2 que formen
> un día coherente que se entrene junto (empuje: pecho/hombros/tríceps; tirón: espalda/bíceps;
> piernas: piernas/abdomen). Elegí por índice. Para CADA grupo dá 3 ejercicios que trabajen
> ESPECÍFICAMENTE ese músculo; nunca pongas ejercicios de otro grupo (ej: no pongas sentadillas en
> bíceps, ni curls en tríceps). Respondé en español.

**Prompt:** solo los grupos disponibles numerados (sin historial — la elegibilidad ya está resuelta en código). `temperature 0.7`, `maximumResponseTokens 512`.

## Qué se probó y qué pasó

**Round 1 (3 variantes, 1 input):** V1 (la del código) ganó; las concisas/recovery-first perdieron coherencia. Primer indicio: la coherencia hay que pedirla explícita.

**Round 2 (I1 vs I2-con-más-reglas, 3 escenarios × 3 runs):**
- **Ambas fallaron la rotación**: en "piernas entrenado ayer" sugirieron piernas igual (3/3). Fijación con "Piernas" (índice 2).
- **I2 (más reglas) salió PEOR**: mezcló ejercicios (peso muerto bajo Hombros, etc.). → más instrucciones = peor en modelo chico.

**Round 3 (instrucción simple + 2 estrategias de rotación-en-código):**
- **A) exclusión en el prompt** ("no recomiendes X"): a veces viola la exclusión, sigue fijado en piernas.
- **B) pasar solo elegibles**: PUSH-ayer → Piernas+Abdomen 3/3, TODO 3/3. **Estable y coherente.** Ganó B.

**Round 4 (estrategia B + instrucción afinada para ejercicios):**
- Coherencia ~8/12 limpia (resto borderline tipo legs+back o push+pull antagonista).
- Variedad mejoró (TODO ya no da siempre piernas; dio Pecho+Tríceps).
- "Dame otra" (excluir lo sugerido) → da un día distinto, confirmado 3/3.
- **Residuo terco**: confunde bíceps↔tríceps en ejercicios a veces. Read-only, tolerable.

**Round 5 (idiomas + músculos nuevos, estrategia B + instrucción ganadora):**
- **Idiomas ES/EN/FR:** los tres dan output coherente, localizado y con ejercicios correctos. Las instrucciones/prompt localizados alcanzan. Sin laburo extra.
- **Grupos nuevos/raros** (trapecios, antebrazos, gemelos, glúteos, lumbares): el modelo **se va a lo familiar** — eligió Pecho+Espalda e ignoró los raros las 2 veces. Riesgo: usuarios con grupos custom granulares pueden ver que el coach los subutiliza.
- **Nombres vagos/custom** (tren superior, core, brazos): los **interpreta bien** (tren inferior→piernas, core→abdomen) y da contenido plausible, pero el mislabel de ejercicios reaparece más seguido (metió sentadillas en "Core").
- Conclusión: multilingüe OK. Customización pesada = dos límites (sesgo a lo familiar + más mislabel). Aceptable para v1 (gym, grupos default); documentar.

## Limitaciones observadas del modelo (importante para futuras features de IA)
- No razona confiablemente sobre datos provistos (rotación, "no repitas lo de ayer").
- Se degrada con instrucciones más complejas.
- Confunde dominio (ejercicios mal asignados al grupo).
- Sesgo de anclaje/posición (se fija en un índice).
- Inconsistente run-a-run (por eso temperature + variedad en código).
- Hipo de cold-start ("server responded with an error" en la 1ra llamada) → mitigado con warmup.

**Bien:** output estructurado (`@Generable`) impecable, conocimiento común en tarea acotada, multilingüe, gratis/on-device/rápido.

## Implicancias para el código (pendiente de aplicar)
`MuscleCheckAI.suggestWorkout` (versión actual pasa todos los grupos + historial) hay que ajustarla:
- Filtrar elegibles (excluir entrenados últimos 1-2 días); pasar solo esos.
- Param `exclude: [String]` para "dame otra".
- Instrucción simplificada (la ganadora de arriba); sacar la rotación del prompt.
- Fallback: si quedan <2 elegibles, no filtrar / usar los más descansados.
- Opcional: derivar `focus` en código de los 2 grupos elegidos (el modelo a veces pone un focus raro).
- **UX: usar `streamResponse` (no `respond`)** para mostrar la sugerencia generándose progresivamente (focus → grupos → ejercicios) en lugar de un spinner. Mejor percepción de velocidad.
