//
//  HealthKitManagerProtocol.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import Foundation
import HealthKit

@MainActor
protocol HealthKitManagerProtocol: AnyObject {
    var isAuthorized: Bool { get }
    var unloggedWorkouts: [HKWorkout] { get }

    func requestAuthorization() async -> Bool
    func checkAuthorizationStatus()
    func fetchUnloggedWorkouts(existingEntries: [MuscleEntry]) async
    func dismissWorkout(_ workout: HKWorkout)
    func dismissAllWorkouts()
}
