//
//  ContentView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [MuscleEntry]
    
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
            }
            .navigationTitle("Muscle check")
            .toolbar {
                NavigationLink("Historial") {
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
                viewModel.createMissingEntriesIfNeeded()
            }
            .onChange(of: entries) {  oldEntries, newEntries in
                viewModel.setup(context: context, entries: newEntries)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddMuscleGroupView()
            }
        }
    }
}
