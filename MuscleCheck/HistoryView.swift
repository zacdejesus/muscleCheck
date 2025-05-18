//
//  HistoryView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query var entries: [MuscleEntry]
    @State private var selectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()

    var body: some View {
        List {
            ForEach(filteredEntries, id: \.self) { entry in
                Text("\(entry.name) - \(entry.date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        .navigationTitle("History")
        .toolbar {
            DatePicker("Week", selection: $selectedWeekStart, displayedComponents: .date)
                .datePickerStyle(.compact)
        }
    }

    var filteredEntries: [MuscleEntry] {
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: selectedWeekStart)!
        return entries.filter {
            $0.date >= Calendar.current.startOfDay(for: selectedWeekStart) &&
            $0.date <= endOfWeek
        }
    }
}
