//
//  CalendarDayCell.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 13/06/2026.
//

import SwiftUI

/// A single day in the month grid. Purely presentational — the parent owns selection.
struct CalendarDayCell: View {
    let day: CalendarDay
    let isToday: Bool
    let isSelected: Bool
    /// Number of muscles trained that day (0 = none); drives the intensity dot.
    let intensity: Int

    private let accent = Color("PrimaryButtonColor")

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    Circle().fill(accent)
                } else if isToday {
                    Circle().stroke(accent, lineWidth: 1.5)
                }
                Text("\(dayNumber)")
                    .font(.appCallout)
                    .fontWeight(isSelected || isToday ? .semibold : .regular)
                    .foregroundStyle(numberColor)
            }
            .frame(width: 32, height: 32)

            // Intensity dot: bigger/more opaque the more muscles trained.
            // Hidden on the selected day (the fill already conveys training).
            // Fixed 8pt slot keeps every row vertically aligned.
            Circle()
                .fill(accent.opacity(dotOpacity))
                .frame(width: dotSize, height: dotSize)
                .frame(height: 8)
                .opacity(showDot ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .contentShape(Rectangle())
    }

    private var dayNumber: Int {
        Date.appCalendar.component(.day, from: day.date)
    }

    private var numberColor: Color {
        if isSelected { return .white }
        if isToday { return accent }
        return day.isInDisplayedMonth ? .primary : .secondary.opacity(0.5)
    }

    // MARK: - Intensity dot scaling

    private var showDot: Bool { intensity > 0 && !isSelected }
    private var clamped: Int { min(max(intensity, 0), 4) }
    private var dotSize: CGFloat { 4 + CGFloat(clamped) }            // 5…8 pt
    private var dotOpacity: Double { 0.35 + 0.65 * Double(clamped) / 4.0 } // ~0.5…1.0
}

#Preview {
    let cal = Date.appCalendar
    let today = cal.startOfDay(for: Date())
    HStack(spacing: 0) {
        CalendarDayCell(day: CalendarDay(date: cal.date(byAdding: .day, value: -1, to: today)!, isInDisplayedMonth: true),
                        isToday: false, isSelected: false, intensity: 1)
        CalendarDayCell(day: CalendarDay(date: today, isInDisplayedMonth: true),
                        isToday: true, isSelected: false, intensity: 2)
        CalendarDayCell(day: CalendarDay(date: cal.date(byAdding: .day, value: 1, to: today)!, isInDisplayedMonth: true),
                        isToday: false, isSelected: true, intensity: 3)
        CalendarDayCell(day: CalendarDay(date: cal.date(byAdding: .day, value: 2, to: today)!, isInDisplayedMonth: true),
                        isToday: false, isSelected: false, intensity: 4)
        CalendarDayCell(day: CalendarDay(date: cal.date(byAdding: .day, value: 3, to: today)!, isInDisplayedMonth: false),
                        isToday: false, isSelected: false, intensity: 0)
    }
    .padding()
}
