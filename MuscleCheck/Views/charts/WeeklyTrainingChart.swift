//
//  WeeklyTrainingChart.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 21/04/2026.
//

import SwiftUI
import Charts

struct WeeklyTrainingChart: View {
    let data: [(weekLabel: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stats_weekly_title")
                .font(.headline)

            Chart(Array(data.enumerated()), id: \.offset) { index, item in
                BarMark(
                    x: .value("stats_week", item.weekLabel),
                    y: .value("stats_days", item.count)
                )
                .foregroundStyle(Color("PrimaryButtonColor").gradient)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...7)
            .chartYAxis {
                AxisMarks(values: [0, 1, 2, 3, 4, 5, 6, 7]) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .frame(height: 180)
        }
    }
}

#Preview {
    WeeklyTrainingChart(data: [
        (weekLabel: "Mar 17", count: 3),
        (weekLabel: "Mar 24", count: 5),
        (weekLabel: "Mar 31", count: 2),
        (weekLabel: "Apr 7", count: 6),
        (weekLabel: "Apr 14", count: 4),
    ])
    .padding()
}
