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
    /// The single week rendered when collapsed.
    let selectedWeek: [CalendarDay]
    let monthTitle: String
    let intensityByDay: [Date: Int]
    let selectedDate: Date
    let isExpanded: Bool
    /// Context-aware paging: the parent wires these to week- or month-stepping based on `isExpanded`.
    let onPrev: () -> Void
    let onNext: () -> Void
    let onToggleExpand: () -> Void
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

    // MARK: - Header (month/week pager + expand toggle)

    private var header: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left").font(.appHeadline)
            }
            Spacer()
            Button(action: onToggleExpand) {
                HStack(spacing: 4) {
                    Text(monthTitle)
                        .font(.appHeadline)
                        .contentTransition(.numericText())
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.appCaption.weight(.bold))
                }
            }
            .accessibilityLabel(monthTitle)
            .accessibilityHint(isExpanded ? "history_calendar_collapse_hint" : "history_calendar_expand_hint")
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right").font(.appHeadline)
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
                    .font(.appCaption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        VStack(spacing: 4) {
            if isExpanded {
                // Full month: highlight the selected week so it stands out in context.
                ForEach(weeks.indices, id: \.self) { row in
                    weekRow(weeks[row], highlighted: isSelectedWeek(weeks[row]))
                }
            } else {
                // Collapsed: only the selected week — it's the sole row, so no highlight needed.
                weekRow(selectedWeek, highlighted: false)
            }
        }
    }

    private func weekRow(_ week: [CalendarDay], highlighted: Bool) -> some View {
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
        // Pin the highlight to the number band (top) instead of the full cell, so it
        // doesn't sag into the reserved intensity-dot slot below each number.
        .background(alignment: .top) { weekBackground(highlighted: highlighted) }
    }

    @ViewBuilder
    private func weekBackground(highlighted: Bool) -> some View {
        if highlighted {
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )
                .frame(height: 38)
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

#Preview("Collapsed") {
    let today = Date()
    MonthCalendarView(
        weeks: MonthCalendarCalculator.monthMatrix(for: today),
        selectedWeek: MonthCalendarCalculator.weekRow(forWeekContaining: today),
        monthTitle: "junio 2026",
        intensityByDay: [Date.appCalendar.startOfDay(for: today): 2],
        selectedDate: today,
        isExpanded: false,
        onPrev: {},
        onNext: {},
        onToggleExpand: {},
        onSelect: { _ in }
    )
    .padding()
}

#Preview("Expanded") {
    let today = Date()
    MonthCalendarView(
        weeks: MonthCalendarCalculator.monthMatrix(for: today),
        selectedWeek: MonthCalendarCalculator.weekRow(forWeekContaining: today),
        monthTitle: "junio 2026",
        intensityByDay: [Date.appCalendar.startOfDay(for: today): 2],
        selectedDate: today,
        isExpanded: true,
        onPrev: {},
        onNext: {},
        onToggleExpand: {},
        onSelect: { _ in }
    )
    .padding()
}
