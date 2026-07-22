//
//  MockContext.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 11/06/2025.
//

@testable import MuscleCheck
import SwiftData

class MockContext: ModelContextProtocol {

  var inserted: [MuscleEntry] = []
  var saved = false

  func insert<T>(_ model: T) where T : PersistentModel {
    if let entry = model as? MuscleEntry {
      inserted.append(entry)
    }
  }
  
  func delete<T>(_ model: T) where T : PersistentModel {
    if let entry = model as? MuscleEntry {
    }
  }
  
  func fetch<T>(_ descriptor: FetchDescriptor<T>) throws -> [T] where T : PersistentModel {
    return []
  }
  
   func save() throws {
    saved = true
  }
}
