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
    var onSaveWeight: (MuscleEntry, Double?) -> Void = { _, _ in }

    @State private var isShowingModal: Bool = false

    private var canEditWeight: Bool {
        entry.category == ActivityCategory.gym.rawValue
    }

    var body: some View {
        HStack {
            Image(systemName: entry.icon)
                .contentShape(Rectangle())
                .foregroundColor(Color("PrimaryButtonColor"))
                .frame(width: 24)
                .onTapGesture {
                    guard canEditWeight else { return }
                    isShowingModal = true
                }
            Text(entry.name)
                .onTapGesture {
                    guard canEditWeight else { return }
                    isShowingModal = true
                }
            if canEditWeight, let weightLabel = entry.formattedLastWeight {
                Text(weightLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        isShowingModal = true
                    }
            }
            Spacer()
            Button(action: {
                onTap(entry)
            }) {
                Image(systemName: entry.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(entry.isChecked ? .green : .gray)
            }
        }
        .sheet(isPresented: $isShowingModal) {
            ModalWeightView(entry: entry) { newWeight in
                onSaveWeight(entry, newWeight)
            }
        }
    }
}
