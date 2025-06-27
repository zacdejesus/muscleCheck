//
//  array+extension.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 14/06/2025.
//


extension Array {
  mutating func appendIfNotNil(_ element: Element?) {
    if let element = element {
      self.append(element)
    }
  }
  
  subscript(safe index: Int) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
