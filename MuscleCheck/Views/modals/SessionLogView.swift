//
//  SessionLogView.swift
//  MuscleCheck
//
//  "Registro" — session editor driven by the entry's MetricType. Opens calm (no
//  keyboard): the main value is a big tappable number (tap to type). Strength shows
//  weight + sets/reps steppers; duration shows minutes; distanceDuration shows km
//  with minutes below. Designed for quick entry and consultation of what you did.
//

import SwiftUI

struct SessionLogView: View {

    let entry: MuscleEntry
    /// Callback receives canonical storage units (kg / seconds / meters).
    let onSave: (SessionInput) -> Void

    @State private var weight: String = ""
    @State private var sets: Int = 0
    @State private var reps: Int = 0
    @State private var minutes: String = ""
    @State private var distanceKm: String = ""
    @Environment(\.dismiss) private var dismiss

    /// User-preferred unit, read once. Weights are always stored in kg; we convert at the edges.
    private let unit: WeightUnit = UserDefaultsManager.shared.weightUnit

    /// Parsed weight in the display unit (e.g. lbs if unit == .lbs).
    private var parsedWeight: Double? {
        Double(weight.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedMinutes: Int? {
        Int(minutes)
    }

    private var parsedKm: Double? {
        Double(distanceKm.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        switch entry.metric {
        case .none:
            return false    // unreachable: the row doesn't open the log for .none
        case .strength:
            return (parsedWeight ?? 0) > 0
        case .duration:
            return (parsedMinutes ?? 0) > 0
        case .distanceDuration:
            // A runner may log only one of the two.
            return (parsedKm ?? 0) > 0 || (parsedMinutes ?? 0) > 0
        }
    }

    /// Date of the most recent recorded session, for the "last trained" subtitle.
    private var lastTrained: Date? { entry.sessions.map(\.date).max() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                Spacer(minLength: 0)

                VStack(spacing: 6) {
                    switch entry.metric {
                    case .none, .strength:
                        heroField("0", text: $weight, keyboard: .numberPad,
                                  suffix: unit.displayLabel, id: "session.weight",
                                  labelKey: "session_field_weight")
                    case .duration:
                        heroField("0", text: $minutes, keyboard: .numberPad,
                                  suffix: "min", id: "session.duration",
                                  labelKey: "session_field_duration")
                    case .distanceDuration:
                        heroField("0", text: $distanceKm, keyboard: .decimalPad,
                                  suffix: "km", id: "session.distance",
                                  labelKey: "session_field_distance")
                    }

                    if let lastTrained {
                        Text(String(format: NSLocalizedString("session_last_trained", comment: ""),
                                    lastTrained.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))))
                            .font(.appFootnote)
                            .foregroundStyle(.secondary)
                    }
                }

                switch entry.metric {
                case .none, .strength:
                    // Sets / Reps — steppers, no keyboard. Each column takes half the width
                    // so the −/+ controls stay inside the screen bounds.
                    HStack(spacing: 8) {
                        stepperColumn(NSLocalizedString("session_field_sets", comment: ""),
                                      value: $sets, id: "session.sets")
                        stepperColumn(NSLocalizedString("session_field_reps", comment: ""),
                                      value: $reps, id: "session.reps")
                    }
                case .duration:
                    EmptyView()
                case .distanceDuration:
                    // Secondary time input — smaller than the hero, same tap-to-type idea.
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("session_field_duration", comment: ""))
                            .font(.appSubheadline)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            TextField("0", text: $minutes)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .fixedSize()
                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                .accessibilityIdentifier("session.duration")
                                .accessibilityLabel(Text(NSLocalizedString("session_field_duration", comment: "")))
                            Text("min")
                                .font(.appSubheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                        onSave(sessionInput())
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    /// 0/empty means "not recorded" → stored as nil to keep the data clean.
    private func sessionInput() -> SessionInput {
        switch entry.metric {
        case .none, .strength:
            return SessionInput(
                weightKg: parsedWeight.map { unit.toKg($0.rounded()) },
                sets: sets == 0 ? nil : sets,
                reps: reps == 0 ? nil : reps
            )
        case .duration:
            return SessionInput(durationSeconds: parsedMinutes.map { $0 * 60 })
        case .distanceDuration:
            return SessionInput(
                durationSeconds: (parsedMinutes ?? 0) > 0 ? parsedMinutes.map { $0 * 60 } : nil,
                distanceMeters: (parsedKm ?? 0) > 0 ? parsedKm.map { $0 * 1000 } : nil
            )
        }
    }

    /// Prefill so the user can consult/edit what they last did. No auto-focus:
    /// the screen should open as a calm readout, not slam up the keyboard.
    private func prefill() {
        switch entry.metric {
        case .none, .strength:
            if let lastKg = entry.lastWeight {
                weight = String(format: "%.0f", unit.displayValue(fromKg: lastKg))
            }
            sets = entry.lastSets ?? 0
            reps = entry.lastReps ?? 0
        case .duration:
            if let seconds = entry.lastDurationSeconds {
                minutes = "\(seconds / 60)"
            }
        case .distanceDuration:
            if let meters = entry.lastDistanceMeters {
                distanceKm = String(format: "%.1f", meters / 1000)
            }
            if let seconds = entry.lastDurationSeconds {
                minutes = "\(seconds / 60)"
            }
        }
    }

    // Main value hero — the value IS the display; tap it to type. Not auto-focused.
    @ViewBuilder
    private func heroField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType,
                           suffix: String, id: String, labelKey: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .multilineTextAlignment(.center)
                .fixedSize()
                .font(.system(size: 64, weight: .semibold, design: .rounded))
                .accessibilityIdentifier(id)
                .accessibilityLabel(Text(NSLocalizedString(labelKey, comment: "")))
            Text(suffix)
                .font(.appTitle2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func stepperColumn(_ title: String, value: Binding<Int>, id: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.appSubheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    if value.wrappedValue > 0 { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.appHeadline)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .disabled(value.wrappedValue == 0)
                .accessibilityIdentifier("\(id).minus")

                Text(value.wrappedValue > 0 ? "\(value.wrappedValue)" : "–")
                    .font(.appTitle2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(minWidth: 36)
                    .accessibilityIdentifier("\(id).value")

                Button {
                    value.wrappedValue += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.appHeadline)
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
