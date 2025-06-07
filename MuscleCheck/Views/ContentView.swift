//
//  ContentView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    
    @StateObject private var viewModel = ContentViewModel()
    @State private var showingAddSheet = false
  
    @Environment(\.modelContext) private var context
    @Query private var entries: [MuscleEntry]
    @AppStorage("hasInsertedInitialData") private var hasInsertedInitialData: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
              ForEach(viewModel.currentWeekEntries, id: \.name) { entry in
                  MuscleEntryRowView(
                      entry: entry,
                      emoji: viewModel.emoji(for: entry.name),
                      onTap: { handleTapItemActivity?($0) }
                  )
              }
              .onDelete(perform: viewModel.deleteEntries)
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
                    viewModel.insertDefaultMuscleEntries(context: context)
                    hasInsertedInitialData = true
                }
                viewModel.createMissingEntriesIfNeeded()
            }
            .onChange(of: entries) { oldEntries, newEntries in
              viewModel.updateCurrentEntries()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMuscleGroupView()
            }
        }
    }
  
  var handleTapItemActivity: ((MuscleEntry) -> Void)? = { entry in
    let today = Date()
    entry.isChecked ? entry.addActivityDate(today) : entry.removeActivityDate(today)
    
    entry.isChecked.toggle()
  }
}
