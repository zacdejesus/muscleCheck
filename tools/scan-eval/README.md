# Evaluación del escaneo de rutinas

Mide el scanner real (FoundationModels, iOS 27) con **32 imágenes sintéticas con respuesta
correcta**: a mano (13), PDF/impresos (8), screenshots (7) y negativos (4). Las imágenes y el
manifiesto viven en `ios/MuscleCheckTests/ScanEval/`; el test es `ScanEvaluationTests`.

> El modelo **no corre en el simulador** en una Mac con macOS 26 (falla hasta con texto): la suite
> se corre en un **iPhone con iOS 27 y Apple Intelligence**. En el simulador el test ni se compila.

## Correr (~5–8 min)

1. iPhone conectado y **desbloqueado** (bloqueo automático en "Nunca" mientras corre).
2. Correr el test y guardar el log:
   ```sh
   DEVELOPER_DIR=/Applications/Xcode27.app/Contents/Developer xcodebuild test \
     -project ios/MuscleCheck.xcodeproj -scheme MuscleCheck \
     -destination "id=<UDID del iPhone>" \
     -only-testing:MuscleCheckTests/ScanEvaluationTests \
     -allowProvisioningUpdates | tee /tmp/scan-eval.log
   ```
3. Puntaje (y comparación opcional con una corrida anterior):
   ```sh
   python3 tools/scan-eval/score.py --log /tmp/scan-eval.log --out /tmp/scan-eval-out \
     [--compare /ruta/summary.json]
   ```

El test no falla por resultados: los mide. Imprime una línea `SCANEVAL_RESULT` por caso.

## Qué mide

Detección (tolera nombres abreviados: "Remo" = "Remo con barra"), ejercicios de más, series, reps
(mínimo del rango), músculo, grupo asignado (con 13 grupos en dos idiomas, como el teléfono de
desarrollo), si los errores quedan marcados como dudosos, negativos y tiempos.

## Regenerar las imágenes

```sh
swift tools/scan-eval/gen-cases.swift /tmp/scan-cases            # resolución completa + PDFs + manifest.json
swift tools/scan-eval/to-jpeg.swift /tmp/scan-cases ios/MuscleCheckTests/ScanEval   # JPEG ≤1600 px para el bundle
```

Los casos y su respuesta correcta están definidos en `gen-cases.swift`.

## Resultados (2026-09-14, iPhone 15 Pro)

| | v1 | v2 |
|---|---|---|
| Detección | 86% | 89% |
| Ejercicios de más | 23 | 18 |
| Series / reps | 92% / 81% | 95% / 86% |
| Músculo | 80% | 79% |
| Grupo correcto | 81% | 83% |
| Negativos bien | 0/3 | 1/3 |
| Tiempo típico / máximo | 8,4 s / 50 s | 6,3 s / 22 s |

v2 = sin encabezados de la hoja para asignar grupos, "5x5" en reps separado y filas "none"
descartadas.

Después de la v2:
- **Diccionario ejercicio → músculo** (repasando la salida de la v2 por el código nuevo, sin volver
  a correr el modelo): músculo 79% → **98%**, grupo 83% → **98%**.
- **Pre-chequeo con Vision** (`RoutineTextGateTests`, corre en el simulador): 28/28 rutinas pasan,
  4/4 negativos rechazados.

Pendientes medidos: ver `docs/PENDING.md` (sección Escanear rutina).
