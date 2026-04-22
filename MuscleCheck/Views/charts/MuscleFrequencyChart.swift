//
//  MuscleFrequencyChart.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import SwiftUI
import Charts

struct MuscleFrequencyChart: View {
    let data: [(muscle: String, count: Int)]

    /// Dynamic height: 44 pts per bar, minimum 100.
    private var chartHeight: CGFloat {
        max(CGFloat(data.count) * 44, 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_muscle_frequency_title")
                .font(.headline)

            Chart(Array(data.enumerated()), id: \.offset) { _, item in
                BarMark(
                    x: .value("stats_days", item.count),
                    y: .value("stats_muscle", item.muscle)
                )
                .foregroundStyle(Color("PrimaryButtonColor").gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: chartHeight)
        }
    }
}

#Preview {
    MuscleFrequencyChart(data: [
        (muscle: "Pecho", count: 12),
        (muscle: "Espalda", count: 10),
        (muscle: "Piernas", count: 8),
        (muscle: "Hombros", count: 6),
        (muscle: "Bíceps", count: 5),
    ])
    .padding()
}
