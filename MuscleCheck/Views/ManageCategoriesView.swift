//
//  ManageCategoriesView.swift
//  MuscleCheck — Feature: user-defined categories
//
//  Lets the user create their own categories beyond the built-in disciplines,
//  list them and delete them. Persists via CategoryStore. Reuses the icon grid
//  pattern from AddMuscleGroupView.
//

import SwiftUI
import SwiftData

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.sortOrder) private var categories: [CustomCategory]

    @State private var name: String = ""
    @State private var selectedIcon: String = ActivityCategory.availableIcons.first ?? "star.fill"
    @State private var tracksWeight: Bool = false
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            // MARK: - New category
            Section("custom_category_section_new") {
                TextField("custom_category_name_placeholder", text: $name)
                Toggle("custom_category_tracks_weight", isOn: $tracksWeight)
                    .tint(Color.brand)
            }

            Section("select_icon") {
                iconGrid
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
                            if category.tracksWeight {
                                Image(systemName: "scalemass")
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

    private var iconGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(ActivityCategory.availableIcons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.appTitle3)
                        .frame(width: 40, height: 40)
                        .background(selectedIcon == icon ? Color.brand.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .foregroundColor(selectedIcon == icon ? Color.brand : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func add() {
        do {
            try CategoryStore(context: context).add(
                name: name,
                icon: selectedIcon,
                tracksWeight: tracksWeight
            )
            // Reset the form for the next one.
            name = ""
            tracksWeight = false
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
