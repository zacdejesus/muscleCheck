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

    let muscleGroups = ["Pecho", "Espalda", "Piernas", "Hombros", "Bíceps", "Tríceps", "Abdomen"]

    var body: some View {
        NavigationStack {
            List {
                ForEach(currentWeekEntries(), id: \.name) { entry in
                    HStack {
                        Text("\(emoji(for: entry.name)) \(entry.name)")
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
            .navigationTitle("Semana Fit")
            .toolbar {
                NavigationLink("Historial") {
                    HistoryView()
                }
            }
            .onAppear {
                createMissingEntriesIfNeeded()
            }
        }
    }

    func currentWeekEntries() -> [MuscleEntry] {
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())

        return entries.filter { $0.weekOfYear == currentWeek && $0.year == currentYear }
    }

    func createMissingEntriesIfNeeded() {
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())

        for name in muscleGroups {
            if !entries.contains(where: { $0.name == name && $0.weekOfYear == currentWeek && $0.year == currentYear }) {
                let newEntry = MuscleEntry(name: name)
                context.insert(newEntry)
            }
        }
    }

    func emoji(for muscle: String) -> String {
        switch muscle {
        case "Pecho": return "🫁"
        case "Espalda": return "🦾"
        case "Piernas": return "🦵"
        case "Hombros": return "🧍‍♂️"
        case "Bíceps": return "💪"
        case "Tríceps": return "🔩"
        case "Abdomen": return "🧘"
        default: return "🏋️"
        }
    }
}
