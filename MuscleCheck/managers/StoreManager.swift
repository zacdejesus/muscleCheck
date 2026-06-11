//
//  StoreManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import Foundation
import RevenueCat

@MainActor
final class StoreManager: ObservableObject, @MainActor StoreManagerProtocol {
    static let shared = StoreManager()
    
    // Replace with your RevenueCat public API key
    private static let apiKey = "appl_jIhCtOfXyaayJwAgfjtdBIIRcUk"
    private static let entitlementID = "MuscleCheck Pro"
    
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var offerings: Offerings?
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)
        
        Task {
            await checkProStatus()
            await loadOfferings()
        }
        
        // Listen for customer info updates
        Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                self.isPro = customerInfo.entitlements[Self.entitlementID]?.isActive == true
            }
        }
    }
    
    // MARK: - StoreManagerProtocol
    
    func purchase(_ packageType: PackageType) async throws {
        guard let offerings = offerings,
              let currentOffering = offerings.current else {
            throw StoreError.noOfferings
        }
        
        let package: Package?
        switch packageType {
        case .monthly:
            package = currentOffering.monthly
        case .yearly:
            package = currentOffering.annual
        case .lifetime:
            package = currentOffering.lifetime
        }
        
        guard let selectedPackage = package else {
            throw StoreError.noOfferings
        }
        
        isLoading = true
        defer { isLoading = false }

        // Rethrow RevenueCat errors as-is: their localizedDescription says *why*
        // (product not available, App Store connection, etc.). Mapping everything
        // to a generic StoreError made production failures undiagnosable.
        let result = try await Purchases.shared.purchase(package: selectedPackage)
        if result.userCancelled {
            throw StoreError.userCancelled
        }
        self.isPro = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        let customerInfo = try await Purchases.shared.restorePurchases()
        self.isPro = customerInfo.entitlements[Self.entitlementID]?.isActive == true
    }

    func loadOfferings() async {
        do {
            self.offerings = try await Purchases.shared.offerings()
        } catch {
            print("Failed to load offerings: \(error)")
        }
    }

    /// Retries the offerings fetch if the launch-time load failed (no network,
    /// products not yet available, etc.). Called when the paywall opens so it
    /// doesn't stay dead for the rest of the session.
    func loadOfferingsIfNeeded() async {
        guard offerings == nil else { return }
        await loadOfferings()
    }
    
    // MARK: - Private
    
    private func checkProStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.isPro = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("Failed to check pro status: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    func priceString(for packageType: PackageType) -> String? {
        guard let currentOffering = offerings?.current else { return nil }
        
        let package: Package?
        switch packageType {
        case .monthly:
            package = currentOffering.monthly
        case .yearly:
            package = currentOffering.annual
        case .lifetime:
            package = currentOffering.lifetime
        }
        
        return package?.localizedPriceString
    }
}
