//
//  StatsView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @Query private var entries: [MuscleEntry]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Summary cards
                HStack(spacing: 12) {
                    StatSummaryCard(
                        titleKey: "stats_total_days",
                        value: "\(viewModel.totalDaysTrained)",
                        icon: "calendar.badge.checkmark"
                    )
                    StatSummaryCard(
                        titleKey: "stats_avg_per_week",
                        value: String(format: "%.1f", viewModel.averageDaysPerWeek),
                        icon: "chart.bar.fill"
                    )
                }
                .padding(.horizontal)

                // MARK: Weekly chart
                if !viewModel.weeklyData.isEmpty {
                    GroupBox {
                        WeeklyTrainingChart(data: viewModel.weeklyData)
                    }
                    .padding(.horizontal)
                }

                // MARK: Muscle frequency chart
                if !viewModel.muscleFrequency.isEmpty {
                    GroupBox {
                        MuscleFrequencyChart(data: viewModel.muscleFrequency)
                    }
                    .padding(.horizontal)
                }

                // MARK: Empty state
                if viewModel.weeklyData.allSatisfy({ $0.count == 0 }) && viewModel.muscleFrequency.isEmpty {
                    ContentUnavailableView(
                        LocalizedStringKey("stats_no_data_title"),
                        systemImage: "chart.bar.xaxis",
                        description: Text("stats_no_data_description")
                    )
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("stats_title")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.update(with: entries)
        }
        .onChange(of: entries) { _, newEntries in
            viewModel.update(with: newEntries)
        }
    }
}

// MARK: - Summary card component

private struct StatSummaryCard: View {
    let titleKey: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color("PrimaryButtonColor"))
                Text(LocalizedStringKey(titleKey))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title.bold())
                .foregroundColor(Color("PrimaryButtonColor"))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: MuscleEntry.self, inMemory: true)
}
