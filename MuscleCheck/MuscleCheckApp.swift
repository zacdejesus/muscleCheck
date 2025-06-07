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
    FirebaseApp.configure()
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
