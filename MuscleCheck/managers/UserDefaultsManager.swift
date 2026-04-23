//
//  UserDefaultsManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 10/06/2025.
//


import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    var lastResetWeek: Int {
        get { defaults.integer(forKey: "lastResetWeek") }
        set { defaults.set(newValue, forKey: "lastResetWeek") }
    }

    var lastResetYear: Int {
        get { defaults.integer(forKey: "lastResetYear") }
        set { defaults.set(newValue, forKey: "lastResetYear") }
    }

    var defaultEntriesCreated: Bool {
        get { defaults.bool(forKey: "defaultEntriesCreated") }
        set { defaults.set(newValue, forKey: "defaultEntriesCreated") }
    }

    // 0 = system, 1 = light, 2 = dark
    var appTheme: Int {
        get { defaults.integer(forKey: "appTheme") }
        set { defaults.set(newValue, forKey: "appTheme") }
    }

    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: "notificationsEnabled") }
        set { defaults.set(newValue, forKey: "notificationsEnabled") }
    }

    /// Hour of day for the daily reminder (0–23). Defaults to 18 (6 PM) if never set.
    var reminderHour: Int {
        get {
            guard defaults.object(forKey: "reminderHour") != nil else { return 18 }
            return defaults.integer(forKey: "reminderHour")
        }
        set { defaults.set(newValue, forKey: "reminderHour") }
    }

    var reminderMinute: Int {
        get { defaults.integer(forKey: "reminderMinute") }
        set { defaults.set(newValue, forKey: "reminderMinute") }
    }

    var addedActivityPresets: [String] {
        get { defaults.stringArray(forKey: "addedActivityPresets") ?? [ActivityCategory.gym.rawValue] }
        set { defaults.set(newValue, forKey: "addedActivityPresets") }
    }
}
