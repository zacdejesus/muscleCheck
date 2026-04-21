//
//  MockStoreManager.swift
//  MuscleCheckTests
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import Foundation
@testable import MuscleCheck

@MainActor
final class MockStoreManager: ObservableObject, StoreManagerProtocol {
    @Published var isPro: Bool = false
    @Published var isLoading: Bool = false
    
    var purchaseCalled = false
    var restoreCalled = false
    var loadOfferingsCalled = false
    var shouldThrowOnPurchase = false
    var shouldThrowOnRestore = false
    
    func purchase(_ packageType: PackageType) async throws {
        purchaseCalled = true
        if shouldThrowOnPurchase {
            throw StoreError.purchaseFailed
        }
        isPro = true
    }
    
    func restorePurchases() async throws {
        restoreCalled = true
        if shouldThrowOnRestore {
            throw StoreError.restoreFailed
        }
    }
    
    func loadOfferings() async {
        loadOfferingsCalled = true
    }
}
