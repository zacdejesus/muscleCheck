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
        let customGroups = entries.map { $0.name }
        
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.yearForWeekOfYear, from: Date())
        
        let allGroups = customGroups
        
        for name in allGroups {
            let exists = entries.contains {
                $0.name == name && $0.weekOfYear == currentWeek && $0.year == currentYear
            }
            
            if !exists {
                let newEntry = MuscleEntry(name: name)
                context?.insert(newEntry)
            }
        }
        
        try? context?.save()
        entries = (try? context?.fetch(FetchDescriptor<MuscleEntry>())) ?? []
        updateCurrentEntries()
    }
    
    func emoji(for muscle: String) -> String {
        switch muscle {
        case NSLocalizedString("group_chest", comment: ""): return "🏋️"
        case NSLocalizedString("group_back", comment: ""): return "🦾"
        case NSLocalizedString("group_legs", comment: ""): return "🦵"
        case NSLocalizedString("group_shoulders", comment: ""): return "🧍‍♂️"
        case NSLocalizedString("group_biceps", comment: ""): return "💪"
        case NSLocalizedString("group_triceps", comment: ""): return "🔩"
        case NSLocalizedString("group_abdomen", comment: ""): return "🧘"
        default: return "🏋️"
        }
    }
}
