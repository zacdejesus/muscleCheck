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
    @State private var selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 0, to: Date()) ?? Date()

    var body: some View {
        List {
            ForEach(filteredEntries, id: \.self) { entry in
                Text("\(entry.name) - \(entry.date.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        .navigationTitle("Historial")
        .toolbar {
            ToolbarItem(placement: .principal) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
            }
        }
    }

    var filteredEntries: [MuscleEntry] {
        let calendar = Calendar.current
        let selectedWeek = calendar.component(.weekOfYear, from: selectedDate)
        let selectedYear = calendar.component(.yearForWeekOfYear, from: selectedDate)

        return entries.filter {
            $0.weekOfYear == selectedWeek && $0.year == selectedYear && $0.isChecked
        }
    }
}
