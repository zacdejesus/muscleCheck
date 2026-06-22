//
//  SessionLogView.swift
//  MuscleCheck
//
//  "Registro" — gym-only session editor. Opens calm (no keyboard): the weight is a big
//  tappable number (tap to type) and sets/reps are steppers. Designed for quick entry and
//  consultation of what you did. The list cell still shows weight only.
//

import SwiftUI

struct SessionLogView: View {

    let entry: MuscleEntry
    /// Callback receives weight in **kg** (canonical storage unit) plus optional sets and reps.
    let onSave: (Double?, Int?, Int?) -> Void

    @State private var weight: String = ""
    @State private var sets: Int = 0
    @State private var reps: Int = 0
    @FocusState private var weightFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// User-preferred unit, read once. Weights are always stored in kg; we convert at the edges.
    private let unit: WeightUnit = UserDefaultsManager.shared.weightUnit

    /// Parsed weight in the display unit (e.g. lbs if unit == .lbs).
    private var parsedWeight: Double? {
        Double(weight.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool { (parsedWeight ?? 0) > 0 }

    /// Date of the most recent recorded session, for the "last trained" subtitle.
    private var lastTrained: Date? { entry.sessions.map(\.date).max() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                Spacer(minLength: 0)

                // Weight hero — the value IS the display; tap it to type. Not auto-focused.
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        TextField("0", text: $weight)
                            .keyboardType(.numberPad)
                            .focused($weightFocused)
                            .multilineTextAlignment(.center)
                            .fixedSize()
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .accessibilityIdentifier("session.weight")
                            .accessibilityLabel(Text(NSLocalizedString("session_field_weight", comment: "")))
                        Text(unit.displayLabel)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }

                    if let lastTrained {
                        Text(String(format: NSLocalizedString("session_last_trained", comment: ""),
                                    lastTrained.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // Sets / Reps — steppers, no keyboard. Each column takes half the width so
                // the −/+ controls stay inside the screen bounds.
                HStack(spacing: 8) {
                    stepperColumn(NSLocalizedString("session_field_sets", comment: ""),
                                  value: $sets, id: "session.sets")
                    stepperColumn(NSLocalizedString("session_field_reps", comment: ""),
                                  value: $reps, id: "session.reps")
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .navigationTitle(entry.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        let kg = parsedWeight.map { unit.toKg($0.rounded()) }
                        // 0 means "not recorded" → store as nil to keep the data clean.
                        onSave(kg, sets == 0 ? nil : sets, reps == 0 ? nil : reps)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                // Prefill so the user can consult/edit what they last did. No auto-focus:
                // the screen should open as a calm readout, not slam up the keyboard.
                if let lastKg = entry.lastWeight {
                    weight = String(format: "%.0f", unit.displayValue(fromKg: lastKg))
                }
                sets = entry.lastSets ?? 0
                reps = entry.lastReps ?? 0
            }
        }
    }

    @ViewBuilder
    private func stepperColumn(_ title: String, value: Binding<Int>, id: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .disabled(value.wrappedValue == 0)
                .accessibilityIdentifier("\(id).minus")

                Text(value.wrappedValue > 0 ? "\(value.wrappedValue)" : "–")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(minWidth: 36)
                    .accessibilityIdentifier("\(id).value")

                Button {
                    value.wrappedValue += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .accessibilityIdentifier("\(id).plus")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
