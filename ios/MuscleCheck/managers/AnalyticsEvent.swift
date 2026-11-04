//
//  AnalyticsEvent.swift
//  MuscleCheck
//
//  Los eventos de la Fase 1 del plan (docs/analytics-plan.md §8), tipados. Es el ÚNICO
//  lugar donde un evento se convierte en nombre + parámetros: un string suelto en una
//  vista es un typo que no rompe nada — el dato simplemente no llega, y te enterás
//  semanas después mirando un dashboard vacío (la misma lección que el WidgetBridge).
//

import Foundation

enum AnalyticsEvent: Equatable, Sendable {

    /// Por dónde llegó el registro. Parte del uso ocurre fuera de la app (§2.1): sin
    /// esto, alguien que solo usa Siri se lee como abandono.
    enum CheckSource: String, Sendable {
        case app, siri, healthkit
    }

    /// Desde dónde se abrió el alta: dice si el FAB se ve o si la gente sigue llegando
    /// por el empty state (§7.2).
    enum AddSource: String, Sendable {
        case fab
        case emptyState = "empty_state"
    }

    case onboardingStarted
    /// `seedCount`: cuántas disciplinas armaron la lista inicial. `skipped` separa
    /// "eligió" de "salteó": por el conteo solo, saltear y elegir solo gym son iguales.
    case onboardingCompleted(seedCount: Int, skipped: Bool)
    /// Una semana pasa de "no entrenada" a "entrenada" para un grupo, por cualquier vía.
    /// Volver a registrar algo ya entrenado esta semana no es un registro nuevo.
    case activityChecked(category: String, metric: MetricType, source: CheckSource, secondsSinceOpen: Int?)
    case exerciseAddStarted(source: AddSource)
    /// Una presentación del alta que terminó con al menos un alta. `category` y `metric`
    /// son los del último agregado; `count`, cuántos quedaron (los deshechos no suman).
    case exerciseAddCompleted(category: String, metric: MetricType, fromPreset: Bool, count: Int)
    /// The AI coach produced a suggestion (first or "give me another"): which model
    /// answered, why it fell back to on-device if it did, and how long it took (§7.5).
    case coachGenerated(engine: CoachEngine, fallbackReason: CoachFallbackReason?, latencyMilliseconds: Int)

    var name: String {
        switch self {
        case .onboardingStarted: return "onboarding_started"
        case .onboardingCompleted: return "onboarding_completed"
        case .activityChecked: return "activity_checked"
        case .exerciseAddStarted: return "exercise_add_started"
        case .exerciseAddCompleted: return "exercise_add_completed"
        case .coachGenerated: return "coach_generated"
        }
    }

    /// Solo `String` e `Int` (los bool viajan como 0/1): lo que GA4 reporta sin sorpresas.
    var parameters: [String: Any] {
        switch self {
        case .onboardingStarted:
            return [:]
        case let .onboardingCompleted(seedCount, skipped):
            return ["seed_count": seedCount, "skipped": skipped ? 1 : 0]
        case let .activityChecked(category, metric, source, secondsSinceOpen):
            var params: [String: Any] = [
                "category": Self.categoryParameter(category),
                "metric": metric.rawValue,
                "source": source.rawValue
            ]
            // Sin apertura medida (Siri, HealthKit) el parámetro no va: un 0 arrastraría
            // hacia abajo la mediana que mide la promesa de los "2 segundos".
            if let secondsSinceOpen { params["seconds_since_open"] = secondsSinceOpen }
            return params
        case let .exerciseAddStarted(source):
            return ["source": source.rawValue]
        case let .exerciseAddCompleted(category, metric, fromPreset, count):
            return [
                "category": Self.categoryParameter(category),
                "metric": metric.rawValue,
                "from_preset": fromPreset ? 1 : 0,
                "count": count
            ]
        case let .coachGenerated(engine, fallbackReason, latencyMilliseconds):
            var params: [String: Any] = [
                "engine": engine.rawValue,
                "latency_bucket": Self.latencyBucket(milliseconds: latencyMilliseconds)
            ]
            if let fallbackReason { params["fallback_reason"] = fallbackReason.rawValue }
            return params
        }
    }

    /// Coach latency in a few buckets rather than raw milliseconds: enough to see PCC
    /// slowing down without exploding the parameter's cardinality.
    static func latencyBucket(milliseconds: Int) -> String {
        switch milliseconds {
        case ..<2_000: return "<2s"
        case ..<4_000: return "2-4s"
        case ..<6_000: return "4-6s"
        default: return ">6s"
        }
    }

    /// Una categoría custom se guarda como UUID: mandarlo explota la cardinalidad y no
    /// dice nada, y su NOMBRE es texto libre del usuario (§10). Built-in → su raw value;
    /// cualquier otra → "custom".
    static func categoryParameter(_ raw: String) -> String {
        ActivityCategory(rawValue: raw)?.rawValue ?? ActivityCategory.custom.rawValue
    }
}
