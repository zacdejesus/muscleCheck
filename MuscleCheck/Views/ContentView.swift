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
  @Environment(\.modelContext) private var context
  @Query private var entries: [MuscleEntry]
  @AppStorage("hasInsertedInitialData") private var hasInsertedInitialData: Bool = false
  @State private var showingReviewModal = false
  @State private var showingAddSheet = false
  
  var body: some View {
    NavigationStack {
      Spacer()
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
      .background(Color(.systemGray6))
      .navigationTitle("home_title")
      .tint(Color("PrimaryButtonColor"))
      .navigationBarTitleDisplayMode(.automatic)
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
      .padding(0.5)
      .onAppear {
        Task {
          await viewModel.setup(context: context, entries: entries)
        }
      }
      .onChange(of: entries) { oldEntries, newEntries in
        viewModel.updateCurrentEntries()
      }
      .sheet(isPresented: $showingAddSheet) {
        AddMuscleGroupView()
      }
      .sheet(isPresented: $showingReviewModal) {
        if let reviewText = viewModel.workoutSuggested {
          VStack {
            Text("Review")
              .font(.headline)
            Text(reviewText)
              .padding()
            Button("Close") {
              showingReviewModal = false
            }
          }
          .padding()
        }
      }
      if viewModel.isAppleIntelligenceAvailable() {
        Button {
          Task {
            await viewModel.reviewLastMonthWorkouts()
            showingReviewModal = true
          }
        } label: {
          HStack {
            Image(systemName: "chart.bar.xaxis")
            Text("Musculo recomendado por Apple Intelligence")
              .fontWeight(.medium)
          }
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .tint(Color("PrimaryButtonColor"))
        .padding(.horizontal)
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
