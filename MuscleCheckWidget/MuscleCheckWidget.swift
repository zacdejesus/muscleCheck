import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private static let appGroup = "group.zadkiel.musclecheck"
    private static let entriesKey = "widgetEntries"
    
    func placeholder(in context: Context) -> WidgetMuscleListEntry {
        WidgetMuscleListEntry(date: Date(), entries: Self.placeholderEntries())
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
        return WidgetMuscleListEntry(date: Date(), entries: entries)
    }
    
    private static func placeholderEntries() -> [SharedMuscleEntry] {
        [
            SharedMuscleEntry(name: "Pecho", isChecked: false),
            SharedMuscleEntry(name: "Espalda", isChecked: true),
            SharedMuscleEntry(name: "Piernas", isChecked: false)
        ]
    }
}

struct MuscleCheckWidgetEntryView: View {
    var entry: WidgetMuscleListEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(entry.entries.prefix(6), id: \.name) { muscle in
                HStack {
                    Text(muscle.isChecked ? "✅" : "⬜️")
                        .font(.caption)
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
        .configurationDisplayName("Muscle Suggestion")
        .description("Shows the suggested muscle group for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
