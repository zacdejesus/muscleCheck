//
//  LocalizedInstructions.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 24/10/2025.
//


import FoundationModels
import Foundation

struct LocalizedStrings {
  static var intructions: Instructions {
    let lang = Locale.current.language.languageCode?.identifier
    switch lang {
    case "es":
      return Instructions {
        "Eres un entrenador personal con conocimiento en principios de balance muscular y recuperación"
        "Tu objetivo es analizar el historial de entrenamiento para sugerir *solo un* grupo muscular principal para el entrenamiento de hoy si el usuario ya entreno un musculo hoy no recomendar ese musculo."
        "Genera *solo* el nombre del grupo muscular, con una breve explicación de por qué."
      }
      
    case .none:
      return Instructions {
        "You are a personal trainer with knowledge in muscle balance and recovery principles."
        "Your goal is to analyze the training history and suggest *only one* main muscle group for today's workout. If the user already trained a muscle today, do not recommend that muscle."
        "Generate *only* the name of the muscle group, with a brief explanation of why."
      }
    case .some(_):
      return Instructions {
        "You are a personal trainer with knowledge in muscle balance and recovery principles."
        "Your goal is to analyze the training history and suggest *only one* main muscle group for today's workout. If the user already trained a muscle today, do not recommend that muscle."
        "Generate *only* the name of the muscle group, with a brief explanation of why."
      }
    }
  }
  
  static var promtPrefix: Prompt {
    let lang = Locale.current.language.languageCode?.identifier
    switch lang {
    case "es":
      return Prompt("""
    Analisa los ultimos entrenamientos del usuario (hoy es 2025-10-15):
    --- HISTORIAL DE EJERCICIOS ---
    Músculo: Espalda. Última sesión: 2025-10-15. Días de descanso: 0.
    Músculo: Hombros. Última sesión: 2025-10-15. Días de descanso: 0.
    --- FIN DEL HISTORIAL ---
    Basado en los ultimos musculos entrenados por el usuario Optional("Espalda, Hombros, Biceps, Piernas"), Cual musculo recomendarle para que haga hoy?
    """)
      
    case .none:
      return Prompt("""
    Analyze the user's recent workouts (today is 2025-10-15):
    --- EXERCISE HISTORY ---
    Muscle: Back. Last session: 2025-10-15. Rest days: 0.
    Muscle: Shoulders. Last session: 2025-10-15. Rest days: 0.
    --- END OF HISTORY ---
    Based on the muscles recently trained by the user Optional("Back, Shoulders, Biceps, Legs"), which muscle would you recommend for today's workout?
    """)
    case .some(_):
      return Prompt("""
    Analyze the user's recent workouts (today is 2025-10-15):
    --- EXERCISE HISTORY ---
    Muscle: Back. Last session: 2025-10-15. Rest days: 0.
    Muscle: Shoulders. Last session: 2025-10-15. Rest days: 0.
    --- END OF HISTORY ---
    Based on the muscles recently trained by the user Optional("Back, Shoulders, Biceps, Legs"), which muscle would you recommend for today's workout?
    """)
    }
  }
  
  static func reviewPrompt(today: String, history: String, muscles: String) -> String {
    let lang = Locale.current.language.languageCode?.identifier
    switch lang {
    case "es":
      return """
              Analisa los ultimos entrenamientos del usuario (hoy es \(today)):
              
              --- HISTORIAL DE EJERCICIOS ---
              \(history)
              --- FIN DEL HISTORIAL ---
              
              Basado en los ultimos musculos entrenados recientemente por el usuario \(muscles), Cual musculo recomendarle para que haga hoy?
              """
    case .none:
      return """
              Analyze the user's recent workouts (today is \(today)):
              
              --- EXERCISE HISTORY ---
              \(history)
              --- END OF HISTORY ---
              
              Based on the muscles recently trained by the user \(muscles), which muscle would you recommend for today's workout?
              """
    case .some(_):
      return """
              Analyze the user's recent workouts (today is \(today)):
              
              --- EXERCISE HISTORY ---
              \(history)
              --- END OF HISTORY ---
              
              Based on the muscles recently trained by the user \(muscles), which muscle would you recommend for today's workout?
              """
    }
  }
}
