//
//  AddExerciseView.swift
//  MuscleCheck
//
//  Unified add flow (replaces AddMuscleGroupView): category first, then one-tap
//  preset chips for that category, free-text name as the secondary path, and the
//  metric/icon overrides collapsed behind "Options". Creating a NEW category is
//  inline (sentinel picker option) — no more detour through Settings.
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.sortOrder) private var customCategories: [CustomCategory]
    @Query private var entries: [MuscleEntry]

    /// Context-aware default: reopening the sheet starts on the last category used.
    @AppStorage("lastAddCategory") private var lastAddCategory: String = ActivityCategory.gym.rawValue

    @State private var selectedCategoryID: String = ActivityCategory.gym.rawValue
    @State private var muscleName: String = ""
    @State private var selectedIcon: String = ActivityCategory.gym.defaultIcon
    @State private var selectedMetric: MetricType = .strength
    /// Once the user touches the metric picker it stops re-syncing to the category default.
    @State private var metricEdited: Bool = false
    @State private var newCategoryName: String = ""
    @State private var newCategoryMetric: MetricType = .none
    @State private var newCategoryIcon: String = ActivityCategory.custom.defaultIcon
    @State private var errorMessage: String?

    /// Sentinel picker tag for "create a new category". Can't collide: built-ins are
    /// reserved rawValues and custom ids are UUID strings.
    private static let newCategoryID = "__new__"

    private var creatingNewCategory: Bool { selectedCategoryID == Self.newCategoryID }

    private var resolvedCategory: ResolvedCategory {
        CategoryResolver.resolve(selectedCategoryID, custom: customCategories)
    }

    /// Presets of the selected category not yet added — same normalization as
    /// `MuscleEntryManager.isDuplicateName`, so a tapped chip can never hit the
    /// duplicate error and the two paths agree on what "already exists" means.
    private var pendingPresets: [(nameKey: String, icon: String)] {
        guard let builtIn = ActivityCategory(rawValue: selectedCategoryID) else { return [] }
        let existingNames = Set(entries.map { MuscleEntryManager.normalizedName($0.name) })
        return builtIn.presetEntries.filter {
            !existingNames.contains(MuscleEntryManager.normalizedName(NSLocalizedString($0.nameKey, comment: "")))
        }
    }

    private var canSave: Bool {
        let hasName = !muscleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if creatingNewCategory {
            return hasName && !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return hasName
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Category first — it drives presets, metric and icon.
                Section("select_category") {
                    Picker("select_category", selection: $selectedCategoryID) {
                        ForEach(ActivityCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.defaultIcon)
                                .tag(category.rawValue)
                        }
                        ForEach(customCategories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category.id)
                        }
                        Label(NSLocalizedString("add_new_category_option", comment: ""), systemImage: "folder.badge.plus")
                            .tag(Self.newCategoryID)
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("add.categoryPicker")
                }

                // MARK: Inline new-category fields (created on Save, via CategoryStore).
                if creatingNewCategory {
                    Section("custom_category_section_new") {
                        TextField("custom_category_name_placeholder", text: $newCategoryName)
                            .accessibilityIdentifier("add.newCategoryName")
                        Picker("custom_category_default_metric", selection: $newCategoryMetric) {
                            ForEach(MetricType.allCases) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                        // Own icon state: the category's icon is a different concept
                        // than the exercise's — sharing selectedIcon left the new
                        // category with the previous category's leftover glyph.
                        IconGridPicker(selectedIcon: $newCategoryIcon)
                    }
                }

                // MARK: One-tap presets — the fast path, no typing.
                if !pendingPresets.isEmpty {
                    Section("add_section_presets") {
                        presetChips
                    }
                }

                // MARK: Free-text name — the custom path.
                Section("add_exercise") {
                    TextField("new_excersise_placeholder", text: $muscleName)
                        .accessibilityIdentifier("add.nameField")
                }

                // MARK: Rare overrides, collapsed so the happy path stays two decisions.
                Section {
                    DisclosureGroup("add_section_options") {
                        // The edited flag is set in the Binding's setter, NOT via
                        // .onChange — onChange also fires for the programmatic sync
                        // in syncDefaults, which latched the flag without user input
                        // and froze the metric on the first category switch.
                        Picker("metric_picker_label", selection: Binding(
                            get: { selectedMetric },
                            set: { selectedMetric = $0; metricEdited = true }
                        )) {
                            ForEach(MetricType.allCases) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                        .accessibilityIdentifier("add.metricPicker")

                        IconGridPicker(selectedIcon: $selectedIcon)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.appSubheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("add_exercise")
            .onAppear(perform: restoreLastCategory)
            .onChange(of: selectedCategoryID) { _, newID in
                syncDefaults(to: newID)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") { save() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel", role: .cancel) { dismiss() }
                }
            }
            .tint(Color.brand)
        }
    }

    private var presetChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(pendingPresets, id: \.nameKey) { preset in
                Button {
                    addPreset(preset)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.appCaption)
                        Text(NSLocalizedString(preset.nameKey, comment: ""))
                            .font(.appSubheadline)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.brand.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.brand)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("add.preset.\(preset.nameKey)")
            }
        }
        .padding(.vertical, 2)
    }

    /// Start from the last-used category if it still resolves; a deleted custom
    /// category falls back to gym instead of landing on the orphan bucket.
    private func restoreLastCategory() {
        let stillExists = ActivityCategory(rawValue: lastAddCategory) != nil
            || customCategories.contains { $0.id == lastAddCategory }
        selectedCategoryID = stillExists ? lastAddCategory : ActivityCategory.gym.rawValue
        syncDefaults(to: selectedCategoryID)
    }

    /// Icon always follows the category; metric only until the user overrides it.
    private func syncDefaults(to categoryID: String) {
        guard !creatingNewCategory else { return }
        let resolved = CategoryResolver.resolve(categoryID, custom: customCategories)
        selectedIcon = resolved.icon
        if !metricEdited {
            selectedMetric = resolved.defaultMetric
        }
    }

    /// One tap = added. The sheet stays open so several presets can be added in a row;
    /// the chip disappears via the @Query refresh.
    private func addPreset(_ preset: (nameKey: String, icon: String)) {
        do {
            try MuscleEntryManager(context: context).addEntry(
                name: NSLocalizedString(preset.nameKey, comment: ""),
                category: selectedCategoryID,
                icon: preset.icon
            )
            errorMessage = nil
            lastAddCategory = selectedCategoryID
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// If the new category is created but the entry fails validation, the category
    /// persists — acceptable: it's valid data the user meant to create. Crucially the
    /// picker is moved onto the created category right away, so retrying Save after an
    /// entry error does NOT re-run the category creation (which would now throw
    /// duplicateName against the category we just made and wedge the flow).
    private func save() {
        do {
            // Captured before mutating selectedCategoryID (creatingNewCategory is
            // computed from it).
            let wasCreatingCategory = creatingNewCategory
            if wasCreatingCategory {
                let category = try CategoryStore(context: context).add(
                    name: newCategoryName,
                    icon: newCategoryIcon,
                    defaultMetric: newCategoryMetric
                )
                selectedCategoryID = category.id
            }
            try MuscleEntryManager(context: context).addEntry(
                name: muscleName,
                category: selectedCategoryID,
                icon: wasCreatingCategory ? newCategoryIcon : selectedIcon,
                metric: metricEdited ? selectedMetric : nil
            )
            lastAddCategory = selectedCategoryID
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddExerciseView().modelContainer(for: MuscleEntry.self)
}
