//
//  ModalWeightView.swift
//  MuscleCheck
//
//  Created by z Air on 17/05/2026.
//

import SwiftUI

struct ModalWeightView: View {

    let entry: MuscleEntry
    /// Callback receives the weight in **kg** (canonical storage unit). Nil if user cleared.
    let onSave: (Double?) -> Void

    @State private var weight: String = ""
    @FocusState private var isWeightFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    /// User-preferred unit, read once at view init. Weights are always stored in kg internally;
    /// we convert at the display/input boundary.
    private let unit: WeightUnit = UserDefaultsManager.shared.weightUnit

    /// Parsed numeric value of the input, in the display unit (e.g. lbs if unit == .lbs).
    private var parsedValue: Double? {
        Double(weight.replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        guard let value = parsedValue else { return false }
        return value > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("", text: $weight)
                            .keyboardType(.numberPad)
                            .focused($isWeightFieldFocused)
                        Text(unit.displayLabel)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(entry.name)
                }
            }
            .navigationTitle(NSLocalizedString("weight_modal_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        // Input is in display unit; weights are whole numbers, so round
                        // before converting to kg for storage.
                        let kg = parsedValue.map { unit.toKg($0.rounded()) }
                        onSave(kg)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let lastKg = entry.lastWeight {
                    let displayed = unit.displayValue(fromKg: lastKg)
                    // Weights are whole numbers — prefill rounded, no decimals.
                    weight = String(format: "%.0f", displayed)
                }
                // Slight delay so the sheet's transition finishes before the keyboard
                // animates up — focusing synchronously inside onAppear is usually ignored.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isWeightFieldFocused = true
                }
            }
        }
    }
}
