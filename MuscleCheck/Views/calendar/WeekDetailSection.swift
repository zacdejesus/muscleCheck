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
                            .foregroundStyle(Color("PrimaryButtonColor"))
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

/// Read-only mirror of `MuscleEntryRowView`'s visual: icon + name + that day's weight (gym only).
/// Deliberately omits the checkmark/weight-edit affordances — history doesn't mutate state.
private struct ActivityDetailRow: View {
    let activity: DayActivity

    private var isGym: Bool { activity.entry.category == ActivityCategory.gym.rawValue }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.entry.icon)
                .foregroundColor(Color("PrimaryButtonColor"))
                .frame(width: 24)
            Text(activity.entry.name)
            if isGym, let kg = activity.weightKg {
                Text(formattedWeight(kg))
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func formattedWeight(_ kg: Double) -> String {
        let unit = UserDefaultsManager.shared.weightUnit
        return String(format: "%.0f", unit.displayValue(fromKg: kg)) + " " + unit.displayLabel
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
