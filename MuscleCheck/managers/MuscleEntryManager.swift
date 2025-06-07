//
//  MuscleEntryManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 30/05/2025.
//

import Foundation
import SwiftData

@MainActor
final class MuscleEntryManager {
  private let context: ModelContext
  
  init(context: ModelContext) {
    self.context = context
  }
  
  func addEntry(name: String) {
    let entry = MuscleEntry(name: name)
    context.insert(entry)
    try? context.save()
  }
  
  func fetchAll() throws -> [MuscleEntry] {
    try context.fetch(FetchDescriptor<MuscleEntry>())
  }
  
  func update(_ entry: MuscleEntry) throws {
    try context.save()
  }
}
