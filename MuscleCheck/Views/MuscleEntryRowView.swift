//
//  MuscleEntryRowView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 02/06/2025.
//


import SwiftUI

struct MuscleEntryRowView: View {
    var entry: MuscleEntry
    var emoji: String
    var onTap: (MuscleEntry) -> Void

    var body: some View {
        HStack {
            Text("\(emoji)  \(entry.name)")
            Spacer()
            Button(action: {
                onTap(entry)
            }) {
                Image(systemName: entry.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(entry.isChecked ? .green : .gray)
            }
        }
    }
}
