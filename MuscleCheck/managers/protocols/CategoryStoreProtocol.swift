//
//  CategoryStoreProtocol.swift
//  MuscleCheck — Feature: user-defined categories
//

import Foundation

@MainActor
protocol CategoryStoreProtocol {
    /// All user-defined categories, ordered by `sortOrder` (after the built-ins).
    func fetchAll() throws -> [CustomCategory]

    /// Creates and persists a custom category. Validates the name and assigns a
    /// collision-free UUID id and a sortOrder after the built-ins.
    @discardableResult
    func add(name: String, icon: String, tracksWeight: Bool) throws -> CustomCategory

    func delete(_ category: CustomCategory) throws
}
