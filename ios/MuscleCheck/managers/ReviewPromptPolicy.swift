//
//  ReviewPromptPolicy.swift
//  MuscleCheck
//
//  Cuándo pedir la reseña del App Store. Pura, para que los bordes se testeen sin UI.
//
//  iOS muestra el pedido como mucho 3 veces por año, y puede decidir no mostrarlo nunca.
//  Así que no se gasta: se pide cuando el usuario ya tiene algo que valorar — dos semanas
//  seguidas entrenando, que es justo el hábito que la app promete — y una vez por versión.
//

import Foundation

enum ReviewPromptPolicy {

    /// Semanas seguidas con entrenamiento. Con una sola, el usuario todavía no vio la app
    /// hacer lo suyo: que la lista vuelva a empezar el lunes y la racha siga.
    static let minimumStreakWeeks = 2

    /// Aire entre pedidos aunque cambie la versión: una actualización por semana no puede
    /// convertirse en un pedido por semana.
    static let minimumDaysBetweenRequests = 120

    static func shouldRequest(
        currentStreak: Int,
        lastRequestDate: Date?,
        lastRequestVersion: String?,
        currentVersion: String,
        now: Date = Date()
    ) -> Bool {
        guard currentStreak >= minimumStreakWeeks else { return false }
        guard lastRequestVersion != currentVersion else { return false }
        if let lastRequestDate,
           let days = Date.appCalendar.dateComponents([.day], from: lastRequestDate, to: now).day,
           days < minimumDaysBetweenRequests {
            return false
        }
        return true
    }
}
