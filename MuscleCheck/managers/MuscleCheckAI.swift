//
//  TrainingReviewGenerator.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 12/10/2025.
//

import Observation
import FoundationModels
import Foundation

/// Structured output for the AI day suggestion (Feature 12). Maps muscle groups
/// by index into the numbered list we pass in the prompt — robust, no name matching.
@available(iOS 26, *)
@Generable
struct WorkoutSuggestion {
    @Guide(description: "Etiqueta corta del día, ej. 'Push', 'Pull', 'Piernas'")
    var focus: String
    @Guide(description: "Exactamente 2 grupos musculares coherentes entre sí para hoy")
    var blocks: [WorkoutBlock]
    @Guide(description: "Una frase corta explicando por qué se sugiere este día")
    var rationale: String
}

@available(iOS 26, *)
@Generable
struct WorkoutBlock {
    @Guide(description: "Índice del grupo muscular elegido, de la lista numerada provista")
    var groupIndex: Int
    @Guide(description: "Tres ejercicios comunes de ejemplo para ese grupo")
    var exercises: [String]
}

@available(iOS 26, *)
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
    session = LanguageModelSession(instructions: LocalizedStrings.coachInstructions)
  }

  /// Suggests one coherent training day (exactly 2 gym muscle groups + example
  /// exercises). Resolves the model's group indices to the user's actual entries
  /// here, returning a version-agnostic `RoutineSuggestion` the rest of the app holds.
  func suggestWorkout(entries: [MuscleEntry]) async throws -> RoutineSuggestion {
    let gymGroups = entries.filter {
      $0.category == ActivityCategory.gym.rawValue && !$0.isDeleted
    }

    let numbered = gymGroups.enumerated()
      .map { "\($0.offset)=\($0.element.name)" }
      .joined(separator: ", ")

    let prompt = LocalizedStrings.coachPrompt(
      groups: numbered,
      history: createHistoryString(from: gymGroups)
    )

    // Some randomness so "Dame otra" yields a different split each time.
    var opts = GenerationOptions()
    opts.sampling = .random(probabilityThreshold: 0.9)
    opts.temperature = 0.8
    opts.maximumResponseTokens = 512

    let suggestion = try await session.respond(
      to: prompt,
      generating: WorkoutSuggestion.self,
      options: opts
    ).content

    // Map indices -> entry names, dropping anything out of range, capped at 2 groups.
    let blocks = suggestion.blocks.compactMap { block -> RoutineSuggestion.Block? in
      guard gymGroups.indices.contains(block.groupIndex) else { return nil }
      return RoutineSuggestion.Block(
        groupName: gymGroups[block.groupIndex].name,
        exercises: Array(block.exercises.prefix(3))
      )
    }

    return RoutineSuggestion(
      focus: suggestion.focus,
      blocks: Array(blocks.prefix(2)),
      rationale: suggestion.rationale
    )
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
      guard let lastDate = entry.sessions.map(\.date).max() else { return nil }
      
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
    case .unavailable(_): return false
    }
  }
}
