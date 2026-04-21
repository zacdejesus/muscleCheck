//
//  StoreManagerTests.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import Testing
@testable import MuscleCheck
import Foundation

struct StoreManagerTests {
    
    @MainActor @Test
    func testMockStoreManagerStartsNotPro() {
        let mock = MockStoreManager()
        #expect(mock.isPro == false)
        #expect(mock.isLoading == false)
    }
    
    @MainActor @Test
    func testPurchaseSetsIsPro() async throws {
        let mock = MockStoreManager()
        try await mock.purchase(.monthly)
        
        #expect(mock.purchaseCalled == true)
        #expect(mock.isPro == true)
    }
    
    @MainActor @Test
    func testPurchaseFailureThrowsError() async {
        let mock = MockStoreManager()
        mock.shouldThrowOnPurchase = true
        
        do {
            try await mock.purchase(.yearly)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StoreError)
        }
    }
    
    @MainActor @Test
    func testRestorePurchasesCalled() async throws {
        let mock = MockStoreManager()
        try await mock.restorePurchases()
        
        #expect(mock.restoreCalled == true)
    }
    
    @MainActor @Test
    func testRestoreFailureThrowsError() async {
        let mock = MockStoreManager()
        mock.shouldThrowOnRestore = true
        
        do {
            try await mock.restorePurchases()
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is StoreError)
        }
    }
    
    @MainActor @Test
    func testLoadOfferingsCalled() async {
        let mock = MockStoreManager()
        await mock.loadOfferings()
        
        #expect(mock.loadOfferingsCalled == true)
    }
    
    @MainActor @Test
    func testPackageTypeCases() {
        let cases = PackageType.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.monthly))
        #expect(cases.contains(.yearly))
        #expect(cases.contains(.lifetime))
    }
}
