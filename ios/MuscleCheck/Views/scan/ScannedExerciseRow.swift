//
//  ScannedExerciseRow.swift
//  MuscleCheck — Feature: escanear rutina en papel
//
//  One exercise card on the review screen. Always expanded, every field live:
//  the user reads the whole list at once and fixes only what's wrong. Doubt is an amber
//  dot, never a filled field; a pair that looks backwards gets a one-tap "Dar vuelta".
//

import SwiftUI

struct ScannedExerciseRow: View {

    @Binding var draft: ScannedExerciseDraft
    let groups: [MuscleEntry]
    var onSwap: () -> Void

    private enum Field: Hashable { case sets, reps }
    @FocusState private var focusedField: Field?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// 74 pt at the default size, growing with Dynamic Type so the number never clips.
    @ScaledMetric(relativeTo: .body) private var numberFieldWidth: CGFloat = 74

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            nameLine

            // Sets · reps · group on one line. At accessibility sizes the group drops below,
            // but sets and reps stay side by side: they read as one "4 × 8" pair.
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) { setsField; repsField }
                    groupMenu
                }
            } else {
                HStack(spacing: 8) { setsField; repsField; groupMenu }
            }

            if case .new = draft.group {
                TextField("scan_new_group_placeholder", text: newGroupName)
                    .textFieldStyle(.plain)
                    .font(.appBody)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
            }

            if let hint = repHint {
                hint
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }

            if draft.suggestsSwap, let sets = draft.sets, let reps = draft.reps {
                swapHint(sets: sets, reps: reps)
            }
        }
        .padding(14)
        .background(Color.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Lines

    private var nameLine: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField("scan_exercise_name_placeholder", text: $draft.name, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.appTitle3.weight(.semibold))
                .lineLimit(1...3)
                .frame(minHeight: 30)
            if draft.lowConfidence {
                Circle()
                    .fill(Color.streakText)
                    .frame(width: 7, height: 7)
                    .accessibilityElement()
                    .accessibilityLabel(Text("scan_low_confidence_a11y"))
            }
        }
    }

    private var setsField: some View {
        numberField($draft.sets, suffix: "scan_sets_suffix", label: "scan_sets_placeholder", field: .sets)
    }

    private var repsField: some View {
        numberField($draft.reps, suffix: "scan_reps_suffix", label: "scan_reps_placeholder", field: .reps)
    }

    private func numberField(_ value: Binding<Int?>, suffix: LocalizedStringKey, label: LocalizedStringKey, field: Field) -> some View {
        HStack(spacing: 4) {
            TextField(label, value: value, format: .number, prompt: Text(verbatim: "–"))
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .font(.appBody)
                .focused($focusedField, equals: field)
            Text(suffix)
                .font(.appFootnote)
                .foregroundStyle(.secondary)
                .fixedSize()
        }
        .padding(.horizontal, 10)
        .frame(width: numberFieldWidth)
        .frame(minHeight: 44)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        // The suffix is part of the target: a tap anywhere in the box starts typing.
        .onTapGesture { focusedField = field }
    }

    private var groupMenu: some View {
        Menu {
            ForEach(groups) { group in
                Button {
                    draft.group = .existing(group.id)
                } label: {
                    if draft.group == .existing(group.id) {
                        Label(group.name, systemImage: "checkmark")
                    } else {
                        Text(group.name)
                    }
                }
            }
            Divider()
            Button {
                if case .new = draft.group { return }
                draft.group = .new(draft.suggestedGroupName)
            } label: {
                Label("scan_group_new_menu", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 4) {
                Text(groupTitle)
                    .font(.appBody)
                    .foregroundStyle(draft.group == nil ? Color.streakText : Color.brand)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 4)
                Image(systemName: "chevron.down")
                    .font(.appFootnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                // The one blocking state gets a visible edge, not just a colour.
                if draft.group == nil {
                    RoundedRectangle(cornerRadius: 10).strokeBorder(Color.streakText, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func swapHint(sets: Int, reps: Int) -> some View {
        // The swap turns "sets × reps" into "reps × sets", so ask about THAT reading.
        let question = Text("scan_swap_question \(reps) \(sets)")
            .font(.appSubheadline)
            .foregroundStyle(Color.streakText)
        let button = Button("scan_swap_button", action: onSwap)
            .fontWeight(.semibold)
            .buttonStyle(.bordered)
            .tint(Color.brand)
            .fixedSize()
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                question.lineLimit(1)
                Spacer(minLength: 0)
                button
            }
            VStack(alignment: .leading, spacing: 8) {
                question
                button
            }
        }
    }

    // MARK: - Derived

    private var groupTitle: String {
        switch draft.group {
        case .existing(let id):
            return groups.first { $0.id == id }?.name ?? String(localized: "scan_group_unset")
        case .new:
            // The name lives in the field right below; repeating it here read as a duplicate.
            return String(localized: "scan_group_new")
        case nil:
            return String(localized: "scan_group_unset")
        }
    }

    /// "La hoja dice 8-12 · se guarda 8", or just "La hoja dice AMRAP" when there's no number.
    private var repHint: Text? {
        guard let range = draft.repRangeHint else { return nil }
        if let reps = draft.reps {
            return Text("scan_rep_range_hint \(range) \(reps)")
        }
        return Text("scan_rep_text_hint \(range)")
    }

    private var newGroupName: Binding<String> {
        Binding {
            if case .new(let name) = draft.group { return name }
            return ""
        } set: { name in
            draft.group = .new(name)
        }
    }
}
