//
//  StoreManagerProtocol.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import Foundation

protocol StoreManagerProtocol: ObservableObject {
    var isPro: Bool { get }
    var isLoading: Bool { get }
    func purchase(_ packageType: PackageType) async throws
    func restorePurchases() async throws
    func loadOfferings() async
}

enum PackageType: String, CaseIterable {
    case monthly
    case yearly
    case lifetime
}

enum StoreError: LocalizedError {
    case purchaseFailed
    case restoreFailed
    case noOfferings
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed: return NSLocalizedString("store_error_purchase_failed", comment: "")
        case .restoreFailed: return NSLocalizedString("store_error_restore_failed", comment: "")
        case .noOfferings: return NSLocalizedString("store_error_no_offerings", comment: "")
        case .userCancelled: return NSLocalizedString("store_error_user_cancelled", comment: "")
        }
    }
}
