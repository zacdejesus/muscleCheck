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
      opts.temperature = 10
      opts.maximumResponseTokens = 150
      return opts
  }()
  
  let session: LanguageModelSession
  
  init() {
    let systemInstructions = Instructions {
      "Eres un entrenador personal con conocimiento en principios de balance muscular y recuperación"
      "Tu objetivo es analizar el historial de entrenamiento para sugerir *solo un* grupo muscular principal para el entrenamiento de hoy si el usuario ya entreno un musculo hoy no recomendar ese musculo."
      "Genera *solo* el nombre del grupo muscular, con una breve explicación de por qué."
    }
    session = LanguageModelSession(instructions: systemInstructions)
  }
  
  func generateReview(daysReviwed: Int = 30, entries: [MuscleEntry]) async -> String {
    let today = Date()
    let formatter = DateFormatter()
    
    let finalPrompt = """
    Analisa los ultimos entrenamientos del usuario (hoy es \(formatter.string(from: today))):
    
    --- HISTORIAL DE EJERCICIOS ---
    \(createHistoryString(from: entries))
    --- FIN DEL HISTORIAL ---
    
    Based on muscular balance and the user training muscles \(String(describing: getEntriesString(entries: entries))), Cual musculo recomendarle para que haga hoy?
    """
    dump(finalPrompt)
    let response = try! await session.respond(to: finalPrompt,
                                              options: options)
    dump(response)
    return response.content
  }
  
  func prewarmModel() {
    let promtPrefix = Prompt("""
    Analisa los ultimos entrenamientos del usuario (hoy es "07/10/2025"))):
    
    --- HISTORIAL DE EJERCICIOS ---
    
    --- FIN DEL HISTORIAL ---
    
    Based on muscular balance and the user training muscles , Cual musculo recomendarle para que haga hoy?
    """)
    
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
}
