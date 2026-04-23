//
//  HealthKitManager.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import Foundation
import HealthKit

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var unloggedWorkouts: [HKWorkout] = []

    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Availability

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard Self.isAvailable else { return false }

        let workoutType = HKObjectType.workoutType()
        let typesToRead: Set<HKObjectType> = [workoutType]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            checkAuthorizationStatus()
            return isAuthorized
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() {
        guard Self.isAvailable else {
            isAuthorized = false
            return
        }
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        // Note: For read-only, HealthKit returns .sharingDenied even when read is granted.
        // We rely on the user toggle + successful authorization request instead.
        isAuthorized = status != .notDetermined || UserDefaultsManager.shared.healthKitEnabled
    }

    // MARK: - Fetch Workouts

    func fetchUnloggedWorkouts(existingEntries: [MuscleEntry]) async {
        guard Self.isAvailable else { return }

        let calendar = Date.appCalendar
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return }

        let predicate = HKQuery.predicateForSamples(
            withStart: sevenDaysAgo,
            end: Date(),
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let workoutType = HKObjectType.workoutType()

        let workouts: [HKWorkout] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let results = samples as? [HKWorkout] ?? []
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }

        // Filter out workouts already logged
        let unlogged = workouts.filter { workout in
            !isWorkoutAlreadyLogged(workout, in: existingEntries)
        }

        self.unloggedWorkouts = unlogged
    }

    func dismissWorkout(_ workout: HKWorkout) {
        unloggedWorkouts.removeAll { $0.uuid == workout.uuid }
    }

    func dismissAllWorkouts() {
        unloggedWorkouts.removeAll()
    }

    // MARK: - Mapping

    static func mapToCategory(_ type: HKWorkoutActivityType) -> ActivityCategory {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining, .crossTraining:
            return .gym
        case .yoga:
            return .yoga
        case .pilates:
            return .pilates
        case .coreTraining, .highIntensityIntervalTraining:
            return .calisthenics
        case .running, .cycling, .swimming, .walking, .hiking,
             .elliptical, .rowing, .stairClimbing, .jumpRope, .mixedCardio:
            return .cardio
        case .cooldown, .preparationAndRecovery, .flexibility:
            return .stretching
        default:
            return .custom
        }
    }

    static func suggestedName(for workout: HKWorkout) -> String {
        let category = mapToCategory(workout.workoutActivityType)
        switch workout.workoutActivityType {
        case .traditionalStrengthTraining: return NSLocalizedString("category_gym", comment: "")
        case .functionalStrengthTraining: return NSLocalizedString("category_gym", comment: "")
        case .yoga: return NSLocalizedString("category_yoga", comment: "")
        case .pilates: return NSLocalizedString("category_pilates", comment: "")
        case .coreTraining, .highIntensityIntervalTraining: return NSLocalizedString("category_calisthenics", comment: "")
        case .running: return NSLocalizedString("cardio_running", comment: "")
        case .cycling: return NSLocalizedString("cardio_cycling", comment: "")
        case .swimming: return NSLocalizedString("cardio_swimming", comment: "")
        case .walking: return NSLocalizedString("cardio_walking", comment: "")
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .cooldown, .flexibility: return NSLocalizedString("category_stretching", comment: "")
        default: return category.displayName
        }
    }

    static func iconForWorkout(_ workout: HKWorkout) -> String {
        let category = mapToCategory(workout.workoutActivityType)
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        default: return category.defaultIcon
        }
    }

    // MARK: - Private

    private func isWorkoutAlreadyLogged(_ workout: HKWorkout, in entries: [MuscleEntry]) -> Bool {
        let workoutDate = workout.startDate
        let calendar = Date.appCalendar

        return entries.contains { entry in
            entry.activityDates.contains { activityDate in
                calendar.isDate(activityDate, inSameDayAs: workoutDate)
            } && Self.mapToCategory(workout.workoutActivityType).rawValue == entry.category
        }
    }
}
