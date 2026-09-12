//
//  AnalyticsService.swift
//  MuscleCheck
//
//  Elige la implementación del seam según cómo corre la app, y las implementaciones.
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

enum AnalyticsService {

    static let shared: any AnalyticsTracking = make(defaults: .standard)

    /// - UI tests (`-uiTesting YES`): NoOp. Las corridas de tests no ensucian los datos.
    /// - Debug: consola. Con `-analyticsDebug YES` además manda a Firebase (sumale
    ///   `-FIRDebugEnabled` para verlo en tiempo real en DebugView).
    /// - Release: Firebase.
    static func make(defaults: UserDefaults) -> any AnalyticsTracking {
        if defaults.bool(forKey: "uiTesting") { return NoOpAnalytics() }
        #if DEBUG
        return defaults.bool(forKey: "analyticsDebug")
            ? FirebaseAnalyticsTracker(echoToConsole: true)
            : ConsoleAnalytics()
        #else
        return FirebaseAnalyticsTracker()
        #endif
    }
}

struct FirebaseAnalyticsTracker: AnalyticsTracking {
    var echoToConsole = false

    func track(_ event: AnalyticsEvent) {
        if echoToConsole { ConsoleAnalytics().track(event) }
        // Mismo guard que CrashDiagnostics: un App Intent puede correr antes de
        // `FirebaseApp.configure()`. Ese evento se pierde en vez de reventar.
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}

struct ConsoleAnalytics: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {
        print("[Analytics] \(event.name) \(event.parameters)")
    }
}

struct NoOpAnalytics: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
}
