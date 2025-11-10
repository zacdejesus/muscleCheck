//
//  TrainingReviewGenerator.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 12/10/2025.
//

import Observation
import FoundationModels
import Foundation

@Observable
@MainActor
final class MuscleCheckAI {
  
  private var options: GenerationOptions = {
      var opts = GenerationOptions()
      opts.sampling = .greedy
      opts.temperature = 0
      opts.maximumResponseTokens = 100
      return opts
  }()
  
  let session: LanguageModelSession
  
  init() {
    session = LanguageModelSession(instructions: LocalizedStrings.intructions)
  }
  
  func generateReview(daysReviwed: Int = 30, entries: [MuscleEntry]) async throws -> String {
    let today = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    let prompt = LocalizedStrings.reviewPrompt(
        today: formatter.string(from: today),
        history: createHistoryString(from: entries),
        muscles: String(describing: getEntriesString(entries: entries))
    )
    
    do {
      let response = try await session.respond(to: prompt,
                                               options: options).content.replacingOccurrences(of: "**", with: " ")
      
      return response
    } catch let err {
      throw err
    }
  }
  
  func prewarmModel() {
    let promtPrefix = LocalizedStrings.promtPrefix
    
    session.prewarm(promptPrefix: promtPrefix)
  }
  
  func createHistoryString(from entries: [MuscleEntry]) -> String {
    let today = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    let historyLines = entries.compactMap { entry -> String? in
      guard let lastDate = entry.activityDates.max() else { return nil }
      
      let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
      
      return "Músculo: \(entry.name). Última sesión: \(formatter.string(from: lastDate)). Días de descanso: \(daysSince)."
    }
    
    return historyLines.joined(separator: "\n")
  }
  
  func getEntriesString(entries: [MuscleEntry]) -> String? {
    let historyLines = entries.compactMap { entry -> String? in
      guard !entry.isDeleted else { return nil }
      return "\(entry.name)"
    }
    return historyLines.joined(separator: ", ")
  }
  
  func isAppleIntelligenceAvailable() -> Bool {
    let model = SystemLanguageModel.default
    
    switch model.availability {
    case .available: return true
    case .unavailable(.deviceNotEligible): return false
    case .unavailable(.appleIntelligenceNotEnabled): return false
    case .unavailable(.modelNotReady): return true
    case .unavailable(let other): return false
    }
  }
}
