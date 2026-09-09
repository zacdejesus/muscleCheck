//
//  CrashDiagnostics.swift
//  MuscleCheck
//
//  Thin wrapper over Crashlytics so the app never talks to the SDK directly. Two jobs:
//
//  1. Attach CONTEXT to whatever crashes. A stack trace alone says where it broke; the
//     custom keys say what the app was holding at that moment (how many entries, how
//     many sections, which screen). That's the difference between a report you can act
//     on and one you can only stare at.
//  2. Give a deliberate way to verify the pipeline end to end — that reports, keys and
//     breadcrumbs actually reach the console — without waiting for a real crash.
//
//  The test triggers are NOT available in App Store builds (see `isTestBuild`).
//

import Foundation
import FirebaseCore
import FirebaseCrashlytics

enum CrashDiagnostics {

    /// Debug builds, or any build launched with `-crashTools YES`.
    ///
    /// NOT keyed on the receipt any more. App Review installs builds carrying a
    /// `sandboxReceipt`, exactly like TestFlight, so a receipt-based check would put a
    /// "force a crash" button in front of the reviewer. To exercise this from
    /// TestFlight, launch with the argument instead.
    static var isTestBuild: Bool {
        #if DEBUG
        return true
        #else
        return UserDefaults.standard.bool(forKey: "crashTools")
        #endif
    }

    /// Escape hatch for when the hidden gesture is a nuisance: add `-crashTools YES`
    /// to the scheme's launch arguments and the tools show up already open. Same hook
    /// style the app already uses for `-uiTesting` and `-resetOnboarding`.
    static var isRevealedByLaunchArgument: Bool {
        isTestBuild && UserDefaults.standard.bool(forKey: "crashTools")
    }

    /// Los App Intents pueden correr en un lanzamiento en background donde este código
    /// se ejecuta antes de `FirebaseApp.configure()`. Pedirle Crashlytics a un Firebase
    /// sin configurar revienta, así que todo pasa por acá.
    private static var isConfigured: Bool { FirebaseApp.app() != nil }

    // MARK: - Context

    /// State of the home list, refreshed whenever it changes. These are the numbers
    /// worth having when the list is the thing that crashed.
    static func setHomeState(entries: Int, sections: Int) {
        guard isConfigured else { return }
        let c = Crashlytics.crashlytics()
        c.setCustomValue(entries, forKey: "entries_count")
        c.setCustomValue(sections, forKey: "sections_count")
    }

    /// Breadcrumb. Shows up in the report as a timestamped log, in order, so you can
    /// see what the user did in the seconds before the crash.
    static func log(_ message: String) {
        guard isConfigured else { return }
        Crashlytics.crashlytics().log(message)
    }

    /// A caught error that did NOT crash the app. Today several `catch` blocks return
    /// silently, which means a failure on someone else's device is invisible. This
    /// makes them visible without changing the app's behaviour.
    static func record(_ error: Error, operation: String) {
        guard isConfigured else { return }
        Crashlytics.crashlytics().setCustomValue(operation, forKey: "last_failed_operation")
        Crashlytics.crashlytics().record(error: error)
    }

    // MARK: - Pipeline verification
    //
    // Bajo #if DEBUG: ni el fatalError ni los textos existen en un binario de Release.
    #if DEBUG

    /// Forces a crash, on purpose, with keys and breadcrumbs attached — so the report
    /// that shows up in the console proves the whole chain works, not just the upload.
    ///
    /// Two things about running it, or the report never arrives:
    /// - Crashlytics does NOT upload while Xcode's debugger is attached. Stop the
    ///   debugger and launch the app from the home screen.
    /// - The report is sent on the NEXT launch, not at crash time. Reopen the app.
    static func forceTestCrash() {
        let c = Crashlytics.crashlytics()
        c.setCustomValue("forced_test_crash", forKey: "crash_kind")
        c.setCustomValue(ISO8601DateFormatter().string(from: Date()), forKey: "triggered_at")
        c.log("CrashDiagnostics: about to force a test crash")
        fatalError("MuscleCheck test crash — triggered from Settings")
    }

    /// Same round trip without killing the app: records a non-fatal. Useful to check
    /// that keys and breadcrumbs arrive even when nothing crashes.
    static func sendTestNonFatal() {
        log("CrashDiagnostics: sending test non-fatal")
        record(NSError(domain: "MuscleCheckDiagnostics", code: 1,
                       userInfo: [NSLocalizedDescriptionKey: "Test non-fatal from Settings"]),
               operation: "test_non_fatal")
    }
    #endif
}
