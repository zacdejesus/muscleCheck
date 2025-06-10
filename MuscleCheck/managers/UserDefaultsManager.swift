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

    private init() {}

    // MARK: - Semana reseteada

    var lastResetWeek: Int {
        get { defaults.integer(forKey: "lastResetWeek") }
        set { defaults.set(newValue, forKey: "lastResetWeek") }
    }

    var lastResetYear: Int {
        get { defaults.integer(forKey: "lastResetYear") }
        set { defaults.set(newValue, forKey: "lastResetYear") }
    }

    // MARK: - Entradas por defecto creadas

    var defaultEntriesCreated: Bool {
        get { defaults.bool(forKey: "defaultEntriesCreated") }
        set { defaults.set(newValue, forKey: "defaultEntriesCreated") }
    }
}
