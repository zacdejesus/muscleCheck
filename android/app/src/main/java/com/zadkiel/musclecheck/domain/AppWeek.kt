package com.zadkiel.musclecheck.domain

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.WeekFields

/**
 * Week math shared across the app. Mirrors iOS `Date.appCalendar`: gregorian,
 * Monday-first, minimumDaysInFirstWeek = 1 — so week numbers and streaks line up
 * with data produced by the iOS app.
 */
object AppWeek {
    val fields: WeekFields = WeekFields.of(DayOfWeek.MONDAY, 1)

    fun startOfWeek(date: LocalDate): LocalDate =
        date.with(fields.dayOfWeek(), 1)

    fun weekOfYear(date: LocalDate): Int =
        date.get(fields.weekOfWeekBasedYear())

    fun weekBasedYear(date: LocalDate): Int =
        date.get(fields.weekBasedYear())
}
