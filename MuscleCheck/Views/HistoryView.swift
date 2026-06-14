import SwiftUI
import SwiftData

struct HistoryView: View {
  let entries: [MuscleEntry]
  @StateObject private var viewModel: HistoryViewModel

  init(entries: [MuscleEntry]) {
    self.entries = entries
    _viewModel = StateObject(wrappedValue: HistoryViewModel.create(with: entries))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        // Month summary caption (per-month trained-day count — not shown in Stats/Streak)
        Text("history_month_summary \(viewModel.monthTrainedCount) \(viewModel.monthName)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal)

        // Hero calendar
        MonthCalendarView(
          weeks: viewModel.weeks,
          selectedWeek: viewModel.selectedWeek,
          monthTitle: viewModel.monthTitle,
          intensityByDay: viewModel.intensityByDay,
          selectedDate: viewModel.selectedDate,
          isExpanded: viewModel.isCalendarExpanded,
          // Chevrons step by month when expanded, by week when collapsed.
          onPrev: { withAnimation { viewModel.isCalendarExpanded ? viewModel.goToPreviousMonth() : viewModel.goToPreviousWeek() } },
          onNext: { withAnimation { viewModel.isCalendarExpanded ? viewModel.goToNextMonth() : viewModel.goToNextWeek() } },
          onToggleExpand: { withAnimation { viewModel.toggleCalendarExpanded() } },
          onSelect: { day in withAnimation { viewModel.select(day) } }
        )
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)

        // Selected week, day by day
        WeekDetailSection(days: viewModel.weekBreakdown)
      }
      .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("workout_history")
    .navigationBarTitleDisplayMode(.large)
    .onChange(of: entries) { _, newEntries in
      viewModel.entries = newEntries
    }
  }
}
