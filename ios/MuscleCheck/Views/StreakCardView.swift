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
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isStreakAlive ? "flame.fill" : "moon.zzz.fill")
                        .font(.appTitle3)
                        .foregroundStyle(viewModel.isStreakAlive ? .streak : .secondary)
                    Text("\(viewModel.currentStreak)")
                        .font(.appTitle.bold())
                        .foregroundColor(viewModel.isStreakAlive ? .streak : .secondary)
                        .contentTransition(.numericText())
                        .animation(.spring, value: viewModel.currentStreak)
                }
                Text("streak_current")
                    .font(.appCaption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Max streak
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.appTitle3)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.maxStreak)")
                        .font(.appTitle.bold())
                        .foregroundColor(.secondary)
                }
                Text("streak_max")
                    .font(.appCaption)
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
