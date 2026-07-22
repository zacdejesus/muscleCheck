//
//  EmptyStateView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 24/10/2025.
//

import SwiftUI

struct EmptyStateView: View {
  /// The old copy pointed at the top-right toolbar ("add some in the corner") —
  /// users didn't find it. Now the empty state IS an add entry point.
  var onAdd: () -> Void = {}

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "tray")
        .font(.appLargeTitle)
        .foregroundColor(.gray)
      Text("empty_state_message")
        .foregroundColor(.gray)
        .font(.appHeadline)
        .multilineTextAlignment(.center)
      Button(action: onAdd) {
        Label("empty_state_add_button", systemImage: "plus")
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.brand)
      .accessibilityIdentifier("empty.addButton")
    }
    .frame(maxWidth: .infinity, minHeight: 200)
  }
}
