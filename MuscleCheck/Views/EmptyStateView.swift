//
//  EmptyStateView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 24/10/2025.
//

import SwiftUI

struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "tray")
        .font(.largeTitle)
        .foregroundColor(.gray)
      Text("No_muscles_added_please_add_some_in_top_rigth_corner")
        .foregroundColor(.gray)
        .font(.headline)
    }
    .frame(maxWidth: .infinity, minHeight: 200)
  }
}
