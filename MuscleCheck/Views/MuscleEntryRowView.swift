//
//  MuscleEntryRowView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 02/06/2025.
//


import SwiftUI
import TipKit

struct MuscleEntryRowView: View {
    var entry: MuscleEntry
    /// Tip anchors: ContentView marks exactly one row per tip (first row overall /
    /// first strength row) so the popovers don't repeat on every row.
    var showsCheckTip: Bool = false
    var showsWeightTip: Bool = false
    var onTap: (MuscleEntry) -> Void
    var onSaveSession: (MuscleEntry, SessionInput) -> Void = { _, _ in }

    @State private var isShowingModal: Bool = false

    private let checkTip = CheckActivityTip()
    private let weightTip = LogWeightTip()

    private var canOpenLog: Bool { entry.metric != .none }

    var body: some View {
        HStack(spacing: 0) {
            if showsWeightTip {
                rowBody.popoverTip(weightTip)
            } else {
                rowBody
            }

            if showsCheckTip {
                checkButton.popoverTip(checkTip)
            } else {
                checkButton
            }
        }
        .sheet(isPresented: $isShowingModal) {
            SessionLogView(entry: entry) { input in
                onSaveSession(entry, input)
            }
        }
    }

    // One tap target for the whole row (except the checkmark): opens the session
    // log for entries whose metric records something. Avoids dead/ambiguous zones.
    private var rowBody: some View {
        HStack {
            // Icon in a soft tinted tile (Settings/Things-style) — adds depth and reads
            // as designed rather than a flat coloured glyph. Ready to colour per category.
            Image(systemName: entry.icon)
                .font(.appSubheadline)
                .foregroundStyle(Color.brand)
                .frame(width: 32, height: 32)
                .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                .padding(.trailing, 4)
            Text(entry.name)
            if let metricLabel = entry.formattedLastMetric {
                Text(metricLabel)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canOpenLog else { return }
            isShowingModal = true
        }
    }

    // Isolated tap target. `.plain` style is required: without it, a Button inside
    // a List row makes the ENTIRE row toggle, so any stray tap flipped the check.
    private var checkButton: some View {
        Button {
            onTap(entry)
        } label: {
            Image(systemName: entry.isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(entry.isChecked ? .success : .gray)
                .padding(.leading, 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
