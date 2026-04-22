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
  @StateObject private var streakViewModel = StreakViewModel()
  @EnvironmentObject var storeManager: StoreManager
  @EnvironmentObject var settingsViewModel: SettingsViewModel
  @Environment(\.modelContext) private var context
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage("hasInsertedInitialData") private var hasInsertedInitialData: Bool = false
  
  @State private var showingReviewModal = false
  @State private var showingAddSheet = false
  @State private var showingPaywall = false
  @State private var showingSettings = false
  @State private var showingStats = false
  
  @Query private var entries: [MuscleEntry]
  
  var body: some View {
    NavigationStack {
      StreakCardView(viewModel: streakViewModel)
      List {
        if viewModel.currentWeekEntries.isEmpty {
          EmptyStateView()
        } else {
          ForEach(viewModel.currentWeekEntries, id: \.name) { entry in
            MuscleEntryRowView(
              entry: entry,
              onTap: { _ in viewModel.toggleActivity(for: entry) }
            )
          }
          .onDelete(perform: viewModel.deleteEntries)
          .id(viewModel.currentWeekEntries.count)
        }
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
          HStack(spacing: 4) {
            Button {
              showingStats = true
            } label: {
              Image(systemName: "chart.bar.xaxis")
                .font(.headline)
                .foregroundColor(Color("PrimaryButtonColor"))
            }
            .accessibilityLabel("stats_title")
            Button {
              showingSettings = true
            } label: {
              Image(systemName: "gearshape")
                .font(.headline)
                .foregroundColor(Color("PrimaryButtonColor"))
            }
            Button {
              showingAddSheet = true
            } label: {
              Image(systemName: "plus.circle")
                .font(.headline)
                .padding(.horizontal, 4)
                .foregroundColor(Color("PrimaryButtonColor"))
            }
            .accessibilityLabel("add_new_muscle_group")
          }
        }
      }
      .padding(0.5)
      .onAppear {
        Task {
          await viewModel.setup(context: context, entries: entries)
          streakViewModel.update(with: entries)
          await NotificationManager.shared.checkAuthorizationStatus()
        }
      }
      .onChange(of: scenePhase) { _, newPhase in
        if newPhase == .background && UserDefaultsManager.shared.notificationsEnabled {
          Task {
            await NotificationManager.shared.scheduleInactivityReminders(for: entries)
          }
        }
      }
      .onChange(of: entries) { oldEntries, newEntries in
        viewModel.updateCurrentEntries()
        streakViewModel.update(with: newEntries)
      }
      .sheet(isPresented: $showingAddSheet) {
        AddMuscleGroupView()
      }
      .sheet(isPresented: $showingSettings) {
        NavigationStack {
          SettingsView()
            .environmentObject(storeManager)
            .environmentObject(settingsViewModel)
        }
      }
      .sheet(isPresented: $showingStats) {
        NavigationStack {
          StatsView()
        }
      }
      .sheet(isPresented: $showingReviewModal) {
        if let reviewText = viewModel.workoutSuggested {
          VStack {
            Text("Review")
              .font(.headline)
            Text(reviewText)
              .padding()
            Button("BUTTON_CLOSE") {
              showingReviewModal = false
            }
          }
          .padding()
        }
      }
      if viewModel.isAppleIntelligenceAvailable() {
        if storeManager.isPro {
          Button {
            Task {
              await viewModel.reviewLastMonthWorkouts()
              showingReviewModal = true
            }
          } label: {
            HStack {
              Image(systemName: "chart.bar.xaxis")
              Text("muscle_recommend_by_ai")
                .fontWeight(.medium)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.regular)
          .tint(Color("PrimaryButtonColor"))
          .padding(.horizontal)
          .padding(.bottom, 15)
        } else {
          ProFeatureGate(lockedMessage: NSLocalizedString("muscle_recommend_by_ai", comment: "")) {
            EmptyView()
          }
          .padding(.horizontal)
          .padding(.bottom, 15)
        }
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
  
  ContentView()
    .modelContainer(container)
    .environmentObject(StoreManager.shared)
    .environmentObject(SettingsViewModel())
}

extension ModelContext: ModelContextProtocol {
  
}
