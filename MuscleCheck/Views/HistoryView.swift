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
  @State private var showPicker = false
  
  var body: some View {
    List {
      ForEach(filteredEntries, id: \.self) { entry in
        Text("\(entry.name) - \(entry.date.formatted(date: .abbreviated, time: .omitted))")
      }
    }
    .navigationTitle("workout_history")
    .toolbar {
      ToolbarItem(placement: .principal) {
        Button {
          showPicker = true
        } label: {
          Text("week \(weekOf(selectedDate)), \(yearOf(selectedDate))")
            .font(.headline)
            .foregroundColor(.blue)
        }
        .sheet(isPresented: $showPicker) {
          VStack {
            DatePicker("select_week", selection: $selectedDate, displayedComponents: .date)
              .datePickerStyle(.graphical)
              .padding()
            Button("Done") {
              showPicker = false
            }
            .padding()
          }
        }
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
  
  func weekOf(_ date: Date) -> Int {
    Calendar.current.component(.weekOfYear, from: date)
  }
  
  func yearOf(_ date: Date) -> String {
      let year = Calendar.current.component(.yearForWeekOfYear, from: date)
      return String(year)
  }
}
