//
//  LocalizedInstructions.swift
//  MuscleCheck
//
//  Created by Alejandro De Jesus on 24/10/2025.
//


import FoundationModels
import Foundation

struct LocalizedStrings {
  @available(iOS 26, *)
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
  
  /// Coach persona + rules for the day-suggestion feature (Feature 12).
  @available(iOS 26, *)
  static var coachInstructions: Instructions {
    let lang = Locale.current.language.languageCode?.identifier
    switch lang {
    case "es":
      return Instructions {
        "Sos un entrenador personal experto en armar días de gimnasio."
        "Tu tarea: recomendar UN día de entrenamiento para hoy."
        "Elegí EXACTAMENTE 2 grupos musculares coherentes entre sí, estilo push/pull/piernas (ej: pecho+tríceps, espalda+bíceps, piernas+abdomen)."
        "Elegí los grupos SOLO de la lista numerada provista, devolviendo sus índices (groupIndex)."
        "No recomiendes grupos ya entrenados hoy. Rotá respecto a lo entrenado recientemente; ante igualdad, priorizá lo más descansado."
        "Para cada grupo sugerí 3 ejercicios comunes. Respondé en español."
      }
    case "fr":
      return Instructions {
        "Tu es un coach personnel expert pour composer des journées de gym."
        "Ta tâche : recommander UNE journée d'entraînement pour aujourd'hui."
        "Choisis EXACTEMENT 2 groupes musculaires cohérents entre eux, style push/pull/jambes (ex : pectoraux+triceps, dos+biceps, jambes+abdos)."
        "Choisis les groupes UNIQUEMENT dans la liste numérotée fournie, en renvoyant leurs index (groupIndex)."
        "Ne recommande pas de groupes déjà entraînés aujourd'hui. Alterne par rapport au récent ; à égalité, priorise le plus reposé."
        "Pour chaque groupe, suggère 3 exercices courants. Réponds en français."
      }
    default:
      return Instructions {
        "You are a personal trainer expert at building gym training days."
        "Your task: recommend ONE training day for today."
        "Pick EXACTLY 2 muscle groups that are coherent together, push/pull/legs style (e.g. chest+triceps, back+biceps, legs+abs)."
        "Pick groups ONLY from the numbered list provided, returning their indices (groupIndex)."
        "Do not recommend groups already trained today. Rotate relative to what was trained recently; break ties toward the most rested."
        "For each group suggest 3 common exercises. Respond in English."
      }
    }
  }

  /// Per-call prompt: the user's numbered gym groups + recent history.
  static func coachPrompt(groups: String, history: String) -> String {
    let lang = Locale.current.language.languageCode?.identifier
    switch lang {
    case "es":
      return """
      Grupos disponibles (elegí por índice): \(groups)

      Historial reciente:
      \(history)

      ¿Qué día de entrenamiento (exactamente 2 grupos coherentes + 3 ejercicios cada uno) me recomendás para hoy?
      """
    case "fr":
      return """
      Groupes disponibles (choisis par index) : \(groups)

      Historique récent :
      \(history)

      Quelle journée d'entraînement (exactement 2 groupes cohérents + 3 exercices chacun) me recommandes-tu pour aujourd'hui ?
      """
    default:
      return """
      Available groups (pick by index): \(groups)

      Recent history:
      \(history)

      What training day (exactly 2 coherent groups + 3 exercises each) do you recommend for today?
      """
    }
  }

  @available(iOS 26, *)
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
