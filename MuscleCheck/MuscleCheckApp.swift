//
//  MuscleCheckApp.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct MuscleCheckApp: App {
  
  @StateObject private var storeManager = StoreManager.shared
  @StateObject private var settingsViewModel = SettingsViewModel()
  
  init() {
    setNavalBarAppearance()

    FirebaseApp.configure()
    StoreManager.shared.configure()
    MuscleCheckShortcuts.updateAppShortcutParameters()
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
    let schema = Schema([
      MuscleEntry.self,
      ProgressPhoto.self,
      CustomCategory.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      // 2.1.0 migrated MuscleEntry.activityDates → sessions[]; SwiftData can't
      // auto-migrate this shape, so on schema mismatch we wipe the local store
      // and start fresh rather than crash. ProgressPhoto files on disk are
      // unaffected (only the DB rows are dropped — the orphaned images stay).
      let support = URL.applicationSupportDirectory
      for suffix in ["default.store", "default.store-wal", "default.store-shm"] {
        try? FileManager.default.removeItem(at: support.appending(path: suffix))
      }
      do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
      } catch {
        fatalError("Could not create ModelContainer after wipe: \(error)")
      }
    }
  }()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(storeManager)
        .environmentObject(settingsViewModel)
        .preferredColorScheme(settingsViewModel.colorScheme)
    }
    .modelContainer(sharedModelContainer)
  }
}
