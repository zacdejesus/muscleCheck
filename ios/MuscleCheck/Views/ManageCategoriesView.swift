//
//  ManageCategoriesView.swift
//  MuscleCheck — Feature: user-defined categories
//
//  Lets the user create their own categories beyond the built-in disciplines,
//  list them and delete them. Persists via CategoryStore. Creation also lives
//  inline in AddExerciseView; both funnel through the same store.
//

import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.sortOrder) private var categories: [CustomCategory]

    @State private var name: String = ""
    @State private var selectedIcon: String = ActivityCategory.availableIcons.first ?? "star.fill"
    @State private var defaultMetric: MetricType = .none
    @State private var errorMessage: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            // MARK: - New category
            Section("custom_category_section_new") {
                TextField("custom_category_name_placeholder", text: $name)
                Picker("custom_category_default_metric", selection: $defaultMetric) {
                    ForEach(MetricType.allCases) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .tint(Color.brand)
            }

            Section("select_icon") {
                IconGridPicker(selectedIcon: $selectedIcon)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.appSubheadline)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("custom_category_add") { add() }
                    .disabled(trimmedName.isEmpty)
            }

            // MARK: - Existing categories
            Section("custom_category_section_yours") {
                if categories.isEmpty {
                    Text("custom_category_empty")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(categories) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .frame(width: 24)
                                .foregroundStyle(Color.brand)
                            Text(category.name)
                            Spacer()
                            if category.defaultMetric != .none {
                                Image(systemName: category.defaultMetric.icon)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle("settings_custom_categories")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.brand)
    }

    private func add() {
        do {
            try CategoryStore(context: context).add(
                name: name,
                icon: selectedIcon,
                defaultMetric: defaultMetric
            )
            // Reset the form for the next one.
            name = ""
            defaultMetric = .none
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        let store = CategoryStore(context: context)
        for index in offsets {
            try? store.delete(categories[index])
        }
    }
}

#Preview {
    NavigationStack {
        ManageCategoriesView()
    }
    .modelContainer(for: CustomCategory.self, inMemory: true)
}
