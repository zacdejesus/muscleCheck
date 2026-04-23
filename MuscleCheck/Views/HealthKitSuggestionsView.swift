//
//  HealthKitSuggestionsView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 23/04/2026.
//

import SwiftUI
import HealthKit

struct HealthKitSuggestionsView: View {
    @ObservedObject var healthKitManager: HealthKitManager
    let onLog: (HKWorkout) -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text(String(format: NSLocalizedString("healthkit_workouts_detected", comment: ""), healthKitManager.unloggedWorkouts.count))
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    healthKitManager.dismissAllWorkouts()
                } label: {
                    Text("healthkit_dismiss_all")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ForEach(healthKitManager.unloggedWorkouts, id: \.uuid) { workout in
                workoutRow(workout)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func workoutRow(_ workout: HKWorkout) -> some View {
        let icon = HealthKitManager.iconForWorkout(workout)
        let name = HealthKitManager.suggestedName(for: workout)

        HStack {
            Image(systemName: icon)
                .foregroundColor(Color("PrimaryButtonColor"))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                Text(Self.timeFormatter.string(from: workout.startDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onLog(workout)
                healthKitManager.dismissWorkout(workout)
            } label: {
                Text("healthkit_log_workout")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color("PrimaryButtonColor"))
                    .cornerRadius(8)
            }
        }
    }
}
