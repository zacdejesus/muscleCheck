import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private static let appGroup = "group.zadkiel.musclecheck"
    private static let entriesKey = "widgetEntries"
    private static let currentStreakKey = "widgetCurrentStreak"
    private static let maxStreakKey = "widgetMaxStreak"
    
    func placeholder(in context: Context) -> WidgetMuscleListEntry {
        WidgetMuscleListEntry(date: Date(), entries: Self.placeholderEntries(), currentStreak: 3, maxStreak: 7)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetMuscleListEntry) -> ()) {
        let entry = fetchEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<WidgetMuscleListEntry>) -> ()) {
        let entry = fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchEntry() -> WidgetMuscleListEntry {
        let defaults = UserDefaults(suiteName: Self.appGroup)
        var entries: [SharedMuscleEntry] = []
      
        if let data = defaults?.data(forKey: Self.entriesKey),
           let decoded = try? JSONDecoder().decode([SharedMuscleEntry].self, from: data) {
                entries = decoded
        }
        let currentStreak = defaults?.integer(forKey: Self.currentStreakKey) ?? 0
        let maxStreak = defaults?.integer(forKey: Self.maxStreakKey) ?? 0
        return WidgetMuscleListEntry(date: Date(), entries: entries, currentStreak: currentStreak, maxStreak: maxStreak)
    }
    
    private static func placeholderEntries() -> [SharedMuscleEntry] {
        [
            SharedMuscleEntry(name: "Pecho", isChecked: false, icon: "figure.strengthtraining.traditional"),
            SharedMuscleEntry(name: "Espalda", isChecked: true, icon: "figure.strengthtraining.traditional"),
            SharedMuscleEntry(name: "Piernas", isChecked: false, icon: "figure.strengthtraining.traditional")
        ]
    }
}

struct MuscleCheckWidgetEntryView: View {
    var entry: WidgetMuscleListEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Streak row
            HStack(spacing: 4) {
                Image(systemName: entry.currentStreak > 0 ? "flame.fill" : "moon.zzz.fill")
                    .font(.caption)
                    .foregroundColor(entry.currentStreak > 0 ? .orange : .secondary)
                Text("widget_streak_days \(entry.currentStreak)")
                    .font(.caption.bold())
                    .foregroundColor(entry.currentStreak > 0 ? .orange : .secondary)
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "trophy.fill")
                    Text("\(entry.maxStreak)")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Divider()

            ForEach(entry.entries.prefix(5), id: \.name) { muscle in
                HStack(spacing: 4) {
                    Image(systemName: muscle.icon)
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .frame(width: 16)
                    Image(systemName: muscle.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(muscle.isChecked ? .green : .secondary)
                    Text(muscle.name)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

@main
struct MuscleCheckWidget: Widget {
    let kind: String = "MuscleCheckWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MuscleCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("widget_display_name"))
        .description(LocalizedStringResource("widget_description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
