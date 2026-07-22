//
//  AddExerciseView.swift
//  MuscleCheck
//
//  Add flow as a PICKER, not a form (recognition over recall): category chips on
//  top, tappable rows of that category's presets below — tap = added, with the row
//  staying visible as "In your list" so success is never silent. Post-UX-crit
//  refinements: rows added in THIS sheet session stay tappable (re-tap = undo,
//  matching the reversible gesture onboarding taught); the sheet opens on the
//  first category with something actionable when the remembered one is complete;
//  creating a custom activity (or category) is pushed one level deeper.
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
    /// Entries created during THIS sheet presentation: still un-addable (re-tap
    /// deletes them — no history to lose). Older entries stay locked: un-adding
    /// those would silently destroy training history.
    @State private var sessionAddedIDs: Set<UUID> = []
    /// Bumped on every successful add — drives the success haptic.
    @State private var addCount = 0
    @State private var errorMessage: String?

    /// `.custom` is the resolver's orphan bucket, not a discipline anyone picks.
    private var selectableBuiltIns: [ActivityCategory] {
        ActivityCategory.allCases.filter { $0 != .custom }
    }

    private var addedNames: Set<String> {
        Set(entries.map { MuscleEntryManager.normalizedName($0.name) })
    }

    private var resolvedCategory: ResolvedCategory {
        CategoryResolver.resolve(selectedCategoryID, custom: customCategories)
    }

    private var isGymSelected: Bool { selectedCategoryID == ActivityCategory.gym.rawValue }

    /// One pickable row and its add-state.
    private struct PickerRow: Identifiable {
        enum State { case available, addedNow, addedBefore }
        let id: String
        let name: String
        let icon: String
        let state: State
        /// The backing entry when added — target for session-scoped undo.
        let entryID: UUID?
        /// Accessibility id suffix — preset key for presets, "own" for user entries.
        let a11yKey: String
    }

    private var rows: [PickerRow] {
        var seen = Set<String>()
        var result: [PickerRow] = []
        let entriesByName = Dictionary(
            entries.map { (MuscleEntryManager.normalizedName($0.name), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        if let builtIn = ActivityCategory(rawValue: selectedCategoryID) {
            for preset in builtIn.presetEntries {
                let name = NSLocalizedString(preset.nameKey, comment: "")
                let normalized = MuscleEntryManager.normalizedName(name)
                guard seen.insert(normalized).inserted else { continue }
                let existing = entriesByName[normalized]
                result.append(PickerRow(
                    id: preset.nameKey,
                    name: name,
                    icon: preset.icon,
                    state: state(for: existing),
                    entryID: existing?.id,
                    a11yKey: preset.nameKey
                ))
            }
        }
        for entry in entries where entry.category == selectedCategoryID {
            let normalized = MuscleEntryManager.normalizedName(entry.name)
            guard seen.insert(normalized).inserted else { continue }
            result.append(PickerRow(
                id: "entry-\(entry.id.uuidString)",
                name: entry.name,
                icon: entry.icon,
                state: state(for: entry),
                entryID: entry.id,
                a11yKey: "own"
            ))
        }
        return result
    }

    private func state(for entry: MuscleEntry?) -> PickerRow.State {
        guard let entry else { return .available }
        return sessionAddedIDs.contains(entry.id) ? .addedNow : .addedBefore
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryChips
                    .padding(.vertical, 10)

                List {
                    Section {
                        ForEach(rows) { row in
                            pickerRow(row)
                        }
                        createOwnRow
                    } header: {
                        Text(promptKey)
                            .font(.appSubheadline)
                            .textCase(nil)
                    } footer: {
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.appSubheadline)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("add_sheet_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Taps already committed — there is nothing to save, so the only
                // exit is "Done". A Save/Cancel pair here reads as unfinished work.
                ToolbarItem(placement: .confirmationAction) {
                    Button("add_done") { dismiss() }
                        .accessibilityIdentifier("add.done")
                }
            }
            .onAppear(perform: pickStartingCategory)
            .tint(Color.brand)
        }
        .sensoryFeedback(.success, trigger: addCount)
    }

    /// Header copy: a question the user can answer ("what do you train?"), switching
    /// to a "you have everything" state when nothing here is actionable — otherwise
    /// the first post-onboarding open (all gym presets seeded) asks a question the
    /// list already answered, over a wall of disabled rows.
    private var promptKey: LocalizedStringKey {
        let allAdded = !rows.isEmpty && rows.allSatisfy { $0.state != .available }
        if allAdded { return "add_picker_all_added" }
        return isGymSelected ? "add_picker_prompt_gym" : "add_picker_prompt_generic"
    }

    // MARK: - Category chips

    // Wrapping grid, not a horizontal scroll: every category is visible at once.
    // A scroll hides options the first-timer can't know exist — and the cut-off
    // chip on the right edge reads as "highlighted", not "there's more".
    private var categoryChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(selectableBuiltIns) { category in
                categoryChip(id: category.rawValue, name: category.displayName, icon: category.defaultIcon)
            }
            ForEach(customCategories) { category in
                categoryChip(id: category.id, name: category.name, icon: category.icon)
            }
            NavigationLink {
                NewCategoryFormView(selectedCategoryID: $selectedCategoryID)
            } label: {
                chipLabel(name: NSLocalizedString("add_new_category_option", comment: ""),
                          icon: "plus", isSelected: false)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("add.newCategory")
        }
        .padding(.horizontal)
    }

    private func categoryChip(id: String, name: String, icon: String) -> some View {
        Button {
            selectedCategoryID = id
            lastAddCategory = id
            errorMessage = nil
        } label: {
            chipLabel(name: name, icon: icon, isSelected: selectedCategoryID == id)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add.category.\(id)")
    }

    private func chipLabel(name: String, icon: String, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.appCaption)
            Text(name)
                .font(.appSubheadline)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.brand : Color(.secondarySystemGroupedBackground), in: Capsule())
        .foregroundStyle(isSelected ? .white : .primary)
    }

    // MARK: - Rows

    @ViewBuilder
    private func pickerRow(_ row: PickerRow) -> some View {
        let locked = row.state == .addedBefore
        return Button {
            switch row.state {
            case .available: add(row)
            case .addedNow: unadd(row)
            case .addedBefore: break
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: row.icon)
                    .foregroundStyle(locked ? Color.secondary : Color.brand)
                    .frame(width: 28)
                Text(row.name)
                    .foregroundStyle(locked ? Color.secondary : Color.primary)
                Spacer()
                trailingControl(row.state)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .accessibilityIdentifier("add.preset.\(row.a11yKey)")
    }

    /// The whole screen is "pick what you train", so the added-this-session state
    /// reads as a SELECTION toggle (filled brand check, tap to deselect) — the
    /// Apple News/Stocks pattern users already know — not a static "En tu lista"
    /// badge that looks un-tappable. Rows added in a previous session keep the
    /// muted badge: they're locked (un-adding would destroy training history).
    @ViewBuilder
    private func trailingControl(_ state: PickerRow.State) -> some View {
        switch state {
        case .available:
            Image(systemName: "circle")
                .font(.appTitle3)
                .foregroundStyle(Color.secondary.opacity(0.5))
        case .addedNow:
            Image(systemName: "checkmark.circle.fill")
                .font(.appTitle3)
                .foregroundStyle(Color.brand)
        case .addedBefore:
            HStack(spacing: 4) {
                Text("add_in_your_list")
                    .font(.appCaption)
                Image(systemName: "checkmark.circle.fill")
            }
            .foregroundStyle(Color.secondary)
        }
    }

    private var createOwnRow: some View {
        NavigationLink {
            CreateEntryFormView(
                categoryID: selectedCategoryID,
                isGym: isGymSelected,
                defaultMetric: resolvedCategory.defaultMetric,
                defaultIcon: resolvedCategory.icon,
                onAdded: { entry in
                    sessionAddedIDs.insert(entry.id)
                    addCount += 1
                }
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .foregroundStyle(Color.brand)
                    .frame(width: 28)
                Text(isGymSelected ? "add_create_custom_gym" : "add_create_custom_generic")
                    .foregroundStyle(Color.brand)
            }
        }
        .accessibilityIdentifier("add.createCustom")
    }

    // MARK: - Actions

    /// One tap = added. The row flips to "In your list" via the @Query refresh and
    /// stays tappable this session (re-tap = undo); the sheet stays open for multi-add.
    private func add(_ row: PickerRow) {
        do {
            let entry = try MuscleEntryManager(context: context).addEntry(
                name: row.name,
                category: selectedCategoryID,
                icon: row.icon
            )
            sessionAddedIDs.insert(entry.id)
            errorMessage = nil
            addCount += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Undo scoped to this sheet session: the entry was created seconds ago and has
    /// no history, so deleting it is safe. Matches the reversible-toggle mental
    /// model the onboarding picker taught.
    private func unadd(_ row: PickerRow) {
        guard let entryID = row.entryID,
              let entry = entries.first(where: { $0.id == entryID }) else { return }
        do {
            try MuscleEntryManager(context: context).delete(entry)
            sessionAddedIDs.remove(entryID)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Start on the remembered category — unless it has nothing actionable (the
    /// post-onboarding reality: every gym preset already seeded). Then jump to the
    /// first built-in that still has pending presets, so the first-timer's first
    /// open shows tappable rows instead of a wall of checkmarks.
    private func pickStartingCategory() {
        let stillExists = ActivityCategory(rawValue: lastAddCategory) != nil
            || customCategories.contains { $0.id == lastAddCategory }
        var candidate = stillExists && lastAddCategory != ActivityCategory.custom.rawValue
            ? lastAddCategory
            : ActivityCategory.gym.rawValue

        if !hasPendingPresets(candidate),
           let firstPending = selectableBuiltIns.first(where: { hasPendingPresets($0.rawValue) }) {
            candidate = firstPending.rawValue
        }
        selectedCategoryID = candidate
    }

    private func hasPendingPresets(_ categoryID: String) -> Bool {
        guard let builtIn = ActivityCategory(rawValue: categoryID) else { return false }
        let added = addedNames
        return builtIn.presetEntries.contains {
            !added.contains(MuscleEntryManager.normalizedName(NSLocalizedString($0.nameKey, comment: "")))
        }
    }
}

// MARK: - Create custom activity (pushed)

/// Escape hatch for names outside the presets. Category is inherited from the
/// picker's active chip — one less decision. Copy adapts: gym creates a "group",
/// everything else an "activity".
private struct CreateEntryFormView: View {
    let categoryID: String
    let isGym: Bool
    let defaultMetric: MetricType
    let defaultIcon: String
    var onAdded: (MuscleEntry) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name: String = ""
    @State private var metric: MetricType
    @State private var icon: String
    @State private var errorMessage: String?
    @FocusState private var nameFocused: Bool

    init(categoryID: String, isGym: Bool, defaultMetric: MetricType, defaultIcon: String, onAdded: @escaping (MuscleEntry) -> Void = { _ in }) {
        self.categoryID = categoryID
        self.isGym = isGym
        self.defaultMetric = defaultMetric
        self.defaultIcon = defaultIcon
        self.onAdded = onAdded
        _metric = State(initialValue: defaultMetric)
        _icon = State(initialValue: defaultIcon)
    }

    var body: some View {
        Form {
            Section {
                TextField(isGym ? "add_name_placeholder_gym" : "add_name_placeholder_generic", text: $name)
                    .focused($nameFocused)
                    .accessibilityIdentifier("add.nameField")
                // navigationLink, not the default menu: "Distancia y tiempo" is
                // too long for an inline menu row and truncated in the middle
                // ("Distan…iempo"). Pushing a sub-list gives each option a full row.
                Picker("add_metric_question", selection: $metric) {
                    ForEach(MetricType.allCases) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.navigationLink)
                .accessibilityIdentifier("add.metricPicker")
            }

            Section("select_icon") {
                IconGridPicker(selectedIcon: $icon)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.appSubheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(isGym ? "add_create_custom_title_gym" : "add_create_custom_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("add_create_confirm") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("add.confirm")
            }
        }
        .onAppear { nameFocused = true }
        .tint(Color.brand)
    }

    private func save() {
        do {
            let entry = try MuscleEntryManager(context: context).addEntry(
                name: name,
                category: categoryID,
                icon: icon,
                metric: metric == defaultMetric ? nil : metric
            )
            onAdded(entry)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Create custom category (pushed from the "+" chip)

private struct NewCategoryFormView: View {
    @Binding var selectedCategoryID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name: String = ""
    @State private var metric: MetricType = .none
    @State private var icon: String = ActivityCategory.custom.defaultIcon
    @State private var errorMessage: String?
    @FocusState private var nameFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("custom_category_name_placeholder", text: $name)
                    .focused($nameFocused)
                    .accessibilityIdentifier("add.newCategoryName")
                Picker("custom_category_default_metric", selection: $metric) {
                    ForEach(MetricType.allCases) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("select_icon") {
                IconGridPicker(selectedIcon: $icon)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.appSubheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("custom_category_section_new")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("custom_category_add") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear { nameFocused = true }
        .tint(Color.brand)
    }

    /// Creates the category and lands the picker on it, ready to add activities.
    private func save() {
        do {
            let category = try CategoryStore(context: context).add(
                name: name,
                icon: icon,
                defaultMetric: metric
            )
            selectedCategoryID = category.id
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddExerciseView().modelContainer(for: MuscleEntry.self)
}
