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
            onTap: { _ in viewModel.toggleActivity(for: entry) }
          )
        }
        .onDelete(perform: viewModel.deleteEntries)
      }
      .navigationTitle("home_title")
      .tint(Color("PrimaryButtonColor"))
      
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          NavigationLink("workout_history") {
            HistoryView(entries: entries)
          }
          .foregroundColor(Color("PrimaryButtonColor"))
          .font(.headline.bold())
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showingAddSheet = true
          } label: {
            Image(systemName: "plus.circle")
                              .font(.headline)
                              .padding(.horizontal, 12)
                              .padding(.vertical, 8)
                              .foregroundColor(Color("PrimaryButtonColor"))
                              .cornerRadius(8)
          }
          .accessibilityLabel("add_new_muscle_group")
        }
      }
      .onAppear {
          if let context = context as? ModelContextProtocol {
              viewModel.setup(context: context, entries: entries)
          } else {
              assertionFailure("ModelContext does not conform to ModelContextProtocol")
          }
      }
      .onChange(of: entries) { oldEntries, newEntries in
        viewModel.updateCurrentEntries()
      }
      .sheet(isPresented: $showingAddSheet) {
        AddMuscleGroupView()
      }
    }
  }
}

extension MuscleEntry {
  static func sample(name: String = "Pecho") -> MuscleEntry {
    let entry = MuscleEntry(name: name)
    entry.isChecked = true
    entry.addActivityDate(Date())
    return entry
  }
}


#Preview {
  let container = try! ModelContainer(for: MuscleEntry.self, configurations: ModelConfiguration())
  let context = container.mainContext
  
  ContentView().modelContainer(container)
}

extension ModelContext: ModelContextProtocol {

}
