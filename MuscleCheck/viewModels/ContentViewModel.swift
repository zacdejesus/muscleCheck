//
//  ContentViewModel.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 18/05/2025.
//

import Foundation
import SwiftData

@MainActor
class ContentViewModel: ObservableObject {
    
    private var context: ModelContext?
    private var entries: [MuscleEntry] = []
    let defaultGroups = ["Pecho", "Espalda", "Piernas", "Hombros", "Bíceps", "Tríceps", "Abdomen"]
    
    @Published var currentWeekEntries: [MuscleEntry] = []
    
    func setup(context: ModelContext, entries: [MuscleEntry]) {
        self.context = context
        self.entries = entries
        createMissingEntriesIfNeeded()
        updateCurrentEntries()
    }
    
    func updateCurrentEntries() {
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
        
        currentWeekEntries = entries.filter { $0.weekOfYear == currentWeek && $0.year == currentYear }
    }
    
    func toggleCheck(for entry: MuscleEntry) {
        entry.isChecked.toggle()
        updateCurrentEntries()
    }
    
    func createMissingEntriesIfNeeded() {
        let customGroups = entries
            .filter { $0.isCustom }
            .map { $0.name }
        
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
        
        let allGroups = defaultGroups + customGroups
        
        for name in allGroups {
            let exists = entries.contains {
                $0.name == name && $0.weekOfYear == currentWeek && $0.year == currentYear
            }
            
            if !exists {
                let newEntry = MuscleEntry(name: name, isCustom: !defaultGroups.contains(name))
                context?.insert(newEntry)
            }
        }
        
        // Refresh
        try? context?.save()
        entries = (try? context?.fetch(FetchDescriptor<MuscleEntry>())) ?? []
        updateCurrentEntries()
    }
    
    func emoji(for muscle: String) -> String {
        switch muscle {
        case "Pecho": return "🏋️"
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
