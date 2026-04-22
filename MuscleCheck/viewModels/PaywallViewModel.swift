//
//  PaywallViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var selectedPackage: PackageType = .yearly
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var purchaseSuccess: Bool = false
    
    private let storeManager: StoreManager
    
    init(storeManager: StoreManager = .shared) {
        self.storeManager = storeManager
    }
    
    var isLoading: Bool {
        storeManager.isLoading
    }
    
    func purchase() async {
        do {
            try await storeManager.purchase(selectedPackage)
            purchaseSuccess = true
        } catch let error as StoreError where error == .userCancelled {
            // User cancelled, no error to show
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func restore() async {
        do {
            try await storeManager.restorePurchases()
            if storeManager.isPro {
                purchaseSuccess = true
            } else {
                errorMessage = NSLocalizedString("store_no_purchases_found", comment: "")
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func priceString(for packageType: PackageType) -> String {
        storeManager.priceString(for: packageType) ?? "..."
    }
}
