//
//  AddFAB.swift
//  MuscleCheck
//
//  Floating add button (bottom-right). The toolbar "+" was too small to find —
//  users literally asked where to add things — so the primary action gets the
//  most discoverable spot on screen, Material/Things-style.
//

import SwiftUI

struct AddFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.brand, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        }
        .accessibilityIdentifier("home.addFAB")
        .accessibilityLabel(Text("add_new_muscle_group"))
    }
}
