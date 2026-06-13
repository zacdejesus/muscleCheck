//
//  MonthCalendarView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 13/06/2026.
//

import SwiftUI

/// Month calendar hero for the history screen. Renders each week as its own `HStack`
/// so the selected week can carry a single contiguous rounded background + border
/// (the macOS Calendar look) — impossible to align cleanly with a flat `LazyVGrid`.
struct MonthCalendarView: View {
    let weeks: [[CalendarDay]]
    let monthTitle: String
    let intensityByDay: [Date: Int]
    let selectedDate: Date
    let onPrev: () -> Void
    let onNext: () -> Void
    let onSelect: (Date) -> Void

    private let accent = Color("PrimaryButtonColor")
    private let calendar = Date.appCalendar

    var body: some View {
        VStack(spacing: 12) {
            header
            weekdayHeader
            grid
        }
    }

    // MARK: - Header (month pager)

    private var header: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left").font(.headline)
            }
            Spacer()
            Text(monthTitle)
                .font(.headline)
                .contentTransition(.numericText())
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right").font(.headline)
            }
        }
        .tint(accent)
    }

    // MARK: - Weekday symbols

    private var weekdayHeader: some View {
        let symbols = MonthCalendarCalculator.weekdaySymbols()
        return HStack(spacing: 0) {
            ForEach(symbols.indices, id: \.self) { i in
                Text(symbols[i])
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        VStack(spacing: 4) {
            ForEach(weeks.indices, id: \.self) { row in
                let week = weeks[row]
                HStack(spacing: 0) {
                    ForEach(week) { day in
                        CalendarDayCell(
                            day: day,
                            isToday: calendar.isDateInToday(day.date),
                            isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                            intensity: intensityByDay[day.date] ?? 0
                        )
                        .onTapGesture { onSelect(day.date) }
                    }
                }
                .padding(.vertical, 2)
                .background(weekBackground(for: week))
            }
        }
    }

    @ViewBuilder
    private func weekBackground(for week: [CalendarDay]) -> some View {
        if isSelectedWeek(week) {
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )
        }
    }

    /// A row is the selected week iff its Monday matches the selected date's Monday.
    /// The matrix is Monday-first, so the selected week is always exactly one row.
    private func isSelectedWeek(_ week: [CalendarDay]) -> Bool {
        guard let rowMonday = week.first?.date,
              let selectedMonday = selectedDate.startOfWeek(using: calendar) else { return false }
        return calendar.isDate(rowMonday, inSameDayAs: selectedMonday)
    }
}

#Preview {
    let today = Date()
    MonthCalendarView(
        weeks: MonthCalendarCalculator.monthMatrix(for: today),
        monthTitle: "junio 2026",
        intensityByDay: [Date.appCalendar.startOfDay(for: today): 2],
        selectedDate: today,
        onPrev: {},
        onNext: {},
        onSelect: { _ in }
    )
    .padding()
}
