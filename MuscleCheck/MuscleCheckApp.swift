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
  
  init() {
    setNavalBarAppearance()
    
    FirebaseApp.configure()
  }
  
  private func setNavalBarAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.titleTextAttributes = [.foregroundColor: UIColor(Color("PrimaryButtonColor"))]
    appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color("PrimaryButtonColor"))]
    appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color("PrimaryButtonColor"))]
    appearance.setBackIndicatorImage(UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(Color("PrimaryButtonColor")), renderingMode: .alwaysOriginal), transitionMaskImage: UIImage(systemName: "chevron.backward"))
    
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().tintColor = UIColor(Color("PrimaryButtonColor"))
  }
  
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      MuscleEntry.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(for: MuscleEntry.self)
  }
}
