//
//  ContentView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//
import SwiftUI
import SwiftData
import HealthKit

struct ContentView: View {
  
  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var streakViewModel = StreakViewModel()
  @ObservedObject private var healthKitManager = HealthKitManager.shared
  @EnvironmentObject var storeManager: StoreManager
  @EnvironmentObject var settingsViewModel: SettingsViewModel
  @Environment(\.modelContext) private var context
  @Environment(\.scenePhase) private var scenePhase
  @AppStorage("hasInsertedInitialData") private var hasInsertedInitialData: Bool = false
  
  @State private var showingRoutineModal = false
  @State private var showingAddSheet = false
  @State private var showingPaywall = false
  @State private var showingSettings = false
  @State private var showingStats = false
  @State private var showingProgressPhotos = false
  @State private var workoutToLog: IdentifiableWorkout?

  @Query private var entries: [MuscleEntry]
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        StreakCardView(viewModel: streakViewModel)
          Spacer()
        if !healthKitManager.unloggedWorkouts.isEmpty && storeManager.isPro {
          HealthKitSuggestionsView(healthKitManager: healthKitManager) { workout in
            selectWorkoutToLog(workout)
          }
          .padding(.top, 4)
        }

        List {
          if viewModel.currentWeekEntries.isEmpty {
            EmptyStateView()
          } else if viewModel.groupedCurrentWeekEntries.count == 1 {
            // Single category — no section headers for clean look
            let group = viewModel.groupedCurrentWeekEntries[0]
            ForEach(group.entries) { entry in
              MuscleEntryRowView(
                entry: entry,
                onTap: { _ in viewModel.toggleActivity(for: entry) },
                onSaveWeight: { target, weight in viewModel.saveWeight(weight, for: target) }
              )
            }
            .onDelete { offsets in
              viewModel.deleteEntries(from: group.entries, at: offsets)
            }
          } else {
            // Multiple categories — show section headers
            ForEach(viewModel.groupedCurrentWeekEntries, id: \.category) { group in
              Section {
                ForEach(group.entries) { entry in
                  MuscleEntryRowView(
                    entry: entry,
                    onTap: { _ in viewModel.toggleActivity(for: entry) },
                    onSaveWeight: { target, weight in viewModel.saveWeight(weight, for: target) }
                  )
                }
                .onDelete { offsets in
                  viewModel.deleteEntries(from: group.entries, at: offsets)
                }
              } header: {
                categoryHeader(group.category)
              }
            }
          }
        }
        .background(Color(.systemGray6))
        // AI Coach: suggested day. Free + on-device, so no Pro gate — only hidden when
        // Apple Intelligence isn't available (iOS < 26, ineligible hardware, AI off).
        // Pinned as a bottom bar so the list scrolls underneath and the bottom edge
        // stays clean (no stray band over the system background).
        .safeAreaInset(edge: .bottom) {
          if viewModel.isAppleIntelligenceAvailable() {
            Button {
              showingRoutineModal = true
              if viewModel.routineSuggestion == nil {
                Task { await viewModel.generateRoutine() }
              }
            } label: {
              HStack {
                Image(systemName: "sparkles")
                Text("ai_coach_suggest_day")
                  .fontWeight(.medium)
              }
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(Color("PrimaryButtonColor"))
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
          }
        }
      }
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
              showingProgressPhotos = true
            } label: {
              Image(systemName: "camera")
                .font(.headline)
                .foregroundColor(Color("PrimaryButtonColor"))
            }
            .accessibilityLabel("progress_photos_title")
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
      .onAppear {
        Task {
          await viewModel.setup(context: context, entries: entries)
          streakViewModel.update(with: entries)
          await NotificationManager.shared.checkAuthorizationStatus()
          if UserDefaultsManager.shared.healthKitEnabled {
            await healthKitManager.fetchUnloggedWorkouts(existingEntries: entries)
          }
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
      .sheet(isPresented: $showingProgressPhotos) {
        NavigationStack {
          ProgressPhotosView()
            .environmentObject(storeManager)
        }
      }
      .sheet(isPresented: $showingRoutineModal) {
        RoutineSuggestionView(viewModel: viewModel)
      }
      .sheet(item: $workoutToLog) { item in
        HealthKitLogSheet(
          workout: item.workout,
          candidates: candidates(for: item.workout)
        ) { selected in
          viewModel.logHealthKitWorkout(item.workout, to: selected)
          healthKitManager.dismissWorkout(item.workout)
        }
      }
    }
  }

  /// Entries in the same category as the workout — the picker's options.
  private func candidates(for workout: HKWorkout) -> [MuscleEntry] {
    let category = HealthKitManager.mapToCategory(workout.workoutActivityType).rawValue
    return entries.filter { $0.category == category }
  }

  private func selectWorkoutToLog(_ workout: HKWorkout) {
    // No entry in this category yet → skip the picker; the VM creates a generic one.
    if candidates(for: workout).isEmpty {
      viewModel.logHealthKitWorkout(workout, to: [])
      healthKitManager.dismissWorkout(workout)
    } else {
      workoutToLog = IdentifiableWorkout(workout: workout)
    }
  }

  @ViewBuilder
  private func categoryHeader(_ categoryRaw: String) -> some View {
    if let category = ActivityCategory(rawValue: categoryRaw) {
      HStack(spacing: 6) {
        Image(systemName: category.defaultIcon)
        Text(category.displayName)
      }
      .font(.subheadline.bold())
      .foregroundColor(Color("PrimaryButtonColor"))
    } else {
      Text(categoryRaw)
    }
  }
}

/// Wraps an HKWorkout so it can drive `.sheet(item:)` (HKWorkout isn't Identifiable).
struct IdentifiableWorkout: Identifiable {
  let workout: HKWorkout
  var id: UUID { workout.uuid }
}

extension MuscleEntry {
  static func sample(name: String = "Pecho") -> MuscleEntry {
    let entry = MuscleEntry(name: name)
    entry.isChecked = true
    entry.addSession(Date())
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
