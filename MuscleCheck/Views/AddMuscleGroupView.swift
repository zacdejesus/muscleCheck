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
    @State private var selectedCategory: ActivityCategory = .gym
    @State private var selectedIcon: String = ActivityCategory.gym.defaultIcon

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section("add_exercise") {
                    TextField("new_excersise_placeholder", text: $muscleName)
                }

                Section("select_category") {
                    Picker("select_category", selection: $selectedCategory) {
                        ForEach(ActivityCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.defaultIcon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("select_icon") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(ActivityCategory.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        selectedIcon == icon
                                            ? Color("PrimaryButtonColor").opacity(0.2)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .foregroundColor(
                                        selectedIcon == icon
                                            ? Color("PrimaryButtonColor")
                                            : .secondary
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("add_exercise")
            .onChange(of: selectedCategory) { _, newCategory in
                selectedIcon = newCategory.defaultIcon
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        guard !muscleName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let entry = MuscleEntry(
                            name: muscleName,
                            category: selectedCategory.rawValue,
                            icon: selectedIcon
                        )
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
