//
//  File.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 22/10/2025.
//

import WidgetKit
import SwiftUI

struct WidgetMuscleListEntry: TimelineEntry, Hashable {
    let date: Date
    let entries: [SharedMuscleEntry]
}
