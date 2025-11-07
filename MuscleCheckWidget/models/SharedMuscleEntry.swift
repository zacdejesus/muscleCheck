//
//  SharedMuscleEntry.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 22/10/2025.
//

import WidgetKit
import SwiftUI

struct SharedMuscleEntry: Codable, Hashable {
    let name: String
    let isChecked: Bool
  
  public init(name: String, isChecked: Bool) {
       self.name = name
       self.isChecked = isChecked
   }
}
