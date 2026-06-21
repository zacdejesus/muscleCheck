//
//  MuscleEntryRowView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 02/06/2025.
//


import SwiftUI

struct MuscleEntryRowView: View {
    var entry: MuscleEntry
    var onTap: (MuscleEntry) -> Void
    var onSaveSession: (MuscleEntry, Double?, Int?, Int?) -> Void = { _, _, _, _ in }

    @State private var isShowingModal: Bool = false

    private var canEditWeight: Bool {
        entry.category == ActivityCategory.gym.rawValue
    }

    var body: some View {
        HStack(spacing: 0) {
            // One tap target for the whole row (except the checkmark): opens the weight
            // modal for gym entries. Avoids the dead/ambiguous zones between icon and name.
            HStack {
                Image(systemName: entry.icon)
                    .foregroundColor(Color("PrimaryButtonColor"))
                    .frame(width: 24)
                Text(entry.name)
                if canEditWeight, let weightLabel = entry.formattedLastWeight {
                    Text(weightLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard canEditWeight else { return }
                isShowingModal = true
            }

            // Isolated tap target. `.plain` style is required: without it, a Button inside
            // a List row makes the ENTIRE row toggle, so any stray tap flipped the check.
            Button {
                onTap(entry)
            } label: {
                Image(systemName: entry.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(entry.isChecked ? .green : .gray)
                    .padding(.leading, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isShowingModal) {
            SessionLogView(entry: entry) { newWeight, newSets, newReps in
                onSaveSession(entry, newWeight, newSets, newReps)
            }
        }
    }
}
