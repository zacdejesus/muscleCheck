//
//  WeekDetailSection.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 13/06/2026.
//

import SwiftUI

/// The per-day breakdown of the selected week, shown below the calendar.
struct WeekDetailSection: View {
    let days: [DayActivities]

    var body: some View {
        if days.isEmpty {
            ContentUnavailableView(
                LocalizedStringKey("history_week_empty_title"),
                systemImage: "calendar.badge.exclamationmark",
                description: Text("history_week_empty_description")
            )
            .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(days) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Self.dayLabel(day.date))
                            .font(.appSubheadline.bold())
                            .foregroundStyle(Color.brand)
                        ForEach(day.activities) { activity in
                            ActivityDetailRow(activity: activity)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEE d")
        return f
    }()

    private static func dayLabel(_ date: Date) -> String {
        dayFormatter.string(from: date).capitalized
    }
}

// MARK: - Activity row (read-only)

/// Read-only mirror of `MuscleEntryRowView`'s visual: icon + name + that day's
/// logged values per the entry's metric. Deliberately omits the checkmark/edit
/// affordances — history doesn't mutate state.
private struct ActivityDetailRow: View {
    let activity: DayActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: activity.entry.icon)
                    .foregroundColor(Color.brand)
                    .frame(width: 24)
                Text(activity.entry.name)
                // Only show the group's own value when there are no exercises to
                // detail (the group session carries no value once exercises exist).
                if activity.exercises.isEmpty, let label = metricLabel {
                    Text(label)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            // Exercises done that day, indented under the group.
            ForEach(activity.exercises) { ex in
                HStack(spacing: 8) {
                    Text(ex.name)
                        .font(.appCaption)
                    if let s = ex.summary {
                        Text(s)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.leading, 36)
            }
        }
    }

    /// That day's values formatted for the entry's metric, nil when nothing was logged.
    /// Same formatter as the home row (`MuscleEntry.formattedLastMetric`), so the two
    /// can't drift.
    private var metricLabel: String? {
        SessionFormatting.label(
            metric: activity.entry.metric,
            weightKg: activity.weightKg,
            durationSeconds: activity.durationSeconds,
            distanceMeters: activity.distanceMeters
        )
    }
}

#Preview {
    let cal = Date.appCalendar
    let mon = cal.startOfDay(for: Date())
    let pecho = MuscleEntry(name: "Pecho")
    let triceps = MuscleEntry(name: "Tríceps")
    let yoga = MuscleEntry(name: "Yoga", category: ActivityCategory.yoga.rawValue, icon: ActivityCategory.yoga.defaultIcon)
    WeekDetailSection(days: [
        DayActivities(date: mon, activities: [
            DayActivity(entry: pecho, weightKg: 20),
            DayActivity(entry: triceps, weightKg: nil)
        ]),
        DayActivities(date: cal.date(byAdding: .day, value: 2, to: mon)!, activities: [
            DayActivity(entry: yoga, weightKg: nil)
        ])
    ])
}
