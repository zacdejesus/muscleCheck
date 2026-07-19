//
//  ContentView.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 17/05/2025.
//
import SwiftUI
import SwiftData
import HealthKit
import TipKit

struct ContentView: View {
  
  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var streakViewModel = StreakViewModel()
  @ObservedObject private var healthKitManager = HealthKitManager.shared
  @EnvironmentObject var storeManager: StoreManager
  @EnvironmentObject var settingsViewModel: SettingsViewModel
  @Environment(\.modelContext) private var context
  @Environment(\.scenePhase) private var scenePhase
  // Same key UserDefaultsManager owns; @AppStorage so the cover dismisses reactively
  // when OnboardingViewModel flips the flag.
  @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

  @State private var showingRoutineModal = false
  @State private var showingAddSheet = false
  @State private var showingSettings = false
  @State private var showingStats = false
  @State private var showingProgressPhotos = false
  @State private var workoutToLog: IdentifiableWorkout?

  @Query private var entries: [MuscleEntry]
  @Query private var customCategories: [CustomCategory]

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Fixed gap below the streak card so it never sticks to the activity list.
        // A flexible Spacer() collapsed to 0 when the list filled the screen (card
        // stuck to the table) and ballooned when the list was short — inconsistent.
        // A constant padding keeps the same separation in every configuration.
        StreakCardView(viewModel: streakViewModel)
          .padding(.bottom, 16)
        if !healthKitManager.unloggedWorkouts.isEmpty && storeManager.isPro {
          HealthKitSuggestionsView(healthKitManager: healthKitManager) { workout in
            selectWorkoutToLog(workout)
          }
          .padding(.top, 4)
        }

        // First time a weekly reset clears the checks, explain the mental model
        // ("fresh list every Monday") right where the checks just disappeared.
        TipView(WeeklyResetTip())
          .padding(.horizontal)

        List {
          if viewModel.currentWeekEntries.isEmpty {
            EmptyStateView()
          } else if viewModel.groupedCurrentWeekEntries.count == 1 {
            // Single category — no section headers for clean look
            let group = viewModel.groupedCurrentWeekEntries[0]
            ForEach(group.entries) { entry in
              entryRow(entry)
            }
            .onDelete { offsets in
              viewModel.deleteEntries(from: group.entries, at: offsets)
            }
          } else {
            // Multiple categories — show section headers
            ForEach(viewModel.groupedCurrentWeekEntries, id: \.category) { group in
              Section {
                ForEach(group.entries) { entry in
                  entryRow(entry)
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
        // Kill the rubber-band bounce on the activity list entirely (even when it's long
        // enough to scroll). SwiftUI's scrollBounceBehavior has no ".never" — its options
        // still bounce once the content overflows — so we reach the backing UIScrollView
        // and set bounces = false. Scoped to this list via a background probe.
        .background(NoScrollBounce())
        // AI Coach: suggested day. Free + on-device, so no Pro gate — only hidden when
        // Apple Intelligence isn't available (iOS < 26, ineligible hardware, AI off).
        // Pinned to the bottom with a transparent background so the list shows through
        // (no bar-material band behind the button).
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
            .tint(Color.brand)
            .padding(.horizontal)
            .padding(.vertical, 8)
          }
        }
      }
      .navigationTitle("home_title")
      .tint(Color.brand)
      .navigationBarTitleDisplayMode(.automatic)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          // Short label ("Historial"/"History") + smaller font: frees horizontal space so
          // the trailing icons fit before iOS has to collapse any into the overflow.
          NavigationLink("navigation_history_button") {
            HistoryView(entries: entries)
          }
          .foregroundColor(Color.brand)
          .font(.appSubheadline)
        }
        
        // One toolbar item per action (instead of an HStack crammed into a single
        // ToolbarItem): lets iOS lay them out individually and, when horizontal space is
        // tight (Display Zoom / large Dynamic Type / long leading title), collapse them
        // into a WORKING overflow "···" menu. Each Button uses a Label so the overflow
        // shows a readable, tappable row — icon-only buttons collapse into a dead menu.
        // Color comes from the NavigationStack's .tint.
        // Order matters: iOS collapses the LAST-declared items into the overflow "···"
        // first. Declaring Add + Settings first keeps them visible the longest; Stats and
        // Photos are the ones that fall into the overflow when space runs out.
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button {
            showingAddSheet = true
          } label: {
            Label("add_new_muscle_group", systemImage: "plus.circle")
          }
          Button {
            showingSettings = true
          } label: {
            Label("settings_title", systemImage: "gearshape")
          }
          Button {
            showingStats = true
          } label: {
            Label("stats_title", systemImage: "chart.bar.xaxis")
          }
          Button {
            showingProgressPhotos = true
          } label: {
            Label("progress_photos_title", systemImage: "camera")
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
        AddExerciseView()
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
      // First run only: the initial seed is decided inside (category picker).
      // Dismisses itself when OnboardingViewModel flips hasCompletedOnboarding.
      .fullScreenCover(isPresented: Binding(
        get: { !hasCompletedOnboarding },
        set: { hasCompletedOnboarding = !$0 }
      )) {
        OnboardingView()
      }
    }
  }

  /// Shared row construction for both list layouts. The tip flags mark exactly one
  /// row app-wide as the anchor for each onboarding tip.
  private func entryRow(_ entry: MuscleEntry) -> some View {
    MuscleEntryRowView(
      entry: entry,
      showsCheckTip: entry.persistentModelID == checkTipEntryID,
      showsWeightTip: entry.persistentModelID == weightTipEntryID,
      onTap: { _ in viewModel.toggleActivity(for: entry) },
      onSaveSession: { target, input in viewModel.saveSession(input, for: target) }
    )
  }

  /// First visible row — anchor for the "tap the circle when you train" tip.
  private var checkTipEntryID: PersistentIdentifier? {
    viewModel.groupedCurrentWeekEntries.first?.entries.first?.persistentModelID
  }

  /// First strength-metric row — anchor for the "tap the name to log weight" tip.
  private var weightTipEntryID: PersistentIdentifier? {
    viewModel.groupedCurrentWeekEntries
      .compactMap { $0.entries.first { $0.metric == .strength } }
      .first?.persistentModelID
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

  private func categoryHeader(_ categoryRaw: String) -> some View {
    // Resolve through CategoryResolver so custom categories show their name + icon —
    // a raw category string here is a custom category's UUID, never a display label.
    let resolved = CategoryResolver.resolve(categoryRaw, custom: customCategories)
    return HStack(spacing: 6) {
      Image(systemName: resolved.icon)
      Text(resolved.displayName)
    }
    .font(.appSubheadline.bold())
    .foregroundColor(Color.brand)
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

/// Disables the rubber-band bounce on the scroll view that backs the attached `List`/
/// `ScrollView`, without disabling scrolling. SwiftUI exposes no native "never bounce"
/// option, so we drop an invisible probe into the hierarchy and locate the UIScrollView.
///
/// We try the responder chain first (tightest scope). SwiftUI sometimes hosts a List's
/// `.background` as a *sibling* of the backing UICollectionView, so the chain misses it —
/// in that case we climb to the nearest ancestor and search its descendants.
private struct NoScrollBounce: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let probe = UIView()
    probe.isUserInteractionEnabled = false
    DispatchQueue.main.async { [weak probe] in
      guard let probe, let scrollView = probe.enclosingScrollView() else { return }
      scrollView.bounces = false
    }
    return probe
  }

  func updateUIView(_ uiView: UIView, context: Context) {}
}

private extension UIView {
  /// Finds the scroll view backing this view's list: first up the responder chain, then,
  /// failing that, by climbing a couple of ancestors and searching their subtrees.
  func enclosingScrollView() -> UIScrollView? {
    var responder: UIResponder? = self
    while let current = responder {
      if let scrollView = current as? UIScrollView { return scrollView }
      responder = current.next
    }
    var ancestor: UIView? = superview
    for _ in 0..<4 {
      if let found = ancestor?.firstScrollViewInSubtree() { return found }
      ancestor = ancestor?.superview
    }
    return nil
  }

  func firstScrollViewInSubtree() -> UIScrollView? {
    if let scrollView = self as? UIScrollView { return scrollView }
    for subview in subviews {
      if let found = subview.firstScrollViewInSubtree() { return found }
    }
    return nil
  }
}
