//
//  MuscleCheckTests.swift
//  MuscleCheckTests
//
//  Created by Alejandro De Jesus on 17/05/2025.
//
import Testing
@testable import MuscleCheck
import Foundation

struct ContentViewModelTests {
    
    @Test("createMissingEntriesIfNeeded adds missing entries")
    func coddso()
    {
        let now = Date()
        let calendar = Calendar.current
        let currentWeek = calendar.component(.weekOfYear, from: now)
        let currentYear = calendar.component(.yearForWeekOfYear, from: now)
        
        let existing = [
            MuscleEntry(name: "Pecho"),
            MuscleEntry(name: "Espalda")
        ]
        
        existing.forEach {
            $0.weekOfYear = currentWeek
            $0.year = currentYear
        }
        
        var insertedEntries: [MuscleEntry] = []
        


    }
}
