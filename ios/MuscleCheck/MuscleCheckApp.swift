//
//  MuscleCheckApp.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import SwiftUI
import SwiftData
import Firebase
import TipKit

@main
struct MuscleCheckApp: App {
  
  @StateObject private var storeManager = StoreManager.shared
  @StateObject private var settingsViewModel = SettingsViewModel()
  
  init() {
    setNavalBarAppearance()

    // UI-test hook: forces the first-run experience on an already-installed build
    // (persisted flags would otherwise skip onboarding on every run after the first).
    if UserDefaults.standard.bool(forKey: "resetOnboarding") {
      UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
      UserDefaults.standard.removeObject(forKey: "defaultEntriesCreated")
      try? Tips.resetDatastore()
    }

    // Before the first body evaluation, so pre-onboarding users never see the
    // welcome cover flash.
    UserDefaultsManager.shared.migrateOnboardingFlagIfNeeded()

    FirebaseApp.configure()

    // Ahora sí hay SDK: si el arranque anterior tuvo que borrar el store por un schema
    // que no abría, se reporta como non-fatal. Es la única señal de que alguien perdió
    // sus datos por una migración.
    reportStoreWipeIfNeeded()
    StoreManager.shared.configure()
    MuscleCheckShortcuts.updateAppShortcutParameters()

    // UI tests pass -uiTesting (arguments domain): unconfigured TipKit never shows
    // tips, so popovers can't sit on top of the rows the tests need to tap.
    if !UserDefaults.standard.bool(forKey: "uiTesting") {
      try? Tips.configure()
    }
  }
  
  /// Key donde el inicializador del contenedor deja constancia del wipe.
  fileprivate static let storeWipeReasonKey = "lastStoreWipeReason"

  private func reportStoreWipeIfNeeded() {
    let defaults = UserDefaults.standard
    guard let reason = defaults.string(forKey: Self.storeWipeReasonKey) else { return }
    defaults.removeObject(forKey: Self.storeWipeReasonKey)

    CrashDiagnostics.record(
      NSError(domain: "MuscleCheckStore", code: 1,
              userInfo: [NSLocalizedDescriptionKey: "Store wiped on schema mismatch: \(reason)"]),
      operation: "store_wipe"
    )
  }

  private func setNavalBarAppearance() {
    let appearance = UINavigationBarAppearance()
    // iOS 26's Liquid Glass nav bar suppresses the large title on pushed screens
    // when scrollEdgeAppearance is opaque (see HistoryView). Use the default glass
    // background there so large titles render; keep the opaque look on iOS < 26.
    if #available(iOS 26.0, *) {
      appearance.configureWithDefaultBackground()
    } else {
      appearance.configureWithOpaqueBackground()
    }
    // Titles use the label colour, not the brand. Brand stays on actions (back button,
    // bar buttons, tint) so it reads as "tappable", not as decoration on every screen.
    appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
    appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
    appearance.setBackIndicatorImage(UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(Color.brand), renderingMode: .alwaysOriginal), transitionMaskImage: UIImage(systemName: "chevron.backward"))
    
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().tintColor = UIColor(Color.brand)
  }
  
  var sharedModelContainer: ModelContainer = {
    let schema = AppSchema.schema
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      // 2.1.0 migrated MuscleEntry.activityDates → sessions[]; SwiftData can't
      // auto-migrate this shape, so on schema mismatch we wipe the local store
      // and start fresh rather than crash. ProgressPhoto files on disk are
      // unaffected (only the DB rows are dropped — the orphaned images stay).
      // Se anota en UserDefaults en vez de reportarse acá: este closure es el
      // inicializador de una propiedad almacenada, y esos corren ANTES del cuerpo de
      // `init()`, o sea antes de `FirebaseApp.configure()`. Reportar en este punto sería
      // hablarle a un SDK que todavía no existe, que es como esta pérdida de datos venía
      // siendo invisible: el usuario se quedaba sin historial y no llegaba ni un evento.
      UserDefaults.standard.set("\(error)", forKey: Self.storeWipeReasonKey)

      let support = URL.applicationSupportDirectory
      for suffix in ["default.store", "default.store-wal", "default.store-shm"] {
        try? FileManager.default.removeItem(at: support.appending(path: suffix))
      }
      do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
        UserDefaults.standard.set("second attempt failed: \(error)", forKey: Self.storeWipeReasonKey)
        fatalError("Could not create ModelContainer after wipe: \(error)")
      }
    }
  }()
  
  var body: some Scene {
    WindowGroup {
        ContentView(context: sharedModelContainer.mainContext)
        .environmentObject(storeManager)
        .environmentObject(settingsViewModel)
        .preferredColorScheme(settingsViewModel.colorScheme)
    }
    .modelContainer(sharedModelContainer)
  }
}
