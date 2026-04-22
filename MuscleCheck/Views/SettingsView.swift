//
//  SettingsView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var storeManager: StoreManager
    @State private var showingPaywall = false

    var body: some View {
        List {
            // MARK: - Subscription
            Section("settings_section_subscription") {
                if !storeManager.isPro {
                    Button {
                        showingPaywall = true
                    } label: {
                        Label("settings_upgrade_pro", systemImage: "crown.fill")
                            .foregroundColor(Color("PrimaryButtonColor"))
                    }
                } else {
                    Label("settings_pro_active", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }

                Button {
                    Task { await viewModel.restorePurchases() }
                } label: {
                    if viewModel.isRestoring {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text("settings_restoring")
                        }
                    } else {
                        Label("settings_restore_purchases", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isRestoring)

                Button {
                    viewModel.openManageSubscription()
                } label: {
                    Label("settings_manage_subscription", systemImage: "creditcard")
                }
            }

            // MARK: - Appearance
            Section("settings_section_appearance") {
                Picker("settings_theme", selection: $viewModel.appTheme) {
                    Text("settings_theme_system").tag(0)
                    Text("settings_theme_light").tag(1)
                    Text("settings_theme_dark").tag(2)
                }
                .pickerStyle(.menu)
                .tint(Color("PrimaryButtonColor"))
            }

            // MARK: - Notifications
            Section("settings_section_notifications") {
                Toggle("settings_notifications_enabled", isOn: $viewModel.notificationsEnabled)
                    .tint(Color("PrimaryButtonColor"))

                if viewModel.notificationsEnabled {
                    DatePicker(
                        "settings_reminder_time",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(Color("PrimaryButtonColor"))
                }
            }

            // MARK: - About
            Section("settings_section_about") {
                HStack {
                    Text("settings_version")
                    Spacer()
                    Text(viewModel.appVersion)
                        .foregroundColor(.secondary)
                }

                Button {
                    viewModel.openPrivacyPolicy()
                } label: {
                    Label("settings_privacy_policy", systemImage: "hand.raised")
                }
            }
        }
        .navigationTitle("settings_title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("settings_restore_title", isPresented: $viewModel.showRestoreAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.restoreMessage ?? "")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(storeManager)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(StoreManager.shared)
    }
}
