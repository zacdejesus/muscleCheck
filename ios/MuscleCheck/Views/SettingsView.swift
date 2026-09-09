//
//  SettingsView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @EnvironmentObject var viewModel: SettingsViewModel
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.modelContext) private var context
    @State private var showingPaywall = false
    // Crash-test tools: hidden behind 7 taps on the version row, and only reachable
    // in Debug/TestFlight builds (see CrashDiagnostics.isTestBuild).
    @State private var showingCrashTools = CrashDiagnostics.isRevealedByLaunchArgument
    @State private var confirmingTestCrash = false
    @State private var versionTapCount = 0
    @State private var lastVersionTapAt = Date.distantPast

    var body: some View {
        List {
            // MARK: - Subscription
            Section("settings_section_subscription") {
                if !storeManager.isPro {
                    Button {
                        showingPaywall = true
                    } label: {
                        Label("settings_upgrade_pro", systemImage: "crown.fill")
                            .foregroundColor(Color.brand)
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
                .tint(Color.brand)
            }

            // MARK: - Activity Presets
            Section("settings_section_activity_presets") {
                ForEach(ActivityCategory.allCases.filter { $0 != .custom }, id: \.self) { category in
                    Button {
                        viewModel.addPresetEntries(for: category, context: context)
                    } label: {
                        HStack {
                            Image(systemName: category.defaultIcon)
                                .frame(width: 24)
                            Text(category.displayName)
                            Spacer()
                            if viewModel.addedPresets.contains(category.rawValue) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color.brand)
                            }
                        }
                    }
                    .disabled(viewModel.addedPresets.contains(category.rawValue))
                }

                NavigationLink {
                    ManageCategoriesView()
                } label: {
                    Label("settings_custom_categories", systemImage: "folder.badge.plus")
                        .foregroundColor(Color.brand)
                }
            }

            // MARK: - Units
            Section("settings_section_units") {
                Picker("settings_weight_unit", selection: $viewModel.weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.displayLabel).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .tint(Color.brand)
            }

            // MARK: - Health
            Section("settings_section_health") {
                if HealthKitManager.isAvailable {
                    if storeManager.isPro {
                        Toggle("settings_healthkit_enabled", isOn: $viewModel.healthKitEnabled)
                            .tint(Color.brand)
                    } else {
                        ProFeatureGate(lockedMessage: NSLocalizedString("settings_healthkit_enabled", comment: "")) {
                            EmptyView()
                        }
                    }
                } else {
                    Label("settings_healthkit_unavailable", systemImage: "heart.slash")
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - Notifications
            Section("settings_section_notifications") {
                Toggle("settings_notifications_enabled", isOn: $viewModel.notificationsEnabled)
                    .tint(Color.brand)

                if viewModel.notificationsEnabled {
                    DatePicker(
                        "settings_reminder_time",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(Color.brand)
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
                // Deliberately undiscoverable: 7 taps, same idea as Android's
                // developer mode. Strings are hardcoded on purpose — this is a
                // diagnostic tool, not product surface, and it must not land in
                // the localization catalog.
                .contentShape(Rectangle())
                .onTapGesture {
                    // Counting taps by hand instead of `.onTapGesture(count:)`: that
                    // modifier needs all taps inside one tight gesture sequence, and
                    // inside a List row it drops taps constantly. This just needs five
                    // taps with less than two seconds between them.
                    guard CrashDiagnostics.isTestBuild else { return }
                    let now = Date()
                    versionTapCount = now.timeIntervalSince(lastVersionTapAt) > 2 ? 1 : versionTapCount + 1
                    lastVersionTapAt = now
                    if versionTapCount >= 5 { showingCrashTools = true }
                }

                if showingCrashTools {
                    // Text(verbatim:) en todos: un literal suelto en Text/Button es
                    // LocalizedStringKey y Xcode lo extrae al catálogo. La primera
                    // versión de esto metió 6 claves en Localizable.xcstrings.
                    Button {
                        CrashDiagnostics.sendTestNonFatal()
                    } label: {
                        Label {
                            Text(verbatim: "Enviar non-fatal de prueba")
                        } icon: {
                            Image(systemName: "paperplane")
                        }
                    }

                    Button(role: .destructive) {
                        confirmingTestCrash = true
                    } label: {
                        Label {
                            Text(verbatim: "Forzar crash de prueba")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                        }
                    }
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
        .confirmationDialog(Text(verbatim: "¿Forzar un crash de prueba?"),
                            isPresented: $confirmingTestCrash, titleVisibility: .visible) {
            Button(role: .destructive) {
                CrashDiagnostics.forceTestCrash()
            } label: {
                Text(verbatim: "Crashear ahora")
            }
            Button(role: .cancel) {} label: {
                Text(verbatim: "Cancelar")
            }
        } message: {
            Text(verbatim: "La app se va a cerrar. El reporte se envía al VOLVER a abrirla, y solo si Xcode no está adjunto.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(StoreManager.shared)
            .environmentObject(SettingsViewModel())
    }
    .modelContainer(for: MuscleEntry.self)
}
