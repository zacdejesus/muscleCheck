//
//  StreakCardView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import SwiftUI

struct StreakCardView: View {
    @ObservedObject var viewModel: StreakViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Current streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(viewModel.isStreakAlive ? "🔥" : "💤")
                        .font(.title2)
                    Text("\(viewModel.currentStreak)")
                        .font(.title.bold())
                        .foregroundColor(viewModel.isStreakAlive ? Color("PrimaryButtonColor") : .secondary)
                        .contentTransition(.numericText())
                        .animation(.spring, value: viewModel.currentStreak)
                }
                Text("streak_current")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Max streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("🏆")
                        .font(.title2)
                    Text("\(viewModel.maxStreak)")
                        .font(.title.bold())
                        .foregroundColor(.secondary)
                }
                Text("streak_max")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
