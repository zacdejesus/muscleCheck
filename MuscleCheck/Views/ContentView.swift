//
//  ContentView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    
    @State private var entriesToDelete: IndexSet?
    
    @Environment(\.modelContext) private var context
    @Query private var entries: [MuscleEntry]
    @AppStorage("hasInsertedInitialData") private var hasInsertedInitialData: Bool = false
    @State private var showFullScreen = false
    
    @StateObject private var viewModel = ContentViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.currentWeekEntries, id: \.name) { entry in
                    HStack {
                        Text("\(viewModel.emoji(for: entry.name))  \(entry.name)")
                        Spacer()
                        Button {
                            entry.isChecked.toggle()
                        } label: {
                            Image(systemName: entry.isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(entry.isChecked ? .green : .gray)
                        }
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("home_title")
            .toolbar {
                NavigationLink("workout_history") {
                    HistoryView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                viewModel.setup(context: context, entries: entries)
                if !hasInsertedInitialData {
                    insertDefaultMuscleEntries(context: context)
                    hasInsertedInitialData = true
                }
                viewModel.createMissingEntriesIfNeeded()
            }
            .onChange(of: entries) { oldEntries, newEntries in
                viewModel.setup(context: context, entries: newEntries)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMuscleGroupView()
            }
        }
    }

    func insertDefaultMuscleEntries(context: ModelContext) {
        let now = Date()
        let week = Calendar.current.component(.weekOfYear, from: now)
        let year = Calendar.current.component(.yearForWeekOfYear, from: now)
        let defaultGroups = [
            NSLocalizedString("group_chest", comment: ""),
            NSLocalizedString("group_back", comment: ""),
            NSLocalizedString("group_legs", comment: ""),
            NSLocalizedString("group_shoulders", comment: ""),
            NSLocalizedString("group_biceps", comment: ""),
            NSLocalizedString("group_triceps", comment: ""),
            NSLocalizedString("group_abdomen", comment: "")
        ]

        for group in defaultGroups {
            let entry = MuscleEntry(name: group)
            entry.date = now
            entry.weekOfYear = week
            entry.year = year
            entry.isChecked = false
            context.insert(entry)
        }
        
        try? context.save()
    }
    
  func deleteEntries(at offsets: IndexSet) {
      for index in offsets {
          let entry = entries[index]
          context.delete(entry)
      }
      try? context.save()
  }

}
