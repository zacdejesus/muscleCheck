//
//  AddMuscleGroupView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/05/2025.
//

import SwiftUI
import SwiftData

struct AddMuscleGroupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var context
    @State private var muscleName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Nuevo grupo") {
                    TextField("Ej: Pilates", text: $muscleName)
                }
            }
            .navigationTitle("Agregar grupo")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard !muscleName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let entry = MuscleEntry(name: muscleName, isCustom: true)
                        context.insert(entry)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }
}
