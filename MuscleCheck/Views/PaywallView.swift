//
//  PaywallView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/04/2026.
//

import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("PrimaryButtonColor"))
                        
                        Text("paywall_title")
                            .font(.largeTitle.bold())
                        
                        Text("paywall_subtitle")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)
                    
                    // Free vs Pro comparison — so the value of upgrading is explicit.
                    PlanComparisonView()
                        .padding(.horizontal, 24)
                    
                    // Package selection
                    VStack(spacing: 12) {
                        PackageOptionView(
                            title: NSLocalizedString("paywall_yearly", comment: ""),
                            price: viewModel.priceString(for: .yearly),
                            badge: NSLocalizedString("paywall_best_value", comment: ""),
                            isSelected: viewModel.selectedPackage == .yearly
                        ) {
                            viewModel.selectedPackage = .yearly
                        }
                        
                        PackageOptionView(
                            title: NSLocalizedString("paywall_monthly", comment: ""),
                            price: viewModel.priceString(for: .monthly),
                            badge: nil,
                            isSelected: viewModel.selectedPackage == .monthly
                        ) {
                            viewModel.selectedPackage = .monthly
                        }
                        
                        PackageOptionView(
                            title: NSLocalizedString("paywall_lifetime", comment: ""),
                            price: viewModel.priceString(for: .lifetime),
                            badge: NSLocalizedString("paywall_one_time", comment: ""),
                            isSelected: viewModel.selectedPackage == .lifetime
                        ) {
                            viewModel.selectedPackage = .lifetime
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Purchase button
                    Button {
                        Task { await viewModel.purchase() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text("paywall_subscribe")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("PrimaryButtonColor"))
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    
                    // Restore button
                    Button {
                        Task { await viewModel.restore() }
                    } label: {
                        Text("paywall_restore")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .disabled(viewModel.isLoading)
                    
                    Spacer(minLength: 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.purchaseSuccess) { _, success in
                if success { dismiss() }
            }
            .task {
                // Retry if the launch-time fetch failed; prices re-render via
                // the observed storeManager when offerings arrive.
                await storeManager.loadOfferingsIfNeeded()
            }
        }
    }
}

// MARK: - Supporting Views

private struct PlanComparisonView: View {
    private struct Row: Identifiable {
        let id = UUID()
        let labelKey: String
        let free: Bool
    }

    // Free rows first, then Pro-only. Reflects what the app actually gates today:
    // stats and notifications ship free; only HealthKit sync and progress photos are Pro.
    private let rows: [Row] = [
        Row(labelKey: "paywall_compare_checklist", free: true),
        Row(labelKey: "paywall_compare_ai", free: true),
        Row(labelKey: "paywall_compare_history", free: true),
        Row(labelKey: "paywall_compare_stats", free: true),
        Row(labelKey: "paywall_compare_notifications", free: true),
        Row(labelKey: "paywall_compare_healthkit", free: false),
        Row(labelKey: "paywall_compare_photos", free: false)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("paywall_compare_free").frame(width: 60)
                Text("paywall_compare_pro").frame(width: 60)
                    .foregroundColor(Color("PrimaryButtonColor"))
            }
            .font(.caption.bold())
            .padding(.bottom, 4)

            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack {
                    Text(LocalizedStringKey(row.labelKey))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    cell(on: row.free, accent: false).frame(width: 60)
                    cell(on: true, accent: true).frame(width: 60)
                }
                .padding(.vertical, 10)
                if index < rows.count - 1 { Divider() }
            }
        }
    }

    @ViewBuilder
    private func cell(on: Bool, accent: Bool) -> some View {
        Image(systemName: on ? "checkmark" : "minus")
            .font(.subheadline.bold())
            .foregroundStyle(on ? (accent ? Color("PrimaryButtonColor") : Color.secondary) : Color.secondary.opacity(0.4))
    }
}

private struct PackageOptionView: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color("PrimaryButtonColor"))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                }
                Spacer()
                Text(price)
                    .font(.subheadline.bold())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("PrimaryButtonColor") : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
