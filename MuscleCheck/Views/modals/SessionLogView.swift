//
//  SessionLogView.swift
//  MuscleCheck
//
//  "Registro" — gym-only session editor. Lets the user record and consult what they did
//  today: weight, sets ("series") and reps. Weight is the primary field (auto-focused);
//  sets/reps are optional extras. The list cell still shows only the weight.
//

import SwiftUI

struct SessionLogView: View {

    let entry: MuscleEntry
    /// Callback receives weight in **kg** (canonical storage unit) plus optional sets and reps.
    let onSave: (Double?, Int?, Int?) -> Void

    @State private var weight: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @FocusState private var isWeightFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// User-preferred unit, read once at view init. Weights are always stored in kg internally;
    /// we convert at the display/input boundary.
    private let unit: WeightUnit = UserDefaultsManager.shared.weightUnit

    /// Parsed numeric value of the weight input, in the display unit (e.g. lbs if unit == .lbs).
    private var parsedWeight: Double? {
        Double(weight.replacingOccurrences(of: ",", with: "."))
    }

    private var parsedSets: Int? { Int(sets) }
    private var parsedReps: Int? { Int(reps) }

    private var isValid: Bool {
        guard let value = parsedWeight else { return false }
        return value > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(NSLocalizedString("session_field_weight", comment: ""))
                        Spacer()
                        TextField("", text: $weight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($isWeightFieldFocused)
                            .frame(maxWidth: 100)
                            .accessibilityIdentifier("session.weight")
                        Text(unit.displayLabel)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(NSLocalizedString("session_field_sets", comment: ""))
                        Spacer()
                        TextField("", text: $sets)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                            .accessibilityIdentifier("session.sets")
                    }
                    HStack {
                        Text(NSLocalizedString("session_field_reps", comment: ""))
                        Spacer()
                        TextField("", text: $reps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                            .accessibilityIdentifier("session.reps")
                    }
                } header: {
                    Text(entry.name)
                }
            }
            .navigationTitle(NSLocalizedString("session_modal_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        // Weight input is in display unit; weights are whole numbers, so round
                        // before converting to kg for storage.
                        let kg = parsedWeight.map { unit.toKg($0.rounded()) }
                        onSave(kg, parsedSets, parsedReps)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                // Prefill so the user can consult/edit what they last did.
                if let lastKg = entry.lastWeight {
                    let displayed = unit.displayValue(fromKg: lastKg)
                    weight = String(format: "%.0f", displayed)
                }
                if let lastSets = entry.lastSets { sets = String(lastSets) }
                if let lastReps = entry.lastReps { reps = String(lastReps) }

                // Slight delay so the sheet's transition finishes before the keyboard
                // animates up — focusing synchronously inside onAppear is usually ignored.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isWeightFieldFocused = true
                }
            }
        }
    }
}
