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
        TextField("new_excersise_placeholder", text: $muscleName)
      }
      .navigationTitle("add_exercise")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("save") {
            guard !muscleName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            let entry = MuscleEntry(name: muscleName)
            context.insert(entry)
            dismiss()
          }
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("cancel", role: .cancel) {
            dismiss()
          }
        }
      }
      .tint(Color("PrimaryButtonColor"))
    }
  }
}

#Preview {
    AddMuscleGroupView().modelContainer(for: MuscleEntry.self)
}
