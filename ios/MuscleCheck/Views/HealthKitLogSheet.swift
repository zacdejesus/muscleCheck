//
//  HealthKitLogSheet.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 14/06/2026.
//

import SwiftUI
import HealthKit

/// Picker shown when logging a HealthKit workout. HealthKit only reports the activity type
/// (e.g. strength training), not which muscles were worked — so the user chooses which
/// entries of that category to mark. Multi-select (you might train chest + triceps).
struct HealthKitLogSheet: View {
    let workout: HKWorkout
    /// Entries belonging to the workout's mapped category.
    let candidates: [MuscleEntry]
    let onConfirm: ([MuscleEntry]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(candidates) { entry in
                        Button {
                            toggle(entry)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: entry.icon)
                                    .foregroundColor(Color.brand)
                                    .frame(width: 24)
                                Text(entry.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected.contains(entry.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.brand)
                                        .fontWeight(.semibold)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(HealthKitManager.suggestedName(for: workout))
                }
            }
            .navigationTitle("healthkit_pick_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("healthkit_log_workout") {
                        onConfirm(candidates.filter { selected.contains($0.id) })
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
            }
            .onAppear {
                // Single-entry category → preselect it so confirming is one tap.
                if candidates.count == 1, let only = candidates.first {
                    selected = [only.id]
                }
            }
        }
    }

    private func toggle(_ entry: MuscleEntry) {
        if selected.contains(entry.id) {
            selected.remove(entry.id)
        } else {
            selected.insert(entry.id)
        }
    }
}
