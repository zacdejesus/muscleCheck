//
//  ModelContextProtocol.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 11/06/2025.
//

import SwiftData

protocol ModelContextProtocol {
  func insert<T: PersistentModel>(_ model: T)
  func delete<T: PersistentModel>(_ model: T)
  func save() throws
  func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T]
}
