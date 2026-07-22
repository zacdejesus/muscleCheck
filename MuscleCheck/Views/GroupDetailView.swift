//
//  GroupDetailView.swift
//  MuscleCheck — Feature: exercises inside a group (Fase 2)
//
//  Opened by tapping a group's row (for groups whose metric logs something). Lists
//  the group's exercises with their last values; tap one to edit, or add a new one.
//  The weekly CHECK stays on the home row — entering here is never required to mark
//  the group trained. Logging an exercise here also marks the group trained today.
//

import SwiftUI

struct GroupDetailView: View {
    let entry: MuscleEntry
    /// Log an exercise's session (kg/s/m). The VM persists + marks the group trained.
    var onLog: (Exercise, SessionInput) -> Void
    var onAddExercise: (String, MetricType, String) -> Void
    var onDeleteExercise: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editing: Exercise?
    @State private var addingExercise = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if entry.exercises.isEmpty {
                        Text(String(format: NSLocalizedString("group_no_exercises", comment: ""), entry.name))
                            .font(.appSubheadline)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(entry.exercises) { ex in
                        Button { editing = ex } label: { exerciseRow(ex) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        offsets.map { entry.exercises[$0] }.forEach(onDeleteExercise)
                    }

                    Button {
                        addingExercise = true
                    } label: {
                        Label("group_add_exercise", systemImage: "plus")
                            .foregroundStyle(Color.brand)
                    }
                    .accessibilityIdentifier("group.addExercise")
                }
            }
            .navigationTitle(entry.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("add_done") { dismiss() }
                }
            }
            .sheet(item: $editing) { ex in
                SessionLogView(target: SessionLogTarget(exercise: ex)) { input in
                    onLog(ex, input)
                }
            }
            .sheet(isPresented: $addingExercise) {
                AddExerciseToGroupView(defaultMetric: entry.metric, defaultIcon: entry.icon) { name, metric, icon in
                    onAddExercise(name, metric, icon)
                }
            }
            .tint(Color.brand)
        }
    }

    private func exerciseRow(_ ex: Exercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: ex.icon)
                .foregroundStyle(Color.brand)
                .frame(width: 28)
            Text(ex.name)
            Spacer()
            if let summary = ex.summary {
                Text(summary)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.appCaption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

/// Create an exercise inside the current group. Metric/icon default to the group's;
/// name is the only required field (autofocused).
private struct AddExerciseToGroupView: View {
    let defaultMetric: MetricType
    let defaultIcon: String
    var onAdd: (String, MetricType, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var metric: MetricType
    @State private var icon: String
    @FocusState private var nameFocused: Bool

    init(defaultMetric: MetricType, defaultIcon: String, onAdd: @escaping (String, MetricType, String) -> Void) {
        self.defaultMetric = defaultMetric
        self.defaultIcon = defaultIcon
        self.onAdd = onAdd
        _metric = State(initialValue: defaultMetric == .none ? .strength : defaultMetric)
        _icon = State(initialValue: defaultIcon)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("group_exercise_name_placeholder", text: $name)
                        .focused($nameFocused)
                        .accessibilityIdentifier("group.exerciseName")
                    Picker("add_metric_question", selection: $metric) {
                        ForEach(MetricType.allCases.filter { $0 != .none }) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("select_icon") {
                    IconGridPicker(selectedIcon: $icon)
                }
            }
            .navigationTitle("group_add_exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("add_create_confirm") {
                        onAdd(name, metric, icon)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("group.exerciseConfirm")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                }
            }
            .onAppear { nameFocused = true }
            .tint(Color.brand)
        }
    }
}
