import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query var entries: [MuscleEntry]
    @State private var selectedDate = Date()
    @State private var showPicker = false

    var body: some View {
        List {
            ForEach(groupedEntries.keys.sorted(), id: \.self) { muscleName in
                Section(header: Text(muscleName).font(.headline)) {
                    ForEach(groupedEntries[muscleName] ?? [], id: \.self) { entry in
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    showPicker = true
                } label: {
                    Text("Semana \(weekOf(selectedDate)): \(weekRangeString(for: selectedDate))")
                        .font(.headline.bold())
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            VStack {
                DatePicker("Selecciona una semana", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Button("Done") {
                    showPicker = false
                }
                .padding()
            }
        }
    }

    var groupedEntries: [String: [MuscleEntry]] {
        let calendar = Calendar.current
        let selectedWeek = calendar.component(.weekOfYear, from: selectedDate)
        let selectedYear = calendar.component(.yearForWeekOfYear, from: selectedDate)

        let filtered = entries.filter {
            $0.weekOfYear == selectedWeek && $0.year == selectedYear && $0.isChecked
        }

        return Dictionary(grouping: filtered, by: { $0.name })
    }

    func weekOf(_ date: Date) -> Int {
        Calendar.current.component(.weekOfYear, from: date)
    }

    func weekRangeString(for date: Date) -> String {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return "" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d 'de' MMMM"

        let start = formatter.string(from: weekInterval.start)
        let end = formatter.string(from: calendar.date(byAdding: .day, value: 6, to: weekInterval.start)!)

        return "del \(start) al \(end)"
    }
}
