//
//  SettingsViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {

    // Combine: @Published emite cambios que la App observa para cambiar el color scheme
    @Published var appTheme: Int {
        didSet {
            UserDefaultsManager.shared.appTheme = appTheme
        }
    }

    @Published var isRestoring = false
    @Published var restoreMessage: String?
    @Published var showRestoreAlert = false

    /// Whether the daily reminder toggle is on. Requests authorization if turned on.
    @Published var notificationsEnabled: Bool {
        didSet {
            guard !_blockNotificationDidSet else { return }
            UserDefaultsManager.shared.notificationsEnabled = notificationsEnabled
            handleNotificationsToggle()
        }
    }

    /// The time-of-day for the daily reminder (only hour/minute components matter).
    @Published var reminderTime: Date {
        didSet {
            let cal = Calendar.current
            UserDefaultsManager.shared.reminderHour = cal.component(.hour, from: reminderTime)
            UserDefaultsManager.shared.reminderMinute = cal.component(.minute, from: reminderTime)
            Task { await updateDailyReminder() }
        }
    }

    private var _blockNotificationDidSet = false
    private let storeManager: StoreManager

    // Combine: cancellables almacena las suscripciones activas
    private var cancellables = Set<AnyCancellable>()

    init(storeManager: StoreManager = .shared) {
        self.storeManager = storeManager
        self.appTheme = UserDefaultsManager.shared.appTheme
        self.notificationsEnabled = UserDefaultsManager.shared.notificationsEnabled
        self.reminderTime = Self.reminderTimeFromDefaults()
    }

    private static func reminderTimeFromDefaults() -> Date {
        let cal = Calendar.current
        var components = DateComponents()
        components.hour = UserDefaultsManager.shared.reminderHour
        components.minute = UserDefaultsManager.shared.reminderMinute
        return cal.date(from: components) ?? Date()
    }

    private func handleNotificationsToggle() {
        Task {
            if notificationsEnabled {
                let granted = await NotificationManager.shared.requestAuthorization()
                if !granted {
                    // Permission denied — revert the toggle without re-triggering didSet
                    _blockNotificationDidSet = true
                    notificationsEnabled = false
                    UserDefaultsManager.shared.notificationsEnabled = false
                    _blockNotificationDidSet = false
                    return
                }
            }
            await updateDailyReminder()
        }
    }

    private func updateDailyReminder() async {
        if UserDefaultsManager.shared.notificationsEnabled {
            await NotificationManager.shared.scheduleDailyReminder(
                hour: UserDefaultsManager.shared.reminderHour,
                minute: UserDefaultsManager.shared.reminderMinute
            )
        } else {
            NotificationManager.shared.cancelDailyReminder()
        }
    }

    // Convierte el Int de UserDefaults a ColorScheme? para SwiftUI
    var colorScheme: ColorScheme? {
        switch appTheme {
        case 1: return .light
        case 2: return .dark
        default: return nil // system
        }
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var isPro: Bool {
        storeManager.isPro
    }

    func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await storeManager.restorePurchases()
            restoreMessage = storeManager.isPro
                ? NSLocalizedString("settings_restore_success", comment: "")
                : NSLocalizedString("settings_restore_not_found", comment: "")
        } catch {
            restoreMessage = NSLocalizedString("settings_restore_error", comment: "")
        }
        showRestoreAlert = true
    }

    func openManageSubscription() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

    func openPrivacyPolicy() {
        // Reemplazar con tu URL real
        guard let url = URL(string: "https://example.com/privacy") else { return }
        UIApplication.shared.open(url)
    }
}
